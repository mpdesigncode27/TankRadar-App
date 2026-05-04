#!/usr/bin/env bash
# Baut, installiert und startet TankRadar im Simulator, wartet kurz, dann AXe-Batch (Smoke/UI-Hilfe).
# Umgebung: SIMULATOR_NAME, AXE_LAUNCH_WAIT_SECONDS (Standard 4), AXE_STEPS_FILE, AXE_VERBOSE=1
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

"${ROOT}/scripts/build-and-run-simulator.sh"

WAIT="${AXE_LAUNCH_WAIT_SECONDS:-4}"
echo "TankRadar: Warte ${WAIT}s auf UI …"
sleep "${WAIT}"

AXE_ARGS=()
if [[ "${AXE_VERBOSE:-0}" == "1" ]]; then
  AXE_ARGS+=(--verbose)
fi

STEPS="${AXE_STEPS_FILE:-${ROOT}/scripts/axe/tankradar-smoke.steps}"
exec "${ROOT}/scripts/run-axe-batch.sh" "${STEPS}" "${AXE_ARGS[@]}"
