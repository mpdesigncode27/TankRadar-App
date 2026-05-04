#!/usr/bin/env bash
# Baut, installiert und startet FuelNow im Simulator, wartet kurz, dann AXe-Batch (Smoke/UI-Hilfe).
# Umgebung: SIMULATOR_NAME, AXE_LAUNCH_WAIT_SECONDS (Standard 4), AXE_STEPS_FILE, AXE_VERBOSE=1
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

"${ROOT}/scripts/build-and-run-simulator.sh"

WAIT="${AXE_LAUNCH_WAIT_SECONDS:-4}"
echo "FuelNow: Warte ${WAIT}s auf UI …"
sleep "${WAIT}"

STEPS="${AXE_STEPS_FILE:-${ROOT}/scripts/axe/fuelnow-smoke.steps}"
# Bash 3.2 + set -u: "${array[@]}" on an empty array can error ("unbound variable").
if [[ "${AXE_VERBOSE:-0}" == "1" ]]; then
  exec "${ROOT}/scripts/run-axe-batch.sh" "${STEPS}" --verbose
else
  exec "${ROOT}/scripts/run-axe-batch.sh" "${STEPS}"
fi
