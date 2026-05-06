#!/usr/bin/env bash
# scripts/lint.sh — FuelNow SwiftLint runner (TAN-63)
#
# Behaviour:
#   - With no args: runs SwiftLint over the configured paths and exits non-zero on errors.
#   - "--strict":   treats warnings as errors (SwiftLint only).
#   - "--ci":       Merge-Gate: SwiftLint strict + SwiftFormat --lint + Xcode „build“ ohne
#                   Compiler-Warnings (`scripts/verify-ios-build.sh`).
#   - "--fix":      applies `--fix` for autocorrectable rules, then re-runs the lint pass.
#
# Style guide: docs/STYLE.md
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
cd "$script_dir/.."

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "❌ SwiftLint not installed. Run: brew bundle --file=Brewfile" >&2
  exit 127
fi

# Keep the SwiftLint cache in-tree so sandboxed agent runs and CI workers
# without ~/Library/Caches access still get incremental linting.
cache_dir=".build/swiftlint-cache"
mkdir -p "$cache_dir"

mode="${1:-}"
case "$mode" in
  --strict)
    exec swiftlint lint --strict --quiet --cache-path "$cache_dir"
    ;;
  --ci)
    swiftlint lint --strict --quiet --cache-path "$cache_dir"
    "$script_dir/format.sh" --lint
    "$script_dir/verify-ios-build.sh"
    ;;
  --fix)
    swiftlint lint --fix --quiet --cache-path "$cache_dir"
    exec swiftlint lint --quiet --cache-path "$cache_dir"
    ;;
  "" | --quiet)
    exec swiftlint lint --quiet --cache-path "$cache_dir"
    ;;
  *)
    echo "Usage: $0 [--strict | --ci | --fix]" >&2
    exit 64
    ;;
esac
