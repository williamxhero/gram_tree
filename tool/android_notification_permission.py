#!/usr/bin/env python3
"""Run an unchanged Android test command alongside a narrowly scoped OS UI driver.

Only Android 14's English notification question for 味谱 is accepted. Unknown
PermissionController identity formats fail closed; no permissions are pre-granted.
"""

from __future__ import annotations

import argparse
import os
import re
import signal
import subprocess
import sys
import threading
import time
import uuid
import xml.etree.ElementTree as ET
from datetime import UTC, datetime

PACKAGE = "app.gramtree.gram_tree"
CONTROLLER = "com.android.permissioncontroller"
ACTIVITIES = {
    f"{CONTROLLER}/.permission.ui.GrantPermissionsActivity",
    f"{CONTROLLER}/com.android.permissioncontroller.permission.ui.GrantPermissionsActivity",
}
ADB_TIMEOUT = 4
VERIFY_TIMEOUT = 10
JOIN_TIMEOUT = 30


class DriverError(RuntimeError):
    """Only fixed, sanitized diagnostics may cross the CLI boundary."""


def permission_activity(output: str) -> str | None:
    """Bind the top-resumed record to its own detailed ActivityRecord dump."""
    tops = re.findall(
        r"^\s*topResumedActivity=(ActivityRecord\{[^\r\n]+\})\s*$", output, re.MULTILINE
    )
    if len(tops) != 1:
        if "GrantPermissionsActivity" in output:
            lines = output.splitlines()
            top_fields = [line for line in lines if re.match(r"^\s*topResumedActivity\s*=", line)]
            permission_lines = [line for line in lines if "GrantPermissionsActivity" in line]
            history_headers = sum(
                bool(re.match(r"^\s*\* Hist {1,2}#\d+: ActivityRecord\{", line))
                for line in permission_lines
            )
            # Counts are clues, not authorization. Unknown structures still fail closed.
            raise DriverError(
                "Cannot identify a unique top-resumed permission activity "
                f"(top_fields={len(top_fields)}, top_matches={len(tops)}, "
                "permission_top_fields="
                f"{sum('GrantPermissionsActivity' in line for line in top_fields)}, "
                f"permission_history_headers={history_headers}, "
                f"permission_history_only_hint={history_headers == len(permission_lines)})"
            )
        return None
    top = tops[0]
    match = re.fullmatch(r"ActivityRecord\{([0-9a-f]+) u0 (\S+) t\d+\}", top)
    if match is None:
        if "GrantPermissionsActivity" in top:
            raise DriverError("Unrecognized top-resumed permission activity format")
        return None
    if match[2] not in ACTIVITIES:
        return None
    # AOSP TaskFragment's "Hist " label plus dumpActivity's " #" makes two spaces.
    # Keep legacy one-space support, but bind the full record and its own caller.
    headers = list(
        re.finditer(
            r"^\s*\* Hist {1,2}#\d+: (ActivityRecord\{[^\r\n]+\})\s*$", output, re.MULTILINE
        )
    )
    blocks = []
    for index, header in enumerate(headers):
        if header[1] == top:
            end = headers[index + 1].start() if index + 1 < len(headers) else len(output)
            blocks.append(output[header.end() : end])
    if len(blocks) != 1:
        raise DriverError(
            "Missing unique detailed permission ActivityRecord "
            f"(history_headers={len(headers)}, matching_records={len(blocks)})"
        )
    callers = re.findall(
        r"^\s*launchedFromUid=\d+ launchedFromPackage=(\S+) launchedFromFeature=\S+ userId=0\s*$",
        blocks[0],
        re.MULTILINE,
    )
    if len(callers) != 1:
        raise DriverError("Missing verified permission requesting package")
    return top if callers[0] == PACKAGE else None


