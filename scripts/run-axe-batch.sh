#!/usr/bin/env bash
# Führt eine AXe-Batch-Datei auf dem gewählten iOS-Simulator aus.
# Voraussetzung: Simulator booted, App ggf. bereits gestartet (siehe build-run-and-axe.sh).
# Install: https://www.axe-cli.com/ — brew tap cameroncooke/axe && brew install axe
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=simulator-env.sh
source "${ROOT}/scripts/simulator-env.sh"

if ! command -v axe >/dev/null 2>&1; then
  echo "TankRadar: AXe CLI fehlt. Install: brew tap cameroncooke/axe && brew install axe" >&2
  echo "TankRadar: Siehe https://www.axe-cli.com/" >&2
  exit 1
fi

DEFAULT_STEPS="${ROOT}/scripts/axe/tankradar-smoke.steps"
STEPS="${1:-$DEFAULT_STEPS}"
if [[ $# -gt 0 ]]; then
  shift
fi

if [[ ! -f "${STEPS}" ]]; then
  echo "TankRadar: Batch-Datei fehlt: ${STEPS}" >&2
  exit 1
fi

UDID="$(tankradar_resolve_simulator_udid)"
if [[ -z "${UDID}" ]]; then
  echo "TankRadar: Kein Simulator „${SIMULATOR_NAME:-iPhone 17}“ gefunden. SIMULATOR_NAME anpassen." >&2
  exit 1
fi

mkdir -p "${ROOT}/scripts/axe/output"

echo "TankRadar: axe batch --file ${STEPS} --udid ${UDID}"
exec axe batch --file "${STEPS}" --udid "${UDID}" "$@"
