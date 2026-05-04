#!/usr/bin/env bash
# TAN-72 / Sicherheit: Prüft, dass geheime Key-Dateien nicht versioniert sind.
# Optionaler Spot-Check für CI oder vor PR (kein Ersatz für Secret-Scanning).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  echo "TankRadar: $*" >&2
  exit 1
}

if git ls-files --error-unmatch TankRadar/Support/APIKeys.swift >/dev/null 2>&1; then
  fail "APIKeys.swift ist getrackt — darf nicht ins Repo."
fi

echo "TankRadar: OK — APIKeys.swift ist nicht versioniert."
echo "TankRadar: Optional manuell: git log --all -p -S 'YOUR_KEY_SUBSTRING' | head"
