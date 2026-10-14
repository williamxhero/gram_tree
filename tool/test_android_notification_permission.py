"""Public CLI acceptance using fake adb processes, not driver internals.

These OS text fixtures do NOT establish a passing Android emulator run.
"""

import json
import os
import pathlib
import signal
import subprocess
import sys
import tempfile
import time
import unittest
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parent.parent
PACKAGE = "app.gramtree.gram_tree"
CONTROLLER = "com.android.permissioncontroller"
# AOSP android-14.0.0_r1 producer formats, not real CI observations.
# TaskFragment passes "Hist "; ActivityRecord.dumpActivity adds " #": two spaces.
ACTIVITY = f"{CONTROLLER}/.permission.ui.GrantPermissionsActivity"
RECORD = f"ActivityRecord{{abc123 u0 {ACTIVITY} t8}}"
DIALOG_ACTIVITY = f"""ACTIVITY MANAGER ACTIVITIES (dumpsys activity activities)
  * Task{{000aaa #8 type=standard A={PACKAGE}}}
    topResumedActivity={RECORD}
    * Hist  #1: {RECORD}
      packageName={CONTROLLER} processName={CONTROLLER}
      launchedFromUid=10123 launchedFromPackage={PACKAGE} launchedFromFeature=null userId=0
    * Hist  #0: ActivityRecord{{def456 u0 {PACKAGE}/.MainActivity t8}}
      launchedFromUid=2000 launchedFromPackage=com.android.shell launchedFromFeature=null userId=0
"""
MAIN_ACTIVITY = f"topResumedActivity=ActivityRecord{{def456 u0 {PACKAGE}/.MainActivity t8}}\n"
GRANT = f"""Packages:
  Package [{PACKAGE}] (f00baa):
    requested permissions:
      android.permission.POST_NOTIFICATIONS
    User 0: installed=true hidden=false
      runtime permissions:
        android.permission.POST_NOTIFICATIONS: granted=true, flags=[ USER_SET ]
"""
UI = f"""<hierarchy rotation="0">
<node package="{CONTROLLER}" class="android.widget.FrameLayout" bounds="[0,0][1080,2400]">
  <node package="{CONTROLLER}" resource-id="{CONTROLLER}:id/permission_message"
    text="Allow 味谱 to send you notifications?" enabled="true"/>
  <node package="{CONTROLLER}" resource-id="{CONTROLLER}:id/permission_allow_button"
    text="Allow" class="android.widget.Button"
    enabled="true" clickable="true" bounds="[90,1400][990,1520]"/>
</node>
</hierarchy>"""
CLOSED_UI = (
    f'<hierarchy rotation="0"><node package="{PACKAGE}" bounds="[0,0][1080,2400]"/></hierarchy>'
)

