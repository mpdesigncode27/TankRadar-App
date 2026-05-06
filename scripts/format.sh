#!/usr/bin/env bash
# scripts/format.sh — FuelNow SwiftFormat runner (TAN-63)
#
# Behaviour:
#   - With no args: rewrites in place using `.swiftformat`.
#   - "--lint":     dry-run check only; exits non-zero on diffs (CI / pre-commit mode).
#
# Style guide: docs/STYLE.md
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v swiftformat >/dev/null 2>&1; then
  echo "❌ SwiftFormat not installed. Run: brew bundle --file=Brewfile" >&2
  exit 127
fi

paths=(FuelNow FuelNowTests FuelNowUITests)

# Keep the SwiftFormat cache in-tree so sandboxed agent runs and CI workers
# without ~/Library/Caches access still get incremental formatting.
cache_dir=".build/swiftformat-cache"
mkdir -p "$cache_dir"

# SwiftFormat parses path-flag adjacency strictly — paths must come before
# `--lint`/`--quiet` or it tries to consume them as flag values.
mode="${1:-}"
case "$mode" in
  --lint)
    exec swiftformat "${paths[@]}" --cache "$cache_dir/cache" --lint --quiet
    ;;
  "")
    exec swiftformat "${paths[@]}" --cache "$cache_dir/cache" --quiet
    ;;
  *)
    echo "Usage: $0 [--lint]" >&2
    exit 64
    ;;
esac
