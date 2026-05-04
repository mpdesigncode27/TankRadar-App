#!/usr/bin/env bash
# TAN-72 / Sicherheit: Prüft, dass geheime Key-Dateien nicht versioniert sind.
# Optionaler Spot-Check für CI oder vor PR (kein Ersatz für Secret-Scanning).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  echo "FuelNow: $*" >&2
  exit 1
}

if git ls-files --error-unmatch FuelNow/Support/APIKeys.swift >/dev/null 2>&1; then
  fail "APIKeys.swift ist getrackt — darf nicht ins Repo."
fi

echo "FuelNow: OK — APIKeys.swift ist nicht versioniert."
echo "FuelNow: Optional manuell: git log --all -p -S 'YOUR_KEY_SUBSTRING' | head"
