#!/usr/bin/env bash
# Copy the cached Perplexity OEM schedule JSON out of the simulator's
# app container into maestro/results/.
#
# Usage: extract_json.sh <SIM_ID> <BUNDLE_ID> <OUT_PATH>
set -euo pipefail

SIM_ID=${1:?sim id required}
BUNDLE_ID=${2:?bundle id required}
OUT=${3:?out path required}

CONTAINER=$(xcrun simctl get_app_container "$SIM_ID" "$BUNDLE_ID" data)
SRC_DIR="$CONTAINER/Documents/oem_schedules"

if [ ! -d "$SRC_DIR" ]; then
  echo "extract_json: no oem_schedules dir — Perplexity call may have failed" >&2
  exit 0
fi

# Grab the most recently modified JSON (one per run because launch wipes state).
LATEST=$(ls -t "$SRC_DIR"/*.json 2>/dev/null | head -n1 || true)
if [ -z "$LATEST" ]; then
  echo "extract_json: oem_schedules empty" >&2
  exit 0
fi

mkdir -p "$(dirname "$OUT")"
cp "$LATEST" "$OUT"
echo "extract_json: copied $(basename "$LATEST") -> $OUT"
