#!/usr/bin/env bash
# Loads `.env.asc.local` then runs Fastlane (TestFlight upload: docs/AppStoreConnectUpload.md).
# Beispiele: ./scripts/asc.sh ios asc_verify | asc_ship_testflight | asc_build_appstore_ipa | asc_upload_ipa
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -f "$ROOT/.env.asc.local" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT/.env.asc.local"
fi

exec bundle exec fastlane "$@"
