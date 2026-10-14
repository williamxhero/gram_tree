"""Seed synthetic comparison/sharing via HTTP and test-only CLI; export no credentials."""

import argparse
import hashlib
import hmac
import json
import os
import secrets
import subprocess
import sys
import time
import uuid
from copy import deepcopy
from pathlib import Path
from urllib.parse import quote, urlsplit

import httpx

ROOT = Path(__file__).resolve().parent.parent


def sign_in(client: httpx.Client, email: str) -> int:
    """Keep device credentials in memory; share the independent HTTP signer."""
    sent = client.post("/v1/auth/email/code", json={"email": email, "purpose": "login"})
    sent.raise_for_status()
    not_before = int((time.time() + sent.json()["resend_after_seconds"] + 2) * 1000)
    code = client.get("/v1/dev/latest-email-code", params={"email": email})
    code.raise_for_status()
    login = client.post("/v1/auth/email/login", json={"email": email, "code": code.json()["code"]})
    login.raise_for_status()
    credentials = login.json()
    client.headers["Authorization"] = f"Bearer {credentials['access_token']}"
    signing_key = credentials["request_signing_key"]

    def sign_request(request: httpx.Request) -> None:
        timestamp = str(int(time.time()))
        nonce = secrets.token_hex(16)
        fields = (
            request.method,
            request.url.path,
            request.url.query.decode("ascii"),
            timestamp,
            nonce,
            hashlib.sha256(request.content).hexdigest(),
        )
        message = "\n".join(quote(field, safe="/-_.~=&") for field in fields).encode()
        request.headers["X-Request-Timestamp"] = timestamp
        request.headers["X-Request-Nonce"] = nonce
        request.headers["X-Request-Signature"] = hmac.new(
            signing_key.encode(), message, hashlib.sha256
        ).hexdigest()

    client.event_hooks["request"].append(sign_request)
    return not_before


def seed_sharing(api: str, recipe_template: dict) -> dict[str, str]:
    # A separate actor avoids sharing OTP cooldowns with the comparison journey.
    email = f"public-sharing-{uuid.uuid4().hex}@example.com"
    with httpx.Client(
        base_url=api, timeout=30, headers={"x-device-id": str(uuid.uuid4())}
    ) as client:
        not_before = sign_in(client, email)
        recipe = deepcopy(recipe_template)
        recipe["dish_name"] = "公开分享联调菜"
        recipe["snapshot"]["description"] = "仅供端到端验收的合成公开简介"
        created = client.post("/v1/recipes", json=recipe)
        created.raise_for_status()
        recipe_id = created.json()["id"]
        # Only the existing test-environment CLI can approve a public fixture.
        # Never relax the production default or change any comparison pair.
        for arguments in (
            ["config", "set", "feature.public_recipes", "true"],
            ["recipes", "seed-sharing-state", recipe_id, "--visibility", "public", "--approved"],
        ):
            subprocess.run(
                [
                    sys.executable,
                    "-m",
                    "gramtree.cli",
                    *arguments,
                    "--by",
                    "e2e",
                    "--reason",
                    "Synthetic live sharing acceptance",
                ],
                check=True,
                stdout=subprocess.DEVNULL,
            )
        shared = client.post(f"/v1/recipes/{recipe_id}/share")
        shared.raise_for_status()
        link = shared.json()
        assert len(link["share_id"]) == 43, link
        assert link["app_path"] == f"/recipes/{recipe_id}", link
        assert urlsplit(link["url"]).scheme == "https", link
        assert urlsplit(link["url"]).path == f"/s/{link['share_id']}", link
        return {
            "E2E_SHARING_EMAIL": email,
            "E2E_SHARING_LOGIN_NOT_BEFORE_MS": str(not_before),
            "E2E_SHARING_RECIPE_ID": recipe_id,
            "E2E_SHARING_SHARE_ID": link["share_id"],
            "E2E_SHARING_URL": link["url"],
            "E2E_SHARING_TITLE": recipe["dish_name"],
        }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--api", required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    if os.environ.get("GRAMTREE_ENV") != "test":
        parser.error("Synthetic approval fixtures require GRAMTREE_ENV=test")
    if urlsplit(args.api).hostname not in {"localhost", "127.0.0.1", "10.0.2.2", "::1"}:
        parser.error("Synthetic fixtures require a local test server")
    if args.out.exists():
        parser.error("Fixture output already exists; choose a fresh output path")
    corpus = json.loads(
        (ROOT / "server/tests/fixtures/ai/comparison_assistance_corpus.json").read_text("utf-8")
    )
    email = f"comparison-assistance-{uuid.uuid4().hex}@example.com"
    device_id = str(uuid.uuid4())
    with httpx.Client(base_url=args.api, timeout=30, headers={"x-device-id": device_id}) as client:
        not_before = sign_in(client, email)
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
    defines.update(seed_sharing(args.api, corpus["recipe"]))
    with args.out.open("x", encoding="utf-8") as output:
        json.dump(defines, output, ensure_ascii=False, indent=2)
    print(f"Seeded four comparison pairs and one public share; token-free defines: {args.out}")


if __name__ == "__main__":
    main()
