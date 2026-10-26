#!/usr/bin/env python3
"""Failure-only native CI summary. Never relay raw reports, messages or logcat."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import threading
import xml.etree.ElementTree as ET
from pathlib import Path

PACKAGE = "app.gramtree.gram_tree"
TEST_CLASS = f"{PACKAGE}.ExportFileShareTest"
TESTS = frozenset(
    {
        "testSaveZipAndRepeatedFilenameThroughSystemDocumentsUI",
        "testCompletionBroadcastMatchesActionOnlyReceiver",
        "testClickWaitsForActionableRowInsteadOfSameNamedTitle",
        "testCancellationInvalidatesPreparationBeforePresentation",
        "testInvalidArgumentsNeverOpenSharing",
    }
)
EXCEPTIONS = frozenset(
    {
        "java.lang.IllegalStateException",
        "java.lang.IllegalArgumentException",
        "java.lang.RuntimeException",
        "java.lang.NullPointerException",
        "java.lang.SecurityException",
        "java.lang.AssertionError",
        "junit.framework.AssertionFailedError",
        "java.util.concurrent.TimeoutException",
        "android.os.RemoteException",
        "android.os.DeadObjectException",
    }
)
# Text reports are untrusted, including lines that look like stack frames. Emit
# only these fixed symbols, never arbitrary valid-looking class/method tokens.
SYMBOLS = frozenset(
    {
        "android.app.UiAutomation.connectWithTimeout",
        "android.app.UiAutomation.connect",
        "android.app.UiAutomation.disconnect",
        "android.app.UiAutomation.destroy",
        "android.app.UiAutomation.getRootInActiveWindow",
        "android.app.Instrumentation.getUiAutomation",
        "android.app.Instrumentation.finish",
        "android.app.Instrumentation.waitForIdleSync",
        "android.app.Instrumentation$InstrumentationThread.run",
        "android.app.UiAutomationConnection.connect",
        "android.app.UiAutomationConnection.registerUiTestAutomationServiceLocked",
        "android.app.IUiAutomationConnection$Stub$Proxy.connect",
        "android.os.Parcel.createException",
        "android.os.Parcel.createExceptionOrNull",
        "android.os.Parcel.readException",
        "android.os.Parcel.readExceptionCode",
        "android.test.InstrumentationTestRunner.onStart",
        "android.view.accessibility.IAccessibilityManager$Stub$Proxy.registerUiTestAutomationService",
        "com.android.server.accessibility.UiAutomationManager.registerUiTestAutomationServiceLocked",
        *(f"{TEST_CLASS}.{name}" for name in TESTS),
        *(
            f"{TEST_CLASS}.{name}"
            for name in (
                "setUp",
                "tearDown",
                "waitForNode",
                "findNode",
                "clickWhenReady",
                "clickableTarget",
                "shareAndSave",
            )
        ),
    }
)
MAX_FILES = 8
MAX_XML_BYTES = 131072
MAX_TOTAL_XML_BYTES = 524288
MAX_CRASH_BYTES = 65536
MAX_FRAMES = 12


def summary(text: str, limit: int) -> dict:
    text = text[:16384]
    category = "unclassified"
    if "UiAutomationService " in text and "already registered!" in text:
        category = "service_registration_conflict"
    elif "Cannot call disconnect() while connecting UiAutomation@" in text:
        category = "disconnect_during_connect"
    elif "Process crashed" in text:
        category = "process_crashed"
    exception = "unknown"
    frames = []
    for line in text.splitlines():
        candidate = line.strip().removeprefix("Caused by: ").split(":", 1)[0]
        if exception == "unknown" and candidate in EXCEPTIONS:
            exception = candidate
        match = re.fullmatch(
            r"\s*at ([A-Za-z0-9_.$<>]{1,200})\([^()\r\n]{0,160}:(\d{1,6})\)\s*", line
        )
        if match and match[1] in SYMBOLS and len(frames) < limit:
            frames.append(f"{match[1]}:{int(match[2])}")
    return {"category": category, "exception": exception, "frames": frames}


def reports(root: Path) -> tuple[str, list[dict], int]:
    directory = root / "app/build/app/outputs/androidTest-results/connected/debug"
    if not directory.exists():
        return "absent", [], MAX_FRAMES
    pending = [(directory, 0)]
    files = []
    status = "ok"
    entries = 0
    while pending and entries < 32:
        current, depth = pending.pop(0)
        with os.scandir(current) as listing:
            for entry in listing:
                entries += 1
                if entries > 32:
                    status = "limited"
                    break
                if entry.is_dir(follow_symlinks=False) and depth == 0:
                    pending.append((Path(entry.path), 1))
                elif (
                    entry.is_file(follow_symlinks=False)
                    and entry.name.startswith("TEST-")
                    and entry.name.endswith(".xml")
                ):
                    if len(files) == MAX_FILES:
                        status = "limited"
                        break
                    files.append(Path(entry.path))
    if pending:
        status = "limited"
    if not files and status == "ok":
        status = "absent"
    tests = []
    seen = set()
    remaining = MAX_FRAMES
    total = 0
    for path in files:
        if total >= MAX_TOTAL_XML_BYTES:
            status = "limited"
            break
        with path.open("rb") as source:
            data = source.read(min(MAX_XML_BYTES, MAX_TOTAL_XML_BYTES - total) + 1)
        total += len(data)
        if total > MAX_TOTAL_XML_BYTES:
            status = "limited"
            break
        if len(data) > MAX_XML_BYTES:
            status = "limited"
            continue
        # Native JUnit reports are UTF-8. Reject NUL/UTF-16 and declarations
        # before parsing, so encoded DTDs cannot bypass the expansion guard.
        if b"\x00" in data or b"<!DOCTYPE" in data.upper() or b"<!ENTITY" in data.upper():
            status = "invalid"
            continue
        try:
            document = ET.fromstring(data)
        except (ET.ParseError, LookupError):
            status = "invalid"
            continue
        for case in document.iter("testcase"):
            name = case.get("name")
            if case.get("classname") != TEST_CLASS or name not in TESTS or name in seen:
                continue
            for failure in case:
                if failure.tag not in ("failure", "error"):
                    continue
                event = summary(failure.text or "", remaining)
                if event["category"] == "unclassified":
                    event["category"] = summary(failure.get("message", ""), 0)["category"]
                # Only a finite known exception type is accepted from attributes.
                if event["exception"] == "unknown" and failure.get("type") in EXCEPTIONS:
                    event["exception"] = failure.get("type")
                remaining -= len(event["frames"])
                tests.append({"test": name, "result": failure.tag, **event})
                seen.add(name)
                break
    return status, tests, remaining


def crash_buffer(adb: list[str], serial: str, remaining: int) -> dict:
    result = {"status": "unavailable", "binding": "unverified_recent"}
    # There is no current-run PID/time receipt here. Even a matching package's
    # most recent record may be old; it must never be labelled this run's cause.
    command = [*adb, "-s", serial, "logcat", "-d", "-b", "crash", "-t", "120", "-v", "brief"]
    with subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL) as child:
        captured = []

        def read_bounded():
            try:
                captured.append(child.stdout.read(MAX_CRASH_BYTES + 1))
                if len(captured[0]) > MAX_CRASH_BYTES:
                    child.kill()
            except OSError:
                pass

        reader = threading.Thread(target=read_bounded, daemon=True)
        reader.start()
        try:
            child.wait(timeout=5)
        except subprocess.TimeoutExpired:
            child.kill()  # Only this Popen's local, read-only adb child.
            child.wait()
            reader.join(timeout=1)
            return result
        reader.join(timeout=1)
        if captured and len(captured[0]) > MAX_CRASH_BYTES:
            return {**result, "status": "limited"}
        if reader.is_alive() or child.returncode or not captured:
            return result
    blocks = []
    current_key = None
    current = []
    native_header = re.compile(
        r"pid: \d{1,9}, tid: \d{1,9}, name: .{0,200} >>> ([A-Za-z0-9_.:]{1,160}) <<<"
    )
    for line in captured[0].decode("utf-8", errors="replace").splitlines()[:120]:
        match = re.fullmatch(r"[EF]/(AndroidRuntime|DEBUG)\s*\(\s*(\d{1,9})\): (.{0,2048})", line)
        if not match:
            continue
        tag, pid, payload = match.groups()
        key = (tag, pid)
        starts_block = tag == "AndroidRuntime" and payload.startswith("FATAL EXCEPTION:")
        if tag == "DEBUG":
            starts_block = payload.startswith("*** *** ***") or (
                key != current_key
                and (payload.startswith("Cmdline:") or native_header.fullmatch(payload))
            )
        if starts_block:
            if current:
                blocks.append((current_key, current))
            current_key, current = key, []
        if key == current_key:
            current.append(payload)
    if current:
        blocks.append((current_key, current))
    for (tag, pid), block in reversed(blocks):
        if tag == "AndroidRuntime" and f"Process: {PACKAGE}, PID: {pid}" in block:
            return {**result, "status": "ok", **summary("\n".join(block), remaining)}
        if tag != "DEBUG":
            continue
        identities = []
        for payload in block:
            if payload.startswith("Cmdline: "):
                identities.append(payload.removeprefix("Cmdline: "))
            elif header := native_header.fullmatch(payload):
                identities.append(header[1])
        # Native DEBUG's prefix PID belongs to the dumper, not necessarily the
        # crashed app. Require its own explicit, consistent package headers.
        if not identities or any(identity != PACKAGE for identity in identities):
            continue
        for payload in block:
            signal = re.fullmatch(r"signal (6 \(SIGABRT\)|11 \(SIGSEGV\))(?:,.*)?", payload)
            if signal:
                return {
                    **result,
                    "status": "ok",
                    "category": (
                        "native_sigabrt" if signal[1] == "6 (SIGABRT)" else "native_sigsegv"
                    ),
                    "exception": "unknown",
                    "frames": [],
                }
    return {**result, "status": "absent"}


class SafeParser(argparse.ArgumentParser):
    def error(self, message):
        self.exit(2, "native_diagnostics invalid_arguments\n")


def main() -> int:
    parser = SafeParser(description=__doc__)
    parser.add_argument("--serial", required=True)
    parser.add_argument("--adb", nargs="+", default=["adb"])
    args = parser.parse_args()
    if (
        not re.fullmatch(r"[A-Za-z0-9_.:-]{1,80}", args.serial)
        or len(args.adb) > 8
        or any(len(a) > 1024 for a in args.adb)
    ):
        parser.error("invalid input")
    try:
        status, tests, remaining = reports(Path(__file__).resolve().parent.parent)
    except (OSError, ValueError):
        status, tests, remaining = "unavailable", [], MAX_FRAMES
    try:
        crash = crash_buffer(args.adb, args.serial, remaining)
    except (OSError, ValueError):
        crash = {"status": "unavailable", "binding": "unverified_recent"}
    output = json.dumps(
        {"xml_status": status, "tests": tests, "crash": crash}, separators=(",", ":")
    )
    if len(output) > 6144:
        output = (
            '{"xml_status":"limited","tests":[],"crash":'
            '{"status":"limited","binding":"unverified_recent"}}'
        )
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
