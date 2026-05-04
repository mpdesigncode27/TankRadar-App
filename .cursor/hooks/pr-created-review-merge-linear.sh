#!/usr/bin/env bash
# Runs after `gh pr create` (Cursor afterShellExecution). Heuristic review + merge + Linear Done.
#
# Limits:
# - Nur wenn die Shell `gh pr create` ausgeführt hat — nicht bei PRs nur in der GitHub-UI.
# - Sandbox-Läufe: übersprungen (gh meist ohne Auth).
# - Draft-PRs werden nicht gemerged (Ausnahme: TANKRADAR_MERGE_DRAFT_PRS=1).
#
# Env:
#   LINEAR_API_KEY / LINEAR_KEY   Linear API Key für issueUpdate → Done (nach erfolgreichem Merge).
#   TANKRADAR_PR_HOOK_DISABLE=1   Hook komplett aus.
#   TANKRADAR_PR_HOOK_DRY_RUN=1   Nur Log, kein Merge / kein Linear.
#   TANKRADAR_MERGE_DRAFT_PRS=1   Draft-PRs dürfen gemerged werden.
#   CURSOR_HOOK_LOG_DIR           Optional: Log-Verzeichnis (Default: $TMPDIR/cursor-hooks).

set -euo pipefail

LOG_DIR="${CURSOR_HOOK_LOG_DIR:-${TMPDIR:-/tmp}/cursor-hooks}"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/tankradar-pr-hook.log"

log() {
  printf '%s %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$*" | tee -a "$LOG_FILE" >&2
}

emit_empty_json() {
  printf '{}'
}

if [[ "${TANKRADAR_PR_HOOK_DISABLE:-}" == "1" ]]; then
  log "hook disabled (TANKRADAR_PR_HOOK_DISABLE=1)"
  emit_empty_json
  exit 0
fi

INPUT="$(cat)"
export HOOK_INPUT_JSON="$INPUT"

python3 <<'PY'
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from typing import Any, Optional


def log(msg: str) -> None:
    print(msg, file=sys.stderr)


def emit_done() -> None:
    print("{}")


