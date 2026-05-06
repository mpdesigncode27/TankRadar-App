#!/usr/bin/env bash
# scripts/verify-ios-build.sh — FuelNow App-Target: Build ohne Compiler-Warnings.
#
# Nutzt SWIFT_TREAT_WARNINGS_AS_ERRORS / GCC_TREAT_WARNINGS_AS_ERRORS auf dem
# Scheme-„build“ (primär das FuelNow-App-Target). Absichtlich kein
# „build-for-testing“: Apples StoreKitTest-SDK wirft unter denselben Flags
# Deprecation-Warnings in System-Headern, die wir nicht beheben können.
#
# Siehe docs/STYLE.md und .cursor/rules/ios-xcode-zero-warnings-ci.mdc
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SCHEME="${VERIFY_IOS_SCHEME:-FuelNow}"
DESTINATION="${VERIFY_IOS_DESTINATION:-generic/platform=iOS Simulator}"
DERIVED="${VERIFY_IOS_DERIVED_DATA:-$ROOT/.derived-data-ios-verify}"

mkdir -p "$DERIVED"

echo "FuelNow: xcodebuild build (Swift/Clang warnings → errors) — scheme=${SCHEME}, destination=${DESTINATION}"

xcodebuild \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED" \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
  GCC_TREAT_WARNINGS_AS_ERRORS=YES \
  build

echo "FuelNow: Xcode-Build ohne Warnings (App-Target) — OK."
