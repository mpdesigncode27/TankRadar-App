#!/usr/bin/env bash
# Wrapper: loads .env.asc.local then runs fastlane (see docs/AppStoreConnectUpload.md).
# Examples: ./scripts/asc.sh ios asc_verify | asc_build_appstore_ipa | asc_upload_ipa | asc_ship_testflight
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -f "$ROOT/.env.asc.local" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT/.env.asc.local"
fi

exec bundle exec fastlane "$@"
