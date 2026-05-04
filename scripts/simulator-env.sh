#!/usr/bin/env bash
# Shared simulator helpers for TankRadar shell scripts.
# shellcheck shell=bash

# Resolves the UDID of the first *available* device whose name matches SIMULATOR_NAME.
# Default SIMULATOR_NAME matches scripts/build-and-run-simulator.sh.
tankradar_resolve_simulator_udid() {
  local sim_name="${SIMULATOR_NAME:-iPhone 17}"
  xcrun simctl list devices available 2>/dev/null \
    | grep "${sim_name} (" \
    | head -1 \
    | grep -oE '[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}' \
    | head -1
}
