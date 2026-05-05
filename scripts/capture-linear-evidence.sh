#!/usr/bin/env bash
# Linear-Nachweis: Build + Simulator + AXe-Batch + PNG unter .linear-evidence/
#
# Nutzung:
#   ./scripts/capture-linear-evidence.sh TAN-XX-kurz-slug
#   ./scripts/capture-linear-evidence.sh TAN-XX-kurz-slug --settings-sheet
#
# Zweiter Modus: Abschluss-Screenshot zeigt das geöffnete Einstellungen-Sheet
# (fuelnow-settings-sheet.steps). Standard: Smoke mit Öffnen/Schließen → Karte im PNG.
#
# Weitere Umgebung wie bei build-run-and-axe.sh: SIMULATOR_NAME, AXE_LAUNCH_WAIT_SECONDS, …
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

usage() {
  echo "Nutze: $0 <Dateiname-ohne-.png> [--settings-sheet | --plus-sheet]" >&2
  echo "  Beispiel: $0 TAN-47-settings-after-merge" >&2
  echo "  Slug: nur Buchstaben, Ziffern, Punkt, Unterstrich, Bindestrich." >&2
  exit 1
}

[[ $# -ge 1 ]] || usage
SLUG_RAW="$1"
shift || true

if [[ ! "${SLUG_RAW}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "FuelNow: Ungültiger Slug (erlaubt: A–Z, a–z, 0–9, . _ -): ${SLUG_RAW}" >&2
  exit 1
fi

EVIDENCE_DIR="${ROOT}/.linear-evidence"
mkdir -p "${EVIDENCE_DIR}"

export AXE_SCREENSHOT_PATH="${EVIDENCE_DIR}/${SLUG_RAW}.png"

DEFAULT_STEPS="${ROOT}/scripts/axe/fuelnow-smoke.steps"
export AXE_STEPS_FILE="${DEFAULT_STEPS}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --settings-sheet)
      export AXE_STEPS_FILE="${ROOT}/scripts/axe/fuelnow-settings-sheet.steps"
      ;;
    --plus-sheet)
      export AXE_STEPS_FILE="${ROOT}/scripts/axe/fuelnow-plus-sheet.steps"
      ;;
    --help|-h)
      usage
      ;;
    *)
      echo "FuelNow: Unbekannte Option: $1" >&2
      usage
      ;;
  esac
  shift
done

echo "FuelNow: Linear-Evidence → ${AXE_SCREENSHOT_PATH}"
echo "FuelNow: AXe steps → ${AXE_STEPS_FILE}"

exec "${ROOT}/scripts/build-run-and-axe.sh"
