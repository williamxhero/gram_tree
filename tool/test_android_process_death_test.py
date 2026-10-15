import collections
import importlib.util
import pathlib
import unittest


_MODULE_PATH = pathlib.Path(__file__).with_name("android_process_death_test.py")
_SPEC = importlib.util.spec_from_file_location("android_process_death_test", _MODULE_PATH)
assert _SPEC is not None and _SPEC.loader is not None
_MODULE = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(_MODULE)


class SafeFailureLogTest(unittest.TestCase):
    def test_includes_redacted_dart_diagnostics_with_pid(self) -> None:
        watch = _MODULE.LogWatch.__new__(_MODULE.LogWatch)
        watch.run_id = "abc123"
        watch.recent = collections.deque(
            [
                "I/flutter: GRAMTREE_PROCESS_DETAIL abc123 pid=4935 phase=restore TestFailure",
                "I/flutter: #0 _restore (package:gram_tree/process_death_harness.dart:456:3)",
            ],
            maxlen=200,
        )

        self.assertEqual(
            "\n".join(
                [
                    "GRAMTREE_PROCESS_DETAIL abc123 pid=4935 phase=restore TestFailure",
                    "#0 _restore (package:gram_tree/process_death_harness.dart:456:3)",
                ]
            ),
            watch.safe_failure_log(),
        )

    def test_keeps_local_probe_rejection_distinct_from_transport_failure(self) -> None:
        watch = _MODULE.LogWatch.__new__(_MODULE.LogWatch)
        watch.run_id = "abc123"
        watch.recent = collections.deque(maxlen=200)
        watch.safe_recent = collections.deque(maxlen=200)
        diagnostic = (
            "GRAMTREE_PROCESS_DETAIL abc123 pid=4935 phase=business_restore "
            "step=verify authoritative version, fact and history "
            "DioException type=unknown status=null cause=probe_credential_missing"
        )
        watch._remember_safe_line(f"I/flutter: {diagnostic}")
        watch._remember_safe_line("I/flutter: Authorization: Bearer secret")

        self.assertEqual(watch.safe_failure_log(), diagnostic)

    def test_keeps_markers_and_redacts_framework_failure(self) -> None:
        watch = _MODULE.LogWatch.__new__(_MODULE.LogWatch)
        watch.run_id = "abc123"
        watch.recent = collections.deque(
            [
                "I/flutter: GRAMTREE_PROCESS_DEATH abc123 BOOT pid=4935",
                "E/flutter: EXCEPTION CAUGHT BY WIDGETS LIBRARY",
                "E/flutter: secret business payload",
                "I/flutter: GRAMTREE_PROCESS_DEATH abc123 FAILED pid=4935",
            ],
            maxlen=200,
        )

        self.assertEqual(
            "\n".join(
                [
                    "GRAMTREE_PROCESS_DEATH abc123 BOOT pid=4935",
                    "Native/framework failure detected (raw message omitted)",
                    "GRAMTREE_PROCESS_DEATH abc123 FAILED pid=4935",
                ]
            ),
            watch.safe_failure_log(),
        )

    def test_safe_stream_survives_logcat_noise(self) -> None:
        watch = _MODULE.LogWatch.__new__(_MODULE.LogWatch)
        watch.run_id = "abc123"
        watch.safe_recent = collections.deque(maxlen=200)
        watch.recent = collections.deque(maxlen=200)
        watch._remember_safe_line(
            "I/flutter: GRAMTREE_PROCESS_DEATH abc123 BOOT pid=4935"
        )
        for index in range(250):
            watch.recent.append(f"I/flutter: routine frame {index}")
            watch._remember_safe_line(f"I/flutter: routine frame {index}")
        watch._remember_safe_line(
            "I/flutter: GRAMTREE_PROCESS_DEATH abc123 FAILED pid=4935"
        )

        self.assertEqual(
            "\n".join(
                [
                    "GRAMTREE_PROCESS_DEATH abc123 BOOT pid=4935",
                    "GRAMTREE_PROCESS_DEATH abc123 FAILED pid=4935",
                ]
            ),
            watch.safe_failure_log(),
        )


if __name__ == "__main__":
    unittest.main()
