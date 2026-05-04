#!/usr/bin/env bash
# Bei Änderungen unter FuelNow/ oder am Xcode-Projekt: Build + Install + Launch im Simulator.
# Voraussetzung: brew install fswatch
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v fswatch >/dev/null 2>&1; then
  echo "Bitte fswatch installieren: brew install fswatch" >&2
  exit 1
fi

echo "FuelNow: Überwache Änderungen (fswatch, Latenz 2s). Beenden mit Ctrl+C."
# -l 2: Ereignisse innerhalb 2s zusammenfassen (weniger parallele Builds)
fswatch -l 2 -o \
  "${ROOT}/FuelNow" \
  "${ROOT}/FuelNow.xcodeproj" \
  | while read -r _; do
    "${ROOT}/scripts/build-and-run-simulator.sh" || true
  done
