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

xcrun simctl launch "${UDID}" "${BUNDLE_ID}" "${LAUNCH_ARGS[@]}"

echo "FuelNow: Installiert und gestartet."
