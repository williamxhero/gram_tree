"""Seed synthetic comparison acceptance through public HTTP; export no credentials."""

import argparse
import json
import time
import uuid
from copy import deepcopy
from pathlib import Path
from urllib.parse import urlsplit

import httpx

ROOT = Path(__file__).resolve().parent.parent


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--api", required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    if urlsplit(args.api).hostname not in {"localhost", "127.0.0.1", "10.0.2.2", "::1"}:
        parser.error("Synthetic fixtures require a local test server")
    if args.out.exists():
        parser.error("Fixture output already exists; choose a fresh output path")
    corpus = json.loads(
        (ROOT / "server/tests/fixtures/ai/comparison_assistance_corpus.json").read_text("utf-8")
    )
    email = f"comparison-assistance-{uuid.uuid4().hex}@example.com"
    with httpx.Client(base_url=args.api, timeout=30) as client:
        sent = client.post("/v1/auth/email/code", json={"email": email, "purpose": "login"})
        sent.raise_for_status()
        not_before = int((time.time() + sent.json()["resend_after_seconds"] + 2) * 1000)
        code = client.get("/v1/dev/latest-email-code", params={"email": email})
        code.raise_for_status()
        login = client.post(
            "/v1/auth/email/login", json={"email": email, "code": code.json()["code"]}
        )
        login.raise_for_status()
        client.headers["Authorization"] = f"Bearer {login.json()['access_token']}"
        defines = {
            "E2E_ASSISTANCE_EMAIL": email,
            "E2E_ASSISTANCE_LOGIN_NOT_BEFORE_MS": str(not_before),
        }
        invariant = None
        for name, scenario in corpus["scenarios"].items():
            recipe = deepcopy(corpus["recipe"])
            recipe["dish_name"] = scenario["dish_name"]
            created = client.post("/v1/recipes", json=recipe)
            created.raise_for_status()
            before = created.json()
            snapshot = deepcopy(before["version"]["snapshot"])
            snapshot["steps"] = deepcopy(corpus["after_steps"])
            saved = client.post(f"/v1/recipes/{before['id']}/versions", json={"snapshot": snapshot})
            saved.raise_for_status()
            after = saved.json()
            pair = {
                "from_version_id": before["version"]["id"],
                "to_version_id": after["version"]["id"],
            }
            compared = client.get(f"/v1/recipes/{before['id']}/full-comparison", params=pair)
            compared.raise_for_status()
            result = compared.json()
            assert result["conclusion"] == "general", result
            assert all(row["alignment"] == "uncertain" for row in result["steps"]), result
            assert before["version"]["conclusion"] is None, before
            assert after["version"]["conclusion"] == "general", after
            current = {
                key: result[key]
                for key in (
                    "conclusion",
                    "rules_version",
                    "ingredients",
                    "steps",
                    "snapshot_fields",
                    "method_changes",
                )
            }
            if invariant is None:
                invariant = current
            else:
                assert current == invariant, "AI scenarios must preserve deterministic differences"
            defines[f"E2E_ASSISTANCE_{name}_RECIPE_ID"] = before["id"]
            defines[f"E2E_ASSISTANCE_{name}_FROM_VERSION_ID"] = pair["from_version_id"]
            defines[f"E2E_ASSISTANCE_{name}_TO_VERSION_ID"] = pair["to_version_id"]
    with args.out.open("x", encoding="utf-8") as output:
        json.dump(defines, output, ensure_ascii=False, indent=2)
    print(f"Seeded four synthetic comparison pairs; token-free defines: {args.out}")


if __name__ == "__main__":
    main()