# Each adb command is a real subprocess. Markers coordinate with the child,
# avoiding imported/mocked observer implementations and fixed child runtimes.
FAKE_ADB = r"""
import json, os, pathlib, sys
p = pathlib.Path(os.environ["FIXTURE"])
c = json.loads((p / "config.json").read_text(encoding="utf-8"))
a = sys.argv[1:]
with (p / "adb.jsonl").open("a", encoding="utf-8") as log:
    log.write(json.dumps(a) + "\n")
assert a[:2] == ["-s", "fixture-device"]
a = a[2:]
def mark(name):
    (p / name).touch()
def output(value):
    sys.stdout.buffer.write(value.encode("utf-8"))
if a == ["shell", "dumpsys", "activity", "activities"]:
    mark("activity_seen")
    if not (p / "child_started").exists():
        output(c["main"])
    elif (p / "tapped").exists() and not c.get("dialog_stays"):
        output(c["main"])
    else:
        mark("dialog_seen")
        if c.get("adb_error"):
            sys.stderr.write("private fixture diagnostic must not be relayed")
            sys.exit(7)
        if c.get("adb_hang"):
            import time
            time.sleep(20)
        output(
            c.get("activity_after_ui", c["activity"])
            if (p / "ui_read").exists() else c["activity"]
        )
elif a[:4] == ["shell", "uiautomator", "dump", "--compressed"]:
    assert len(a) == 5 and a[4].startswith("/data/local/tmp/gramtree-notification-")
    (p / "dump_path").write_text(a[4], encoding="utf-8")
    output("UI hierchary dumped to: " + a[4])
elif a[:2] == ["exec-out", "cat"]:
    assert a[2] == (p / "dump_path").read_text(encoding="utf-8")
    if (p / "tapped").exists() and not c.get("dialog_stays"):
        mark("closed_read")
        output(c["closed"])
    else:
        mark("ui_read")
        output(c["ui"])
elif a[:3] == ["shell", "rm", "-f"]:
    assert a[3] == (p / "dump_path").read_text(encoding="utf-8")
    mark("removed")
elif a[:3] == ["shell", "input", "tap"]:
    assert a[3:] == c["tap"], a
    mark("tapped")
elif a == ["shell", "dumpsys", "package", "app.gramtree.gram_tree"]:
    mark("grant_read")
    output(c["grant"])
else:
    raise AssertionError("Unexpected adb command: " + repr(a))
"""

CHILD = r"""
import json, os, pathlib, sys, time
p = pathlib.Path(os.environ["FIXTURE"])
c = json.loads((p / "config.json").read_text(encoding="utf-8"))
assert (p / "activity_seen").exists(), "observer must start before child"
(p / "child_started").touch()
(p / "child.json").write_text(
    json.dumps({
        "argv": sys.argv[1:], "cwd": os.getcwd(), "env": os.environ["UNCHANGED_CHILD_ENV"]
    }),
    encoding="utf-8",
)
deadline = time.monotonic() + 12
while not (p / c["wait_for"]).exists():
    if time.monotonic() >= deadline:
        sys.exit(91)
    time.sleep(0.02)
# Give the observer time to consume the fixture response before child shutdown.
time.sleep(0.5)
print("fixture child output", flush=True)
if c.get("child_signal"):
    import signal
    os.kill(os.getpid(), signal.SIGTERM)
sys.exit(c.get("child_code", 0))
"""