def allow_center(xml: str) -> tuple[int, int] | None:
    try:
        root = ET.fromstring(xml)
    except ET.ParseError:
        raise DriverError("Malformed OS UI XML") from None
    if root.tag != "hierarchy":
        raise DriverError("Unexpected OS UI XML root")
    nodes = list(root.iter("node"))
    messages = [
        node for node in nodes if node.get("resource-id") == f"{CONTROLLER}:id/permission_message"
    ]
    # Full English API 34 question; whitespace can differ across layout/wrapping.
    expected = "Allow 味谱 to send you notifications?"
    questions = [node for node in messages if " ".join(node.get("text", "").split()) == expected]
    if not questions:
        return None  # A different permission question is never ours to answer.
    if len(questions) != 1 or questions[0].get("package") != CONTROLLER:
        raise DriverError("Notification question has ambiguous controller identity")
    buttons = [
        node
        for node in nodes
        if node.get("resource-id") == f"{CONTROLLER}:id/permission_allow_button"
    ]
    if len(buttons) != 1:
        raise DriverError("Missing unique notification Allow button")
    button = buttons[0]
    # AOSP's resource text and all-caps accessibility text; no normalization.
    text_match = button.get("text") in ("Allow", "ALLOW")
    if (
        button.get("package") != CONTROLLER
        or not text_match
        or button.get("class") != "android.widget.Button"
        or button.get("enabled") != "true"
        or button.get("clickable") != "true"
    ):
        # Only comparison results cross the CLI boundary, never OS attribute values.
        raise DriverError(
            "Notification Allow button is not an enabled controller button "
            f"(package_match={button.get('package') == CONTROLLER}, "
            f"text_match={text_match}, "
            f"class_match={button.get('class') == 'android.widget.Button'}, "
            f"enabled_match={button.get('enabled') == 'true'}, "
            f"clickable_match={button.get('clickable') == 'true'})"
        )
    bounds = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", button.get("bounds", ""))
    if bounds is None:
        raise DriverError("Malformed notification Allow bounds")
    left, top, right, bottom = map(int, bounds.groups())
    if right <= left or bottom <= top:
        raise DriverError("Empty notification Allow bounds")
    windows = root.findall("node")
    window = (
        re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", windows[0].get("bounds", ""))
        if len(windows) == 1
        else None
    )
    if window is None or windows[0].get("package") != CONTROLLER:
        raise DriverError("Missing notification controller window bounds")
    x1, y1, x2, y2 = map(int, window.groups())
    if not (x1 <= left < right <= x2 and y1 <= top < bottom <= y2):
        raise DriverError("Notification Allow bounds are outside the controller window")
    return ((left + right) // 2, (top + bottom) // 2)


def notifications_granted(output: str) -> bool:
    # Restrict the runtime grant to this package and Android user 0; the requested
    # permission list and install permissions do not prove a runtime grant.
    packages = list(re.finditer(r"^  Package \[([^\]]+)\] \([^)]+\):\s*$", output, re.MULTILINE))
    for index, package in enumerate(packages):
        if package[1] != PACKAGE:
            continue
        end = packages[index + 1].start() if index + 1 < len(packages) else len(output)
        block = output[package.end() : end]
        users = list(re.finditer(r"^    User (\d+):[^\r\n]*$", block, re.MULTILINE))
        for user_index, user in enumerate(users):
            if user[1] != "0":
                continue
            end = users[user_index + 1].start() if user_index + 1 < len(users) else len(block)
            runtime = re.search(
                r"^      runtime permissions:\s*\n((?:        [^\r\n]*\n?)+)",
                block[user.end() : end],
                re.MULTILINE,
            )
            return bool(
                runtime
                and re.search(
                    r"^        android\.permission\.POST_NOTIFICATIONS: granted=true"
                    r"(?:, flags=\[[^\r\n]*\])?\s*$",
                    runtime[1],
                    re.MULTILINE,
                )
            )
    return False


class Observer:
    def __init__(self, adb: list[str], serial: str) -> None:
        self.prefix = [*adb, "-s", serial]
        self.stop = threading.Event()
        self.ready = threading.Event()
        self.error: str | None = None
        self.phase = "not_started"
        self.thread = threading.Thread(target=self._watch, daemon=True)
        self.dump = f"/data/local/tmp/gramtree-notification-{uuid.uuid4().hex}.xml"

    def run(self, *args: str) -> str:
        try:
            result = subprocess.run(
                [*self.prefix, *args],
                text=True,
                encoding="utf-8",
                capture_output=True,
                timeout=ADB_TIMEOUT,
                check=False,
            )
        except subprocess.TimeoutExpired:
            raise DriverError("adb command timed out") from None
        except (OSError, UnicodeError):
            raise DriverError("Cannot execute/read adb command") from None
        if result.returncode or result.stderr.strip():
            raise DriverError("adb command failed (raw output omitted)")
        return result.stdout

    def activity(self) -> str:
        return self.run("shell", "dumpsys", "activity", "activities")

    def ui(self) -> str:
        try:
            output = self.run("shell", "uiautomator", "dump", "--compressed", self.dump)
            if f"UI hierchary dumped to: {self.dump}" not in output:
                raise DriverError("OS UI dump did not confirm its output file")
            return self.run("exec-out", "cat", self.dump)
        finally:
            # Only this observer's uniquely named remote temporary file.
            self.run("shell", "rm", "-f", self.dump)

    def observe(self) -> None:
        self.phase = "activity_scan"
        token = permission_activity(self.activity())
        if token is None or self.stop.is_set():
            return
        center = allow_center(self.ui())
        if center is None or self.stop.is_set():
            return
        # UI dumping takes time: revalidate the resumed record/caller immediately
        # before using these freshly matched bounds. Never reuse old coordinates.
        self.phase = "activity_revalidation"
        if permission_activity(self.activity()) != token:
            raise DriverError("Permission activity changed before notification tap")
        if self.stop.is_set():
            return
        self.run("shell", "input", "tap", str(center[0]), str(center[1]))
        deadline = time.monotonic() + VERIFY_TIMEOUT
        while time.monotonic() < deadline:
            granted = notifications_granted(self.run("shell", "dumpsys", "package", PACKAGE))
            activity = self.activity()
            xml = self.ui()
            # Paused/history records may outlive the dialog. Revalidate the
            # top-resumed identity and the current UI, not the entire dump text.
            self.phase = "grant_verification"
            closed = permission_activity(activity) is None and not any(
                node.get("resource-id", "").startswith(f"{CONTROLLER}:id/permission_")
                for node in self.parse_ui(xml).iter("node")
            )
            if granted and closed:
                print(
                    "Android notification permission granted and OS dialog closed",
                    flush=True,
                )
                return
            # Shutdown cannot turn an unverified tap into success.
            time.sleep(0.25)
        raise DriverError("Notification grant/dialog closure verification timed out")

    @staticmethod
    def parse_ui(xml: str) -> ET.Element:
        try:
            root = ET.fromstring(xml)
        except ET.ParseError:
            raise DriverError("Malformed OS UI XML during grant verification") from None
        if root.tag != "hierarchy":
            raise DriverError("Unexpected OS UI XML during grant verification")
        return root

    def _watch(self) -> None:
        try:
            while not self.stop.is_set():
                self.observe()
                self.ready.set()
                self.stop.wait(0.25)
        except Exception as error:
            # Thread errors must fail the CLI. Never forward UI/activity dumps,
            # labels from unrelated apps, adb
            # stderr, or arbitrary exception text into CI logs.
            self.error = (
                str(error)
                if isinstance(error, DriverError)
                else "Unexpected notification observer failure"
            )
            if self.error.startswith("Cannot identify a unique top-resumed permission activity"):
                print(
                    "Android notification observer error observed "
                    f"at={datetime.now(UTC).isoformat(timespec='milliseconds')} "
                    f"phase={self.phase}: {self.error}",
                    file=sys.stderr,
                    flush=True,
                )
        finally:
            self.ready.set()

    def start(self) -> None:
        self.thread.start()
        if not self.ready.wait(JOIN_TIMEOUT):
            raise DriverError("Notification observer startup timed out")
        if self.error:
            raise DriverError(self.error)

    def close(self) -> None:
        self.stop.set()
        self.thread.join(timeout=JOIN_TIMEOUT)
        if self.thread.is_alive():
            self.error = "Notification observer did not stop within its bounded join"
        print(
            "Android notification observer stopped"
            if not self.thread.is_alive()
            else "Android notification observer cleanup failed",
            flush=True,
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--serial", default="emulator-5554")
    parser.add_argument(
        "--adb",
        nargs="+",
        default=["adb"],
        help="adb executable (and optional executable prefix arguments)",
    )
    parser.add_argument(
        "command",
        nargs=argparse.REMAINDER,
        help="-- followed by the unmodified test command",
    )
    args = parser.parse_args()
    command = args.command
    if not command or command[0] != "--" or len(command) < 2:
        parser.error("provide -- followed by the test command")
    observer = Observer(args.adb, args.serial)
    child: subprocess.Popen | None = None
    code = 1
    try:
        observer.start()  # A completed first observation precedes child startup.
        child = subprocess.Popen(command[1:])  # Inherit cwd, environment and streams.
        code = child.wait()
    except (DriverError, OSError) as error:
        if not observer.error:
            observer.error = (
                str(error) if isinstance(error, DriverError) else "Cannot start test command"
            )
    except KeyboardInterrupt:
        if child is not None:
            child.terminate()
            try:
                code = child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                child.kill()
                code = child.wait(timeout=5)
        if not code:
            code = 1
    finally:
        observer.close()
    if observer.error:
        print(
            f"Android notification observer FAILED: {observer.error}",
            file=sys.stderr,
            flush=True,
        )
    # Flutter failure always wins, including when the observer also failed.
    return code if code else int(observer.error is not None)


if __name__ == "__main__":
    status = main()
    if status < 0 and os.name == "posix":
        # subprocess reports signals as negative statuses; sys.exit(-N) would
        # instead produce an unrelated normal exit code. Cleanup has completed.
        if -status not in (signal.SIGKILL, signal.SIGSTOP):
            signal.signal(-status, signal.SIG_DFL)
        os.kill(os.getpid(), -status)
    sys.exit(status)
