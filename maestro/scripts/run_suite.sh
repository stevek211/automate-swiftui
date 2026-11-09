#!/usr/bin/env bash
# AutoMate Service Plan screenshot harness.
#
# Environment knobs:
#   VINS_ONLY=1        run only the CSV VIN pass
#   MMY_ONLY=1         run only the randomized make/model/year pass
#   MMY_COUNT=10       number of randomized vehicles (default 10)
#   VINS_CSV=path      override default CSV path
#   BUNDLE_ID=...      override bundle id (default: steve.kurien.claude-automate)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

BUNDLE_ID=${BUNDLE_ID:-steve.kurien.claude-automate}
VINS_CSV=${VINS_CSV:-maestro/data/vins.csv}
MMY_COUNT=${MMY_COUNT:-10}
TS=$(date +%s)

SIM_ID=$(xcrun simctl list devices booted | awk -F'[()]' '/Booted/ {print $2; exit}')
if [ -z "${SIM_ID:-}" ]; then
  echo "run_suite: no booted iOS Simulator — boot one from Xcode first" >&2
  exit 1
fi
echo "run_suite: using simulator $SIM_ID, bundle $BUNDLE_ID"

mkdir -p maestro/screenshots maestro/results

sanitize() { echo "$1" | tr -c 'A-Za-z0-9._-' '_'; }

pick_one() {
  # Pick a random element from the given list (space-separated, each item in
  # single quotes so we can include spaces/slashes). Usage: pick_one "'a' 'b'"
  local choices=$1
  eval "set -- $choices"
  local i=$(( (RANDOM % $#) + 1 ))
  eval "echo \"\${$i}\""
}

USAGE_CHOICES="'Daily commuter' 'Family car' 'Weekend / road trips' 'Work vehicle' 'Occasional use'"
CONDITION_CHOICES="'City / stop-and-go' 'Highway / long stretches' 'Rain / wet roads' 'Snow / ice in winter' 'Extreme heat' 'Dirt / gravel / rough roads'"
ANNUAL_MILES_CHOICES="'Under 5,000' '5,000–10,000' '10,000–15,000'"

run_one() {
  local mode=$1 slug=$2
  slug=$(sanitize "$slug")

  export EMAIL="automate+${TS}_${slug}@test.com"
  export PASSWORD="Test${TS}!aA"
  export FIRST="Test"
  export LAST="User"
  export MODE=$mode
  export USAGE=$(pick_one "$USAGE_CHOICES")
  export CONDITION=$(pick_one "$CONDITION_CHOICES")
  export ANNUAL_MILES=$(pick_one "$ANNUAL_MILES_CHOICES")
  export SCREENSHOT_PATH="${REPO_ROOT}/maestro/screenshots/${TS}_${slug}.png"

  echo ""
  echo "================================================================"
  echo "run_suite: [$mode] $slug"
  echo "  EMAIL=$EMAIL  MILEAGE=${MILEAGE:-?}"
  if [ "$mode" = "vin" ]; then
    echo "  VIN=$VIN"
  else
    echo "  YEAR=$YEAR MAKE=$MAKE MODEL=$MODEL"
  fi
  echo "  USAGE='$USAGE'  CONDITION='$CONDITION'  ANNUAL_MILES='$ANNUAL_MILES'"
  echo "================================================================"

  if maestro test \
      -e "MODE=$MODE" \
      -e "EMAIL=$EMAIL" \
      -e "PASSWORD=$PASSWORD" \
      -e "FIRST=$FIRST" \
      -e "LAST=$LAST" \
      -e "MILEAGE=$MILEAGE" \
      -e "VIN=${VIN:-}" \
      -e "YEAR=${YEAR:-}" \
      -e "MAKE=${MAKE:-}" \
      -e "MODEL=${MODEL:-}" \
      -e "USAGE=$USAGE" \
      -e "CONDITION=$CONDITION" \
      -e "ANNUAL_MILES=$ANNUAL_MILES" \
      -e "SCREENSHOT_PATH=$SCREENSHOT_PATH" \
      maestro/flows/main.yaml; then
    ./maestro/scripts/extract_json.sh "$SIM_ID" "$BUNDLE_ID" \
      "maestro/results/${TS}_${slug}.json" || true
  else
    echo "run_suite: flow failed for $slug — continuing" >&2
  fi
}

# --- Mode 1: VINs from CSV -----------------------------------------------
if [ -z "${MMY_ONLY:-}" ]; then
  if [ ! -f "$VINS_CSV" ]; then
    echo "run_suite: $VINS_CSV not found — skipping VIN pass" >&2
  else
    tail -n +2 "$VINS_CSV" | while IFS=, read -r vin _rest; do
      vin=$(echo "$vin" | tr -d '[:space:]"')
      [ -z "$vin" ] && continue
      export VIN=$vin
      export MILEAGE=$(( (RANDOM * 32768 + RANDOM) % 100000 + 1 ))
      run_one vin "vin_${vin}_${MILEAGE}mi"
    done
  fi
fi

# --- Mode 2: randomized make/model/year ---------------------------------
if [ -z "${VINS_ONLY:-}" ]; then
  for i in $(seq 1 "$MMY_COUNT"); do
    eval "$(./maestro/scripts/gen_mmy.sh)"
    run_one mmy "mmy_${YEAR}_${MAKE}_${MODEL}_${MILEAGE}mi"
  done
fi

echo ""
echo "run_suite: done. Outputs:"
echo "  screenshots -> maestro/screenshots/${TS}_*.png"
echo "  json        -> maestro/results/${TS}_*.json"
