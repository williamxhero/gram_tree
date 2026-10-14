import json
import pathlib
import subprocess
import sys
import tempfile
import unittest

_ROOT = pathlib.Path(__file__).resolve().parent.parent


class ApiClientProjectionTest(unittest.TestCase):
    def test_compose_enum_default_is_explicit_without_changing_server_contract(self) -> None:
        document = {
            "components": {
                "schemas": {
                    "ComposeRequest": {
                        "type": "object",
                        "required": ["page_type"],
                        "properties": {
                            "page_type": {"type": "string"},
                            "personalization_view": {
                                "type": "string",
                                "enum": ["personalized", "original"],
                                "default": "personalized",
                            },
                            "screen_width": {"type": "integer", "default": 400},
                        },
                    }
                }
            }
        }
        build = _ROOT / "build"
        build.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="api-client-test-", dir=build) as temporary:
            source = pathlib.Path(temporary) / "openapi.json"
            target = pathlib.Path(temporary) / "client.json"
            canonical = json.dumps(document)
            source.write_text(canonical, encoding="utf-8")
            subprocess.run(
                [
                    sys.executable,
                    str(_ROOT / "tool" / "prepare_api_client.py"),
                    str(source),
                    str(target),
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            projected = json.loads(target.read_text(encoding="utf-8"))
            request = projected["components"]["schemas"]["ComposeRequest"]
            self.assertEqual(request["required"], ["page_type", "personalization_view"])
            self.assertEqual(
                request["properties"]["personalization_view"],
                {"type": "string", "enum": ["personalized", "original"]},
            )
            self.assertEqual(request["properties"]["screen_width"]["default"], 400)
            self.assertEqual(source.read_text(encoding="utf-8"), canonical)


if __name__ == "__main__":
    unittest.main()
