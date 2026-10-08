#!/usr/bin/env python3
"""Bounded Android OS restart acceptance: one APK, no clear/reinstall on restore.

Run after the ordinary integration tests on the same emulator. Only stdlib and
Flutter/adb are required. No missing marker, process exit, or timeout is success.
"""

from __future__ import annotations

import argparse
import collections
import contextlib
import queue
import re
import subprocess
import sys
import threading
import time
import uuid
from pathlib import Path

PACKAGE = "app.gramtree.gram_tree"
ACTIVITY = f"{PACKAGE}/.MainActivity"
APP = Path(__file__).resolve().parents[1] / "app"
MARKER = re.compile(r"GRAMTREE_PROCESS_DEATH ([a-f0-9]+) ([A-Z_]+) pid=(\d+)")
LOG_PID = re.compile(r"^\d\d-\d\d\s+[\d:.]+\s+(\d+)\s+\d+\s+")
FAILURE = re.compile(
    r"FATAL EXCEPTION|Fatal signal|Unhandled Exception|"
    r"EXCEPTION CAUGHT BY FLUTTER|Test failed|TimeoutException|"
    r"Lost connection to device|Process .* has died|ANR in " + re.escape(PACKAGE),
    re.IGNORECASE,
)


def command(args: list[str], *, timeout: float = 30) -> str:
    result = subprocess.run(
        args,
        cwd=APP,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=timeout,
        check=False,
    )
    if result.returncode:
        raise RuntimeError(
            f"Command failed ({result.returncode}): {args[0]}\n{result.stdout}"
        )
    return result.stdout.strip()


class Android:
    def __init__(self, adb: str, serial: str) -> None:
        self.prefix = [adb, "-s", serial]

    def run(self, *args: str, timeout: float = 30) -> str:
        return command([*self.prefix, *args], timeout=timeout)

    def pid(self) -> str:
        # Android pidof exits 1 for an absent process; this is an expected query
        # result, not permission to swallow other adb/transport failures.
        result = subprocess.run(
            [*self.prefix, "shell", "pidof", PACKAGE],
            cwd=APP,
            text=True,
            capture_output=True,
            timeout=10,
            check=False,
        )
        if result.returncode not in (0, 1) or result.stderr.strip():
            raise RuntimeError(f"Cannot query app PID: {result.stderr.strip()}")
        value = result.stdout.strip()
        if value and not re.fullmatch(r"\d+", value):
            raise RuntimeError(f"Expected exactly one app process, got {value!r}")
        return value

    def launch(self) -> str:
        output = self.run("shell", "am", "start", "-W", "-n", ACTIVITY)
        if "Error:" in output or "Status: ok" not in output:
            raise RuntimeError(f"Activity did not launch cleanly:\n{output}")
        process = self.pid()
        if not process:
            raise RuntimeError("Activity launch returned without a live app PID")
        return process

    def stop_and_check(self, expected_pid: str) -> None:
        if not expected_pid or self.pid() != expected_pid:
            raise RuntimeError("Seed process disappeared/changed before force-stop")
        self.run("shell", "am", "force-stop", PACKAGE)
        if self.pid():
            raise RuntimeError("App process is still present after force-stop")
        print(f"OS force-stop verified: PID {expected_pid} is absent", flush=True)


