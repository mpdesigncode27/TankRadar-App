#!/usr/bin/env bash
# Baut FuelNow für den iOS-Simulator, installiert die App auf dem gewählten Simulator und startet sie.
# Überlappende Aufrufe (z. B. viele Saves) serialisieren sich per flock.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=simulator-env.sh
source "${ROOT}/scripts/simulator-env.sh"

SCHEME="${SCHEME:-FuelNow}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17}"
BUNDLE_ID="${BUNDLE_ID:-com.vibecoding.fuelnow}"
DERIVED="${DERIVED_DATA_PATH:-$ROOT/.derived-data-ios}"

mkdir -p "$DERIVED"
LOCK_DIR="$DERIVED/.build-run-lock-dir"
wait_for_build_lock() {
  local attempts=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    sleep 0.25
    attempts=$((attempts + 1))
    if [[ $attempts -gt 600 ]]; then
      echo "FuelNow: Build-Warteschlange-Timeout." >&2
      exit 1
    fi
  done
  trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
}
wait_for_build_lock

UDID="$(fuelnow_resolve_simulator_udid)"
if [[ -z "${UDID}" ]]; then
  echo "FuelNow: Kein Simulator „${SIMULATOR_NAME}“ gefunden. SIMULATOR_NAME anpassen oder Gerät in Xcode installieren." >&2
  exit 1
fi

if ! xcrun simctl list devices booted 2>/dev/null | grep -q "${UDID}"; then
  xcrun simctl boot "${UDID}" 2>/dev/null || true
fi
open -a Simulator 2>/dev/null || true

echo "FuelNow: Build (${SCHEME}) → Simulator ${SIMULATOR_NAME} (${UDID}) …"

xcodebuild \
  -scheme "${SCHEME}" \
  -destination "platform=iOS Simulator,id=${UDID}" \
  -derivedDataPath "${DERIVED}" \
  -quiet \
  build

APP="${DERIVED}/Build/Products/Debug-iphonesimulator/FuelNow.app"
if [[ ! -d "${APP}" ]]; then
  echo "FuelNow: Build-Produkt fehlt: ${APP}" >&2
  exit 1
fi

xcrun simctl install "${UDID}" "${APP}"

# TAN-90: Mit FUELNOW_DEMO_PLUS=1 startet die App im DEBUG-Build mit aktivem Plus
# (kein echter Kauf nötig). Wirkt nur in Debug-Builds; Release ignoriert das Argument.
LAUNCH_ARGS=()
if [[ "${FUELNOW_DEMO_PLUS:-0}" == "1" ]]; then
  LAUNCH_ARGS+=("--mock-plus-subscriber")
  echo "FuelNow: Demo-Plus aktiv (--mock-plus-subscriber)."
fi

# TAN-91: Live-Tankerkönig ist Default. Damit der Simulator beim Skript-Start an einen
# echten Key kommt, wird ~/.fuelnow/tankerkoenig-api-key gelesen und über die
# `SIMCTL_CHILD_*`-Konvention an `xcrun simctl launch` weitergereicht (kein Klartext-Key
# im Skript). Ohne Key-Datei startet die App trotzdem — sie zeigt dann den Offline-Splash
# bei fehlender Verbindung bzw. den bestehenden Error-Alert (missingAPIKey).
TANKERKOENIG_KEY_FILE="${TANKERKOENIG_KEY_FILE:-${HOME}/.fuelnow/tankerkoenig-api-key}"
if [[ -f "${TANKERKOENIG_KEY_FILE}" ]]; then
  TANKERKOENIG_KEY="$(tr -d '[:space:]' < "${TANKERKOENIG_KEY_FILE}")"
  if [[ -n "${TANKERKOENIG_KEY}" ]]; then
    export SIMCTL_CHILD_TANKERKOENIG_API_KEY="${TANKERKOENIG_KEY}"
    echo "FuelNow: Tankerkönig-Key aus ${TANKERKOENIG_KEY_FILE} übernommen."
  else
    echo "FuelNow: ${TANKERKOENIG_KEY_FILE} ist leer — App startet ohne Live-Key (Offline-Splash bei fehlender Verbindung, Error-Alert ohne Key)." >&2
  fi
else
  echo "FuelNow: Kein Tankerkönig-Key unter ${TANKERKOENIG_KEY_FILE} — App startet ohne Live-Key." >&2
  echo "         Tipp: 'mkdir -p ${HOME}/.fuelnow && echo <KEY> > ${TANKERKOENIG_KEY_FILE}' (siehe TAN-72/TAN-91)." >&2
fi

# Optional: lokale FUELNOW_USE_MOCK_STATIONS=1 (z. B. UI-Tests), wird an die App gereicht.
if [[ "${FUELNOW_USE_MOCK_STATIONS:-0}" == "1" ]]; then
  export SIMCTL_CHILD_FUELNOW_USE_MOCK_STATIONS=1
  echo "FuelNow: QA-Mock erzwungen (FUELNOW_USE_MOCK_STATIONS=1)."
fi

xcrun simctl launch "${UDID}" "${BUNDLE_ID}" ${LAUNCH_ARGS[@]+"${LAUNCH_ARGS[@]}"}

echo "FuelNow: Installiert und gestartet."
