"""Public format documentation served on the same website as legal/share pages."""

from html import escape

from fastapi import APIRouter
from fastapi.responses import HTMLResponse

from gramtree.exports.archive import UNAVAILABLE_ENTITIES

router = APIRouter(include_in_schema=False)
FORMAT_DESCRIPTION = """
The ZIP contains UTF-8 JSON files, one file per supported entity, plus photos/.
Every entity file has format_version (integer 1), entity (name) and items (array).
manifest.json has format_version, exported_at (RFC3339 UTC), owner_id,
format_documentation, supported_entities, unavailable_entities, scope,
complete_spec47_export and excluded. IDs are UUID strings. Missing optional
values are null; timestamps include timezone. Empty supported entities have
items: []. A missing file is NOT proof that the account has no such data.

account: nickname, timezone/settings, phone, real-name status and creation time.
identities: kind, email, creation time (never tokens or credential hashes).
consents: all agreement/withdrawal receipts.
recipes: every owned recipe, visibility/current version and minimal source.
recipe_versions: all immutable versions, draft/private and taken-down included;
snapshot, edit_operations/intents, change_note, derived values/provenance and
original text, reproducibility, change conclusion/rules, safety checks and
ai_assisted are retained. No aggregate/trust/score data is included.
source references contain only nickname, title, version and relative link;
source_recipe/source snapshots and another user's full recipe are not exported.
cooking_records and cooking_record_revisions: frozen displayed content,
conversion context, adjustments, ratings/feedback/tags/original words, co-diners
and verification are retained as stored personal history.
taste_profiles and taste_profile_changes: ordinary values, versions, reasons,
locks, application/revert timestamps and source record IDs.
personal_measures: all owner tools including soft-deleted tools.
ai_generation_drafts, ai_modification_suggestions and
quantification_suggestions: owner drafts/proposals/decisions, with explicit
ai_assisted: true. Modification baselines (potential foreign snapshots) and
AI call/accounting/log rows are not included. Per-field AI provenance is kept.
recipe_imports: owned import source and original text, never encrypted bytes.
events: only this owner's exact type/version marked exportable in the registry;
content follows that version's schema. Non-exportable events and internal
fingerprints/risk flags are excluded. UI composition history is in these events.
photos.json: image metadata and relative archive paths; photos/ contains the
stored original uploads after location/EXIF stripping, including staged uploads.

This release exports SUPPORTED SERVER ENTITIES ONLY, not the complete SPEC-47
promise. unavailable_entities explicitly identifies domains not yet persisted
and encrypted family/allergy values not authorized for export by the current
privacy boundary. Sensitive change values are withheld, never decrypted here.
Client-local unsynced recipe drafts and pending offline writes are unavailable; a
recipe version appears here only after it has been committed to the server.

Only the authenticated owner can create/read/retry/download an export. Creation
and retry require recent identity reauthentication. A separate UTC-day quota is
controlled by export.daily_limit (default 3). Expiry is controlled by
export.download_ttl_seconds (default 86400 seconds, 24 hours after completion).
Signed links are relative, same-host, require login, and do not extend expiry.
No access/audit/moderation/risk logs, aggregate people counts, internal scores,
other users' records/feedback, or credentials are exported.

POST /v1/me/exports returns a durable job (202). GET /v1/me/exports lists jobs;
GET /v1/me/exports/{id} provides status and completion notification state.
A completed job includes download_url. POST .../{id}/retry retries only failed
jobs (no extra daily charge; max attempts export.max_attempts, default 3).
A broker outage leaves the committed pending job for periodic recovery.
Repeated delivery is idempotent; failed archives are removed, failure reasons
contain no personal data. Expired files are automatically deleted by a minute
scheduled task; download is rejected at expiry even before cleanup runs.

Deployment: API and workers need the same private persistent GRAMTREE_EXPORT_DIR
(default .data/exports), outside any static/public web root. Start the existing
Celery worker and beat. Operator recovery: python -m gramtree.exports run;
cleanup: python -m gramtree.exports cleanup. --as-of accepts a timezone-aware
ISO timestamp for deterministic operator tests. Cleanup also removes orphaned
archives and abandoned temporary files. Never publish this private directory.
""".strip()


@router.get("/data-export-format", response_class=HTMLResponse)
def data_export_format() -> HTMLResponse:
    limitations = "".join(
        f"<li><b>{escape(key)}</b>: {escape(reason)}</li>"
        for key, reason in UNAVAILABLE_ENTITIES.items()
    )
    return HTMLResponse(
        "<!doctype html><html lang='en'><head><meta charset='utf-8'>"
        "<meta name='viewport' content='width=device-width,initial-scale=1'>"
        "<title>GramTree Export Format</title><style>body{max-width:52rem;margin:2rem auto;"
        "padding-inline:16px;font:16px/1.7 system-ui;background:#F7F4EE;color:#1B1813}"
        "pre{white-space:pre-wrap;overflow-wrap:anywhere}li{margin-block:1em}</style></head><body>"
        "<h1>GramTree JSON export format</h1><p>Version 1 · Supported server entities only</p>"
        f"<pre>{escape(FORMAT_DESCRIPTION)}</pre>"
        f"<h2>Explicit limitations</h2><ul>{limitations}</ul>"
        "</body></html>",
        headers={"Cache-Control": "public, max-age=3600"},
    )