class LogWatch:
    def __init__(self, android: Android, run_id: str) -> None:
        self.android = android
        self.run_id = run_id
        self.lines: queue.Queue[str | None] = queue.Queue()
        self.recent: collections.deque[str] = collections.deque(maxlen=200)
        self.process = subprocess.Popen(
            [
                *android.prefix,
                "logcat",
                "-v",
                "threadtime",
                "flutter:I",
                "AndroidRuntime:E",
                "ActivityManager:I",
                "DEBUG:F",
                "libc:F",
                "*:S",
            ],
            cwd=APP,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            bufsize=1,
        )
        self.reader = threading.Thread(target=self._read, daemon=True)
        self.reader.start()

    def _read(self) -> None:
        assert self.process.stdout is not None
        for line in self.process.stdout:
            self.lines.put(line.rstrip())
        self.lines.put(None)

    def wait(self, target: str, process: str, timeout: float) -> None:
        deadline = time.monotonic() + timeout
        next_pid_check = 0.0
        stages = {
            "SEED_READY": ["BOOT", "SEED_READY"],
            "PASSED": ["BOOT", "RESTORE_DURABLE", "RESTORE_OFFLINE", "PASSED"],
        }[target]
        seen: list[str] = []
        while time.monotonic() < deadline:
            if time.monotonic() >= next_pid_check:
                if self.android.pid() != process:
                    raise RuntimeError(
                        f"Unexpected app exit/PID change before {target}"
                    )
                next_pid_check = time.monotonic() + 1
            try:
                line = self.lines.get(timeout=0.25)
            except queue.Empty:
                continue
            if line is None:
                raise RuntimeError(f"logcat exited before {target}")
            self.recent.append(line)
            marker = MARKER.search(line)
            if marker and marker[1] == self.run_id:
                state, marker_pid = marker[2], marker[3]
                if marker_pid != process:
                    raise RuntimeError(f"Marker came from unexpected PID: {marker_pid}")
                print(marker.group(0), flush=True)
                if state == "FAILED":
                    raise RuntimeError("Standalone Flutter binding reported failure")
                if len(seen) >= len(stages) or state != stages[len(seen)]:
                    raise RuntimeError(f"Unexpected marker order: {seen} then {state}")
                seen.append(state)
                if state == target:
                    return
            log_pid = LOG_PID.match(line)
            is_ours = (log_pid is not None and log_pid[1] == process) or PACKAGE in line
            if is_ours and FAILURE.search(line):
                raise RuntimeError(
                    f"Unexpected crash/test failure before {target}, PID {process}"
                )
        raise TimeoutError(f"Missing {target} after {timeout:g}s; observed {seen}")

    def capture_failure_details(
        self, *, timeout: float = 2, max_lines: int = 200
    ) -> None:
        # FAILED is terminal, not permission to lose the following framework
        # exception/stack. Drain briefly before closing logcat or stopping the app;
        # never interpret a later success marker as recovery from this failure.
        deadline = time.monotonic() + timeout
        for _ in range(max_lines):
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                break
            try:
                line = self.lines.get(timeout=min(0.25, remaining))
            except queue.Empty:
                continue
            if line is None:
                break
            self.recent.append(line)

    def safe_failure_log(self) -> str:
        # Flutter's automatic assertion report can dump whole envelopes even
        # though our Dart diagnostics do not. Never relay those raw values.
        safe: list[str] = []
        detail_prefix = f"GRAMTREE_PROCESS_DETAIL {self.run_id} "
        frame = re.compile(
            r"#\d+\s+[A-Za-z0-9_.$<> ]+\s+"
            r"\((?:package:|file:)[^()\s]+:\d+(?::\d+)?\)$"
        )
        for line in self.recent:
            marker = MARKER.search(line)
            if marker and marker[1] == self.run_id:
                safe.append(marker.group(0))
            elif detail_prefix in line:
                safe.append(line[line.index(detail_prefix) :])
            elif match := frame.search(line):
                safe.append(match.group(0))
            elif FAILURE.search(line):
                safe.append("Native/framework failure detected (raw message omitted)")
        return "\n".join(safe)

    def close(self) -> None:
        self.process.terminate()
        try:
            self.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait(timeout=5)
        self.reader.join(timeout=5)
        if self.process.stdout is not None:
            self.process.stdout.close()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--serial", default="emulator-5554")
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--flutter", default="flutter")
    parser.add_argument("--phase-timeout", type=float, default=180)
    parser.add_argument("--build-timeout", type=float, default=600)
    args = parser.parse_args()
    if not 0 < args.phase_timeout <= 240 or not 0 < args.build_timeout <= 900:
        parser.error("phase timeout must be 1..240s; build timeout must be 1..900s")
    run_id = uuid.uuid4().hex
    android = Android(args.adb, args.serial)
    watch: LogWatch | None = None
    try:
        if android.run("get-state") != "device":
            raise RuntimeError("Android target is not available")
        print(f"Building standalone restart harness, run={run_id}", flush=True)
        # Never use flutter test/drive here: an external runner would finish the
        # activity or reinstall it. Native result reporting also assumes an
        # instrumentation listener; we consume allTestsPassed + tagged logcat.
        output = command(
            [
                args.flutter,
                "build",
                "apk",
                "--debug",
                "--target=integration_test/process_death_harness.dart",
                "--dart-define=APP_ENV=dev",
                "--dart-define=API_BASE_URL=http://10.0.2.2:8000",
                "--dart-define=INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false",
                f"--dart-define=PROCESS_DEATH_RUN_ID={run_id}",
            ],
            timeout=args.build_timeout,
        )
        print(output, flush=True)
        apk = APP / "build/app/outputs/flutter-apk/app-debug.apk"
        if not apk.is_file():
            raise RuntimeError("Build returned without the standalone APK")
        android.run("shell", "am", "force-stop", PACKAGE)
        # Exactly one install, before seed; -r retains the emulator's prior
        # ordinary test app. The harness isolates its own fresh owner/run ID.
        android.run("install", "-r", "-t", str(apk), timeout=90)
        android.run("logcat", "-c")
        watch = LogWatch(android, run_id)
        seed_pid = android.launch()
        watch.wait("SEED_READY", seed_pid, args.phase_timeout)
        android.stop_and_check(seed_pid)
        # Same APK, same package data, same Android keystore and Drift files.
        # Discard the seed log stream and begin a fresh, bounded restore watch.
        watch.close()
        watch = None
        android.run("logcat", "-c")
        watch = LogWatch(android, run_id)
        restore_pid = android.launch()
        if restore_pid == seed_pid:
            raise RuntimeError("Restore reused the seed PID instead of restarting")
        print(f"OS relaunch verified: {seed_pid} -> {restore_pid}", flush=True)
        watch.wait("PASSED", restore_pid, args.phase_timeout)
        print(
            "Android process-death acceptance PASSED (binding test future passed)",
            flush=True,
        )
        return 0
    except (RuntimeError, TimeoutError, OSError, subprocess.SubprocessError) as error:
        print(
            f"Android process-death acceptance FAILED: {error}",
            file=sys.stderr,
            flush=True,
        )
        if watch is not None:
            watch.capture_failure_details()
            print("Recent safe harness diagnostics:", file=sys.stderr)
            print(watch.safe_failure_log(), file=sys.stderr)
        return 1
    finally:
        if watch is not None:
            watch.close()
        # Only stop this app; never clear data/uninstall, including on failure.
        with contextlib.suppress(OSError, subprocess.SubprocessError, RuntimeError):
            android.run("shell", "am", "force-stop", PACKAGE)


if __name__ == "__main__":
    sys.exit(main())
