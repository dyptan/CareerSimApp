#!/bin/sh
# Builds the headless balance simulator from the real model layer and runs it.
#
#   Tools/BalanceSim/run.sh [simulator args...]
#
# The binary goes to $BALANCESIM_BIN, else $TMPDIR/balancesim — never into the
# repo. Arguments are passed straight to the simulator (see README.md), e.g.
#   Tools/BalanceSim/run.sh --lives 300 --out /tmp/baseline.md
set -e

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BIN="${BALANCESIM_BIN:-${TMPDIR:-/tmp}/balancesim}"

cd "$ROOT"
echo "Building $BIN ..." >&2
# shellcheck disable=SC2046
swiftc -O -o "$BIN" \
    $(ls Main/Models/*.swift | grep -v GameCenterManager) \
    Main/Resources/JobCatalog.swift \
    Tools/BalanceSim/*.swift
echo "Running ..." >&2
exec "$BIN" "$@"