class NotificationCliTest(unittest.TestCase):
    def invoke(self, **overrides):
        build = ROOT / "build"
        build.mkdir(exist_ok=True)
        config = {
            "activity": DIALOG_ACTIVITY,
            "main": MAIN_ACTIVITY,
            "ui": UI,
            "grant": GRANT,
            "closed": CLOSED_UI,
            "wait_for": "closed_read",
            "tap": ["540", "1460"],
        }
        config.update(overrides)
        with tempfile.TemporaryDirectory(prefix="notification-cli-", dir=build) as temporary:
            path = pathlib.Path(temporary)
            (path / "config.json").write_text(json.dumps(config), encoding="utf-8")
            (path / "adb.py").write_text(FAKE_ADB, encoding="utf-8")
            (path / "child.py").write_text(CHILD, encoding="utf-8")
            env = {
                **os.environ,
                "FIXTURE": str(path),
                "UNCHANGED_CHILD_ENV": "preserved",
            }
            argv = [
                "test",
                "integration_test",
                "--dart-define=APP_ENV=dev",
                "--dart-define=E2E_COMPOSITION_TIMEOUT_MS=3000",
                "--dart-define=API_BASE_URL=http://10.0.2.2:8000",
                "--dart-define-from-file=fixture with spaces.json",
                "-d",
                "fixture-device",
            ]
            result = subprocess.run(
                [
                    sys.executable,
                    "-B",
                    str(ROOT / "tool/android_notification_permission.py"),
                    "--serial",
                    "fixture-device",
                    "--adb",
                    sys.executable,
                    str(path / "adb.py"),
                    "--",
                    sys.executable,
                    str(path / "child.py"),
                    *argv,
                ],
                cwd=path,
                env=env,
                capture_output=True,
                text=True,
                encoding="utf-8",
                timeout=45,
                check=False,
            )
            commands = [
                json.loads(line)[2:]
                for line in (path / "adb.jsonl").read_text(encoding="utf-8").splitlines()
            ]
            child = json.loads((path / "child.json").read_text(encoding="utf-8"))
            self.assertEqual(child, {"argv": argv, "cwd": str(path), "env": "preserved"})
            self.assertIn("fixture child output", result.stdout)
            self.assertIn("Android notification observer stopped", result.stdout)
            self.assertNotIn("private fixture diagnostic", result.stderr)
            # All writes must be a bounds-derived tap or removal of our own dump.
            for command in commands:
                self.assertTrue(
                    command
                    in (
                        ["shell", "dumpsys", "activity", "activities"],
                        ["shell", "dumpsys", "package", PACKAGE],
                    )
                    or command[:4] == ["shell", "uiautomator", "dump", "--compressed"]
                    or command[:2] == ["exec-out", "cat"]
                    or command[:3] == ["shell", "rm", "-f"]
                    or command == ["shell", "input", "tap", *config["tap"]],
                    command,
                )
            # The wrapper exited; the log must stay still (no detached observer).
            before = (path / "adb.jsonl").read_bytes()
            time.sleep(0.35)
            self.assertEqual((path / "adb.jsonl").read_bytes(), before)
            return result, commands

    def assert_no_tap(self, commands):
        self.assertFalse(any(command[:3] == ["shell", "input", "tap"] for command in commands))

    def test_exact_notification_grant_and_child_argv(self):
        result, commands = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("permission granted and OS dialog closed", result.stdout)
        self.assertEqual(commands.count(["shell", "input", "tap", "540", "1460"]), 1)
        self.assertIn(["shell", "dumpsys", "package", PACKAGE], commands)
        self.assertTrue(any(command[:3] == ["shell", "rm", "-f"] for command in commands))

    def test_aosp_and_legacy_history_spacing_preserve_notification_grant(self):
        for spaces in (1, 2):
            with self.subTest(spaces=spaces):
                activity = DIALOG_ACTIVITY.replace("Hist  #", "Hist" + " " * spaces + "#")
                result, commands = self.invoke(activity=activity, wait_for="dialog_seen")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("permission granted and OS dialog closed", result.stdout)
                self.assertEqual(commands.count(["shell", "input", "tap", "540", "1460"]), 1)

    def test_unknown_history_spacing_fails_closed(self):
        for whitespace in ("", "   ", "\t", "\n"):
            with self.subTest(whitespace=repr(whitespace)):
                activity = DIALOG_ACTIVITY.replace("Hist  #", "Hist" + whitespace + "#")
                result, commands = self.invoke(activity=activity, wait_for="dialog_seen")
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn("history_headers=0, matching_records=0", result.stderr)
                self.assert_no_tap(commands)
                self.assertNotIn(RECORD, result.stderr)

    def test_history_record_mismatch_and_duplicates_fail_closed(self):
        header = f"* Hist  #1: {RECORD}"
        duplicate = (
            f"    * Hist  #2: {RECORD}\n"
            f"      launchedFromUid=10123 launchedFromPackage={PACKAGE} "
            "launchedFromFeature=null userId=0\n"
        )
        for activity, counts in (
            (
                DIALOG_ACTIVITY.replace(header, header.replace("abc123", "c0ffee")),
                "history_headers=2, matching_records=0",
            ),
            (
                DIALOG_ACTIVITY.replace(header, header.replace("t8}", "t9}")),
                "history_headers=2, matching_records=0",
            ),
            (DIALOG_ACTIVITY + duplicate, "history_headers=3, matching_records=2"),
        ):
            with self.subTest(counts=counts, activity=activity):
                result, commands = self.invoke(activity=activity, wait_for="dialog_seen")
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn(counts, result.stderr)
                self.assert_no_tap(commands)
                self.assertNotIn(RECORD, result.stderr)
                self.assertNotIn("c0ffee", result.stderr)

    def test_retained_permission_history_does_not_mean_open_dialog(self):
        main_with_history = (
            MAIN_ACTIVITY
            + f"    mLastPausedActivity={RECORD}\n"
            + f"    * Hist  #1: {RECORD}\n"
            + f"      launchedFromUid=10123 launchedFromPackage={PACKAGE} "
            + "launchedFromFeature=null userId=0\n"
        )
        result, commands = self.invoke(main=main_with_history)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("permission granted and OS dialog closed", result.stdout)
        self.assertEqual(commands.count(["shell", "input", "tap", "540", "1460"]), 1)

    def test_bounds_are_taken_from_current_ui_not_fixed_coordinates(self):
        result, commands = self.invoke(
            ui=UI.replace("[90,1400][990,1520]", "[100,1200][900,1300]"),
            tap=["500", "1250"],
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(commands.count(["shell", "input", "tap", "500", "1250"]), 1)

    def test_activity_change_before_tap_fails_closed(self):
        result, commands = self.invoke(activity_after_ui=MAIN_ACTIVITY, wait_for="ui_read")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("changed before notification tap", result.stderr)
        self.assert_no_tap(commands)

    def test_other_app_even_with_identical_label(self):
        for caller in ("other.app", PACKAGE + ".impostor"):
            with self.subTest(caller=caller):
                activity = DIALOG_ACTIVITY.replace(
                    f"launchedFromPackage={PACKAGE} ", f"launchedFromPackage={caller} "
                )
                result, commands = self.invoke(activity=activity, wait_for="dialog_seen")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assert_no_tap(commands)
                self.assertFalse(any(command[:2] == ["exec-out", "cat"] for command in commands))

    def test_other_permission_and_other_label(self):
        for text in (
            "Allow 味谱 to take pictures and record video?",
            "Allow Other to send you notifications?",
        ):
            with self.subTest(text=text):
                result, commands = self.invoke(
                    ui=UI.replace("Allow 味谱 to send you notifications?", text),
                    wait_for="ui_read",
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assert_no_tap(commands)

    def test_ambiguous_or_missing_caller_fails_closed(self):
        for activity in (
            DIALOG_ACTIVITY.replace("launchedFromPackage=" + PACKAGE, "callerPackage=" + PACKAGE),
            DIALOG_ACTIVITY.replace("topResumedActivity=", "mResumedActivity="),
            DIALOG_ACTIVITY.replace(RECORD, RECORD.replace("abc123", "unknown-format")),
        ):
            with self.subTest(activity=activity):
                result, commands = self.invoke(activity=activity, wait_for="dialog_seen")
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn("observer FAILED", result.stderr)
                self.assert_no_tap(commands)
                self.assertNotIn(activity, result.stderr)

    def test_disabled_malformed_xml_and_bounds_fail_closed(self):
        for xml in (
            UI.replace('enabled="true" clickable', 'enabled="false" clickable'),
            UI.replace("[90,1400][990,1520]", "[990,1400][90,1520]"),
            UI.replace("[90,1400][990,1520]", "garbage"),
            UI.replace("[90,1400][990,1520]", "[-1,1400][990,1520]"),
            UI.replace("[90,1400][990,1520]", "[90,1400][9999,1520]"),
            UI.replace("[90,1400][990,1520]", "[90,1400][90,1520]"),
            UI[:-12],
        ):
            with self.subTest(xml=xml):
                result, commands = self.invoke(ui=xml, wait_for="ui_read")
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assert_no_tap(commands)

    def test_button_mismatch_diagnostics_are_exact_and_private(self):
        for attribute, value, matches in (
            (
                "package",
                "private.fixture.controller",
                "package_match=False, text_match=True, class_match=True, "
                "enabled_match=True, clickable_match=True",
            ),
            (
                "text",
                "private button text",
                "package_match=True, text_match=False, class_match=True, "
                "enabled_match=True, clickable_match=True",
            ),
            (
                "class",
                "private.fixture.Button",
                "package_match=True, text_match=True, class_match=False, "
                "enabled_match=True, clickable_match=True",
            ),
            (
                "enabled",
                "false",
                "package_match=True, text_match=True, class_match=True, "
                "enabled_match=False, clickable_match=True",
            ),
            (
                "clickable",
                "false",
                "package_match=True, text_match=True, class_match=True, "
                "enabled_match=True, clickable_match=False",
            ),
        ):
            with self.subTest(attribute=attribute):
                tree = ET.fromstring(UI)
                button = list(tree.iter("node"))[-1]
                button.set(attribute, value)
                button.set("content-desc", "private-ui-marker")
                xml = ET.tostring(tree, encoding="unicode")
                result, commands = self.invoke(ui=xml, wait_for="ui_read")
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertEqual(
                    result.stderr,
                    "Android notification observer FAILED: "
                    "Notification Allow button is not an enabled controller button "
                    f"({matches})\n",
                )
                self.assert_no_tap(commands)
                output = result.stdout + result.stderr
                for private in (
                    xml,
                    "private-ui-marker",
                    "private.fixture.controller",
                    "private button text",
                    "private.fixture.Button",
                ):
                    self.assertNotIn(private, output)

    def test_controller_identity_and_resource_ids(self):
        tree = ET.fromstring(UI)
        button = list(tree.iter("node"))[-1]
        button.set("package", PACKAGE)
        result, commands = self.invoke(ui=ET.tostring(tree, encoding="unicode"), wait_for="ui_read")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assert_no_tap(commands)
        result, commands = self.invoke(
            ui=UI.replace(":id/permission_allow_button", ":id/not_allow"),
            wait_for="ui_read",
        )
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assert_no_tap(commands)

    def test_runtime_grant_and_dialog_closure_are_both_required(self):
        for overrides in (
            {"grant": GRANT.replace("granted=true", "granted=false")},
            {"grant": GRANT.replace("User 0:", "User 10:")},
            {"grant": GRANT.replace(f"Package [{PACKAGE}]", "Package [other.app]")},
            {"dialog_stays": True},
        ):
            with self.subTest(overrides=overrides):
                result, commands = self.invoke(**overrides, wait_for="tapped")
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn("verification timed out", result.stderr)
                self.assertEqual(commands.count(["shell", "input", "tap", "540", "1460"]), 1)

    def test_child_failure_code_is_exact_even_on_observer_failure(self):
        for overrides in ({}, {"adb_error": True, "wait_for": "dialog_seen"}):
            with self.subTest(overrides=overrides):
                result, _ = self.invoke(**overrides, child_code=37)
                self.assertEqual(result.returncode, 37, result.stderr)

    def test_child_termination_status(self):
        if os.name == "posix":
            result, _ = self.invoke(child_signal=True)
            self.assertEqual(result.returncode, -signal.SIGTERM, result.stderr)
        else:
            # Windows has normal process exit codes, not POSIX signal statuses.
            result, _ = self.invoke(child_code=143)
            self.assertEqual(result.returncode, 143, result.stderr)

    def test_adb_failure_is_not_silent_success(self):
        result, commands = self.invoke(adb_error=True, wait_for="dialog_seen")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("adb command failed", result.stderr)
        self.assert_no_tap(commands)

    def test_bounded_observer_cleanup_during_adb_timeout(self):
        start = time.monotonic()
        result, commands = self.invoke(adb_hang=True, wait_for="dialog_seen")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("adb command timed out", result.stderr)
        self.assertLess(time.monotonic() - start, 15)
        self.assert_no_tap(commands)


if __name__ == "__main__":
    unittest.main()