def linear_graphql(api_key: str, query: str, variables: Optional[dict[str, Any]] = None) -> dict[str, Any]:
    body = json.dumps({"query": query, "variables": variables or {}}).encode()
    req = urllib.request.Request(
        "https://api.linear.app/graphql",
        data=body,
        headers={
            "Authorization": api_key,
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.loads(resp.read().decode())


try:
    data = json.loads(os.environ.get("HOOK_INPUT_JSON") or "{}")
except json.JSONDecodeError as e:
    log(f"pr-hook: invalid stdin JSON: {e}")
    emit_done()
    sys.exit(0)

cmd = data.get("command") or ""
out = data.get("output") or ""
sandbox = data.get("sandbox")

if sandbox:
    log("pr-hook: sandbox run — skipping merge/Linear.")
    emit_done()
    sys.exit(0)

if "gh pr create" not in cmd:
    emit_done()
    sys.exit(0)

m = re.search(r"https://github\.com/[^/\s]+/[^/\s]+/pull/\d+", out)
if not m:
    log("pr-hook: no PR URL in gh output — skipping.")
    emit_done()
    sys.exit(0)

pr_url = m.group(0)
dry = os.environ.get("TANKRADAR_PR_HOOK_DRY_RUN") == "1"
merge_drafts = os.environ.get("TANKRADAR_MERGE_DRAFT_PRS") == "1"

log(f"pr-hook: detected PR {pr_url}")

raw = subprocess.run(
    ["gh", "pr", "view", pr_url, "--json", "isDraft,mergeable,mergeStateStatus,statusCheckRollup,headRefName"],
    capture_output=True,
    text=True,
)
if raw.returncode != 0:
    log(f"pr-hook: gh pr view failed: {raw.stderr.strip()}")
    emit_done()
    sys.exit(0)

try:
    pr = json.loads(raw.stdout)
except json.JSONDecodeError:
    log("pr-hook: could not parse gh pr view JSON")
    emit_done()
    sys.exit(0)

head_ref = pr.get("headRefName") or ""
id_match = re.search(r"(TAN-\d+)", head_ref, re.I)
linear_id = id_match.group(1).upper() if id_match else None

checks = pr.get("statusCheckRollup") or []
bad = [
    c
    for c in checks
    if isinstance(c, dict) and c.get("conclusion") in ("FAILURE", "CANCELLED", "TIMED_OUT", "ACTION_REQUIRED")
]
incomplete_status = {"IN_PROGRESS", "QUEUED", "WAITING", "PENDING", "REQUESTED", "RE_REQUESTED"}
pending = [c for c in checks if isinstance(c, dict) and c.get("status") in incomplete_status]

is_draft = bool(pr.get("isDraft"))
mergeable = pr.get("mergeable")
merge_state = pr.get("mergeStateStatus")

log(
    f"pr-hook: review — draft={is_draft} mergeable={mergeable} mergeState={merge_state} "
    f"checks_fail={len(bad)} checks_pending={len(pending)} linear={linear_id or '—'}"
)

concerns: list[str] = []
if is_draft and not merge_drafts:
    concerns.append("PR ist Draft — kein Auto-Merge (TANKRADAR_MERGE_DRAFT_PRS=1 zum Erlauben).")
if mergeable == "CONFLICTING":
    concerns.append("Merge-Konflikte (mergeable=CONFLICTING).")
if bad:
    concerns.append(f"{len(bad)} Check(s) fehlgeschlagen.")
if merge_state in ("DIRTY", "BLOCKED", "BEHIND"):
    concerns.append(f"mergeStateStatus={merge_state}.")

if concerns:
    log("pr-hook: Bedenken — kein Merge:\n  - " + "\n  - ".join(concerns))
    emit_done()
    sys.exit(0)

log("pr-hook: keine Blocker aus Draft/Konflikt/Checks — Merge auslösen.")

if dry:
    log("pr-hook: DRY_RUN — überspringe gh pr merge und Linear.")
    emit_done()
    sys.exit(0)

merge_cmd = ["gh", "pr", "merge", pr_url, "--merge", "--delete-branch"]
if pending:
    merge_cmd.append("--auto")
    log("pr-hook: Checks noch laufend — gh pr merge --auto (wartet auf Branch-Regeln).")

gm = subprocess.run(merge_cmd, capture_output=True, text=True)
if gm.returncode != 0:
    log(f"pr-hook: gh pr merge failed: {gm.stderr.strip() or gm.stdout.strip()}")
    emit_done()
    sys.exit(0)

if gm.stdout.strip():
    log(f"pr-hook: gh merge stdout: {gm.stdout.strip()[:500]}")

# Warten bis MERGED (bei --auto oft verzögert)
merged = False
for attempt in range(90):
    vr = subprocess.run(
        ["gh", "pr", "view", pr_url, "--json", "state"],
        capture_output=True,
        text=True,
    )
    if vr.returncode != 0:
        log(f"pr-hook: gh pr view state failed (Versuch {attempt + 1}): {vr.stderr.strip()}")
        time.sleep(10)
        continue
    try:
        st = json.loads(vr.stdout).get("state")
    except json.JSONDecodeError:
        time.sleep(10)
        continue
    if st == "MERGED":
        merged = True
        log("pr-hook: PR ist MERGED.")
        break
    time.sleep(10)

if not merged:
    log("pr-hook: PR nach 900s noch nicht MERGED — Linear wird nicht auf Done gesetzt.")
    emit_done()
    sys.exit(0)

linear_key = os.environ.get("LINEAR_API_KEY") or os.environ.get("LINEAR_KEY")
if not linear_key:
    log("pr-hook: LINEAR_API_KEY fehlt — Ticket nicht auf Done gesetzt.")
    emit_done()
    sys.exit(0)

if not linear_id:
    log("pr-hook: kein TAN-XX im Branch-Namen — Linear übersprungen.")
    emit_done()
    sys.exit(0)

try:
    search = linear_graphql(
        linear_key,
        """
        query IssueSearch($q: String!) {
          issueSearch(query: $q, first: 15) {
            nodes {
              id
              identifier
              team { id }
            }
          }
        }
        """,
        {"q": linear_id},
    )
except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, json.JSONDecodeError, OSError) as e:
    log(f"pr-hook: Linear API Fehler (issueSearch): {e}")
    emit_done()
    sys.exit(0)

if search.get("errors"):
    log(f"pr-hook: Linear GraphQL errors (issueSearch): {search.get('errors')}")
    emit_done()
    sys.exit(0)

nodes = (((search.get("data") or {}).get("issueSearch") or {}).get("nodes")) or []
issue_node = next((n for n in nodes if (n or {}).get("identifier") == linear_id), None)
if not issue_node:
    log(f"pr-hook: Linear Issue {linear_id} nicht in issueSearch.")
    emit_done()
    sys.exit(0)

issue_uuid = issue_node["id"]
team_id = ((issue_node.get("team") or {}).get("id"))
if not team_id:
    log("pr-hook: Linear Issue ohne team.id.")
    emit_done()
    sys.exit(0)

try:
    team_payload = linear_graphql(
        linear_key,
        """
        query TeamStates($id: String!) {
          team(id: $id) {
            states {
              nodes {
                id
                type
                name
              }
            }
          }
        }
        """,
        {"id": team_id},
    )
except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, json.JSONDecodeError, OSError) as e:
    log(f"pr-hook: Linear API Fehler (team): {e}")
    emit_done()
    sys.exit(0)

states = (((team_payload.get("data") or {}).get("team") or {}).get("states") or {}).get("nodes") or []
done_state = next((s for s in states if (s or {}).get("type") == "completed"), None)
if not done_state:
    log("pr-hook: Kein Workflow-State type=completed für das Team.")
    emit_done()
    sys.exit(0)

try:
    upd = linear_graphql(
        linear_key,
        """
        mutation IssueDone($id: String!, $stateId: String!) {
          issueUpdate(id: $id, input: { stateId: $stateId }) {
            success
            issue {
              identifier
              state { name }
            }
          }
        }
        """,
        {"id": issue_uuid, "stateId": done_state["id"]},
    )
except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, json.JSONDecodeError, OSError) as e:
    log(f"pr-hook: Linear issueUpdate Fehler: {e}")
    emit_done()
    sys.exit(0)

payload = (upd.get("data") or {}).get("issueUpdate") or {}
if payload.get("success"):
    iss = payload.get("issue") or {}
    log(f"pr-hook: Linear {iss.get('identifier')} → „{((iss.get('state') or {}).get('name'))}“.")
else:
    log(f"pr-hook: Linear issueUpdate nicht erfolgreich: {upd.get('errors')}")

emit_done()
PY
