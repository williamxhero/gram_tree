"""Public CLI diagnostics with synthetic reports; not Android runtime acceptance."""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOL = ROOT / "tool/android_native_diagnostics.py"
CLASS = "app.gramtree.gram_tree.ExportFileShareTest"
TEST = "testClickWaitsForActionableRowInsteadOfSameNamedTitle"
RESULTS = "app/build/app/outputs/androidTest-results/connected/debug"
FAKE_ADB = """
import json, os, pathlib, sys
p = pathlib.Path(os.environ['FIXTURE'])
with (p / 'calls.jsonl').open('a', encoding='utf-8') as output:
    output.write(json.dumps(sys.argv[1:]) + '\\n')
config = json.loads((p / 'adb.json').read_text(encoding='utf-8'))
sys.stdout.write(config.get('output', ''))
sys.stderr.write('private adb failure https://secret.invalid/token')
sys.exit(config.get('exit', 0))
"""


class NativeDiagnosticsCliTest(unittest.TestCase):
    def invoke(self, reports=None, *, crash="", adb_exit=0, cli_args=()):
        build = ROOT / "build"
        build.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="native-diagnostic-cli-", dir=build) as temporary:
            fixture = Path(temporary)
            (fixture / "tool").mkdir()
            if TOOL.exists():
                shutil.copyfile(TOOL, fixture / "tool/android_native_diagnostics.py")
            results = fixture / RESULTS
            results.mkdir(parents=True)
            for name, content in (reports or {}).items():
                target = results / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(content.encode() if isinstance(content, str) else content)
            (fixture / "adb.py").write_text(FAKE_ADB, encoding="utf-8")
            (fixture / "adb.json").write_text(
                json.dumps({"output": crash, "exit": adb_exit}), encoding="utf-8"
            )
            result = subprocess.run(
                [
                    sys.executable,
                    "-B",
                    str(fixture / "tool/android_native_diagnostics.py"),
                    "--serial",
                    "fixture-device",
                    "--adb",
                    sys.executable,
                    str(fixture / "adb.py"),
                    *cli_args,
                ],
                cwd=fixture,
                env={**os.environ, "FIXTURE": str(fixture)},
                capture_output=True,
                text=True,
                encoding="utf-8",
                timeout=15,
            )
            calls = fixture / "calls.jsonl"
            commands = (
                [json.loads(line) for line in calls.read_text().splitlines()]
                if calls.exists()
                else []
            )
            return result, commands

    def test_reports_only_known_test_exception_and_frames(self):
        report = f"""<testsuite><testcase classname="{CLASS}" name="{TEST}">
        <failure type="java.lang.IllegalStateException" message="https://secret.invalid/token">
java.lang.IllegalStateException: UiAutomationService private already registered!
    at android.app.UiAutomation.connectWithTimeout(UiAutomation.java:381)
    at {CLASS}.waitForNode(ExportFileShareTest.kt:193)
        </failure></testcase></testsuite>"""
        result, commands = self.invoke({"TEST-fixture.xml": report})
        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        self.assertEqual(output["xml_status"], "ok")
        self.assertEqual(
            output["tests"],
            [
                {
                    "test": TEST,
                    "result": "failure",
                    "category": "service_registration_conflict",
                    "exception": "java.lang.IllegalStateException",
                    "frames": [
                        "android.app.UiAutomation.connectWithTimeout:381",
                        f"{CLASS}.waitForNode:193",
                    ],
                }
            ],
        )
        self.assertEqual(output["crash"]["binding"], "unverified_recent")
        self.assertNotIn("secret", result.stdout + result.stderr)
        self.assertEqual(
            commands,
            [["-s", "fixture-device", "logcat", "-d", "-b", "crash", "-t", "120", "-v", "brief"]],
        )

    def test_generic_crash_does_not_claim_an_initial_exception(self):
        report = (
            f'<testsuite><testcase classname="{CLASS}" name="{TEST}">'
            '<failure message="Process crashed. https://private.invalid/token"/>'
            "</testcase></testsuite>"
        )
        result, _ = self.invoke({"TEST-fixture.xml": report})
        self.assertEqual(result.returncode, 0, result.stderr)
        event = json.loads(result.stdout)["tests"][0]
        self.assertEqual(event["category"], "process_crashed")
        self.assertEqual(event["exception"], "unknown")
        self.assertEqual(event["frames"], [])
        self.assertNotIn("private", result.stdout + result.stderr)

    def test_messages_cannot_smuggle_valid_looking_stack_symbols(self):
        report = f"""<testsuite secret="PRIVATE_ATTRIBUTE"><system-out>PRIVATE_OUTPUT</system-out>
<testcase classname="{CLASS}" name="{TEST}">
<failure type="java.lang.PRIVATE_EXCEPTION"
 message="PRIVATE_MESSAGE&#10; at android.app.UiAutomation.PRIVATE_METHOD(File.java:123)">
java.lang.PRIVATE_EXCEPTION: PRIVATE_BODY
    at android.app.PRIVATE_CLASS.run(File.java:123)
    at {CLASS}.PRIVATE_CALLBACK(File.java:123)
    at android.app.UiAutomation.PRIVATE_METHOD(File.java:123)
    at android.app.UiAutomation.connect(UiAutomation.java:339)
</failure></testcase>
<testcase classname="private.ForeignTest" name="{TEST}">
<failure>PRIVATE_FOREIGN</failure></testcase>
<testcase classname="{CLASS}" name="PRIVATE_TEST"><failure>PRIVATE_UNKNOWN_TEST</failure></testcase>
</testsuite>"""
        result, _ = self.invoke({"TEST-fixture.xml": report})
        self.assertEqual(result.returncode, 0, result.stderr)
        event = json.loads(result.stdout)["tests"][0]
        self.assertEqual(event["exception"], "unknown")
        self.assertEqual(event["frames"], ["android.app.UiAutomation.connect:339"])
        self.assertNotIn("PRIVATE", result.stdout + result.stderr)
        self.assertEqual(len(json.loads(result.stdout)["tests"]), 1)

    def test_only_target_crash_is_summarized_and_is_explicitly_unverified(self):
        crash = (
            "E/AndroidRuntime(26456): FATAL EXCEPTION: "
            "Instr: android.test.InstrumentationTestRunner\n"
            "E/AndroidRuntime(26456): Process: app.gramtree.gram_tree, PID: 26456\n"
            "E/AndroidRuntime(26456): java.lang.IllegalStateException: "
            "Cannot call disconnect() while connecting UiAutomation@PRIVATE\n"
            "E/AndroidRuntime(26456): \tat android.app.UiAutomation.disconnect"
            "(UiAutomation.java:380)\n"
            f"""E/AndroidRuntime(26456): \tat {CLASS}.PRIVATE_CANARY(File.java:123)
E/AndroidRuntime(99): FATAL EXCEPTION: main
E/AndroidRuntime(99): Process: private.foreign, PID: 99
E/AndroidRuntime(99): java.lang.NullPointerException: PRIVATE_FOREIGN
E/AndroidRuntime(99): \tat android.app.UiAutomation.connect(File.java:123)
"""
        )
        result, commands = self.invoke(crash=crash)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            json.loads(result.stdout)["crash"],
            {
                "status": "ok",
                "binding": "unverified_recent",
                "category": "disconnect_during_connect",
                "exception": "java.lang.IllegalStateException",
                "frames": ["android.app.UiAutomation.disconnect:380"],
            },
        )
        self.assertNotIn("PRIVATE", result.stdout + result.stderr)
        self.assertNotIn("26456", result.stdout)
        self.assertEqual(len(commands), 1)

    def test_target_native_signal_is_unverified_and_never_relays_tombstone_details(self):
        for identity, signal, category in (
            ("Cmdline: app.gramtree.gram_tree", "6 (SIGABRT)", "native_sigabrt"),
            (
                "pid: 7, tid: 8, name: PRIVATE_THREAD  >>> app.gramtree.gram_tree <<<",
                "11 (SIGSEGV)",
                "native_sigsegv",
            ),
        ):
            with self.subTest(category=category):
                crash = (
                    "F/DEBUG   ( 77): *** *** *** *** *** *** *** *** "
                    "*** *** *** *** *** *** *** ***\n"
                    f"F/DEBUG   ( 77): {identity}\n"
                    f"F/DEBUG   ( 77): signal {signal}, code -1 (PRIVATE_CODE), "
                    "fault addr 0xdeadbeef\n"
                    "F/DEBUG   ( 77): Abort message: 'PRIVATE_MESSAGE https://private.invalid/token'\n"
                    "F/DEBUG   ( 77):     x0  0123456789abcdef\n"
                    "F/DEBUG   ( 77): backtrace:\n"
                    "F/DEBUG   ( 77):     #00 pc 000000001234abcd /data/PRIVATE_PATH/lib.so\n"
                    "F/DEBUG   ( 77): at android.app.UiAutomation.connect(PRIVATE.java:339)\n"
                )
                result, commands = self.invoke(crash=crash)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(
                    json.loads(result.stdout)["crash"],
                    {
                        "status": "ok",
                        "binding": "unverified_recent",
                        "category": category,
                        "exception": "unknown",
                        "frames": [],
                    },
                )
                for secret in ("PRIVATE", "private", "deadbeef", "0123456789abcdef", "1234abcd"):
                    self.assertNotIn(secret, result.stdout + result.stderr)
                self.assertEqual(len(commands), 1)

    def test_foreign_native_tombstones_are_ignored(self):
        for identity in (
            "Cmdline: private.foreign",
            "pid: 7, tid: 8, name: PRIVATE_THREAD  >>> private.foreign <<<",
        ):
            with self.subTest(identity=identity):
                result, commands = self.invoke(
                    crash=(
                        "F/DEBUG   (77): *** *** *** ***\n"
                        f"F/DEBUG   (77): {identity}\n"
                        "F/DEBUG   (77): signal 11 (SIGSEGV), code 1, fault addr 0xdeadbeef\n"
                        "F/DEBUG   (77): Abort message: PRIVATE_FOREIGN\n"
                    )
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(
                    json.loads(result.stdout)["crash"],
                    {"status": "absent", "binding": "unverified_recent"},
                )
                self.assertNotIn("PRIVATE", result.stdout + result.stderr)
                self.assertNotIn("deadbeef", result.stdout)
                self.assertEqual(len(commands), 1)

    def test_absent_reports_and_failed_adb_reveal_no_error_details(self):
        result, commands = self.invoke(adb_exit=7)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            json.loads(result.stdout),
            {
                "xml_status": "absent",
                "tests": [],
                "crash": {"status": "unavailable", "binding": "unverified_recent"},
            },
        )
        self.assertNotIn("private", result.stdout + result.stderr)
        self.assertEqual(len(commands), 1)

    def test_xml_entities_and_malformed_reports_are_not_echoed(self):
        for report in (
            '<!DOCTYPE suite [<!ENTITY secret "PRIVATE_ENTITY">]><testsuite>&secret;</testsuite>',
            "<testsuite PRIVATE_MALFORMED",
            (
                '<!DOCTYPE suite [<!ENTITY secret "PRIVATE_ENTITY">]>'
                "<testsuite>&secret;</testsuite>"
            ).encode("utf-16"),
        ):
            with self.subTest(report=report):
                result, _ = self.invoke({"TEST-fixture.xml": report})
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads(result.stdout)["xml_status"], "invalid")
                self.assertNotIn("PRIVATE", result.stdout + result.stderr)

    def test_unknown_xml_encoding_does_not_leak_fields_or_tracebacks(self):
        result, commands = self.invoke(
            {
                "TEST-fixture.xml": (
                    '<?xml version="1.0" encoding="PRIVATE_ENCODING_CANARY"?><testsuite/>'
                )
            }
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["xml_status"], "invalid")
        self.assertEqual(result.stderr, "")
        self.assertNotIn("PRIVATE", result.stdout)
        self.assertNotIn("Traceback", result.stdout)
        self.assertEqual(len(commands), 1)

    def test_file_count_size_and_frame_output_have_hard_limits(self):
        frames = "\n".join(
            "    at android.app.UiAutomation.connect(File.java:339)" for _ in range(40)
        )
        report = (
            f'<testsuite><testcase classname="{CLASS}" name="{TEST}">'
            f"<failure>{frames}</failure></testcase></testsuite>"
        )
        for reports in (
            {"TEST-large.xml": b"PRIVATE_OVERSIZED" * 9000},
            {f"TEST-{i}.xml": report for i in range(9)},
        ):
            with self.subTest(files=len(reports)):
                result, _ = self.invoke(reports)
                self.assertEqual(result.returncode, 0, result.stderr)
                output = json.loads(result.stdout)
                self.assertEqual(output["xml_status"], "limited")
                self.assertLessEqual(sum(len(t["frames"]) for t in output["tests"]), 12)
                self.assertLess(len(result.stdout), 6144)
                self.assertNotIn("PRIVATE", result.stdout + result.stderr)

    def test_oversized_crash_output_is_bounded_without_relay(self):
        result, commands = self.invoke(crash="PRIVATE_CRASH" * 20000)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["crash"]["status"], "limited")
        self.assertNotIn("PRIVATE", result.stdout + result.stderr)
        self.assertEqual(len(commands), 1)

    def test_crash_pid_mismatch_cannot_claim_the_target_package(self):
        result, _ = self.invoke(
            crash="""E/AndroidRuntime(99): FATAL EXCEPTION: main
E/AndroidRuntime(99): Process: app.gramtree.gram_tree, PID: 26456
E/AndroidRuntime(99): java.lang.IllegalStateException: PRIVATE
E/AndroidRuntime(99): \tat android.app.UiAutomation.disconnect(File.java:380)
"""
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["crash"]["status"], "absent")
        self.assertNotIn("PRIVATE", result.stdout + result.stderr)

    def test_invalid_cli_fields_are_not_reflected(self):
        result, commands = self.invoke(cli_args=("--PRIVATE_ARGUMENT", "PRIVATE_VALUE"))
        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stderr, "native_diagnostics invalid_arguments\n")
        self.assertEqual(result.stdout, "")
        self.assertEqual(commands, [])

    def test_nested_reports_and_global_frame_budget(self):
        frames = "\n".join(" at android.app.UiAutomation.connect(File.java:339)" for _ in range(40))
        report = (
            f'<testsuite><testcase classname="{CLASS}" name="{TEST}">'
            f"<failure>{frames}</failure></testcase></testsuite>"
        )
        crash = """E/AndroidRuntime(7): FATAL EXCEPTION: main
E/AndroidRuntime(7): Process: app.gramtree.gram_tree, PID: 7
E/AndroidRuntime(7): java.lang.IllegalStateException: PRIVATE
E/AndroidRuntime(7): at android.app.UiAutomation.disconnect(File.java:380)
"""
        result, _ = self.invoke({"device/TEST-PRIVATE_FILENAME.xml": report}, crash=crash)
        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        self.assertEqual(output["xml_status"], "ok")
        self.assertEqual(len(output["tests"][0]["frames"]), 12)
        self.assertEqual(output["crash"]["frames"], [])
        self.assertLess(len(result.stdout), 6144)
        self.assertNotIn("PRIVATE", result.stdout + result.stderr)

    def test_workflow_preserves_native_failure_even_if_diagnostics_fail(self):
        lines = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8").splitlines()
        command = next(
            line.strip() for line in lines if "./gradlew :app:connectedDebugAndroidTest" in line
        )
        build = ROOT / "build"
        build.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="native-workflow-cli-", dir=build) as temporary:
            fixture = Path(temporary)
            android = fixture / "app/android"
            android.mkdir(parents=True)
            binaries = fixture / "bin"
            binaries.mkdir()
            gradle = android / "gradlew"
            gradle.write_text(
                '#!/bin/sh\nprintf "native_called\\n"\nprintf "arg=%s\\n" "$@"\n'
                'test -f expected-android-cwd || exit 92\nexit "$NATIVE_FIXTURE_EXIT"\n',
                encoding="utf-8",
            )
            (android / "expected-android-cwd").touch()
            diagnostic = binaries / "python3"
            diagnostic.write_text(
                '#!/bin/sh\nprintf "diagnostic_called\\n"\nexit 73\n', encoding="utf-8"
            )
            gradle.chmod(0o755)
            diagnostic.chmod(0o755)
            for code in (0, 17):
                with self.subTest(native_exit=code):
                    result = subprocess.run(
                        [shutil.which("bash"), "-e", "-c", command],
                        cwd=fixture / "app",
                        env={
                            **os.environ,
                            "PATH": str(binaries) + os.pathsep + os.environ["PATH"],
                            "NATIVE_FIXTURE_EXIT": str(code),
                        },
                        capture_output=True,
                        text=True,
                        encoding="utf-8",
                        timeout=10,
                    )
                    self.assertEqual(result.returncode, code, result.stderr)
                    self.assertEqual(result.stdout.count("native_called"), 1)
                    self.assertEqual(
                        [
                            line[4:]
                            for line in result.stdout.splitlines()
                            if line.startswith("arg=")
                        ],
                        [
                            ":app:connectedDebugAndroidTest",
                            "-Ptarget=lib/main.dart",
                            "-Pandroid.testInstrumentationRunnerArguments.class=" + CLASS,
                        ],
                    )
                    self.assertEqual(result.stdout.count("diagnostic_called"), int(code != 0))


if __name__ == "__main__":
    unittest.main()
