#!/usr/bin/env bash
# Emit `export` statements for a random YEAR, MAKE, MODEL, MILEAGE.
# Usage: eval "$(./maestro/scripts/gen_mmy.sh)"
set -euo pipefail

DATA=${MMY_DATA:-maestro/data/makes_models.json}

YEAR=$(( (RANDOM % 27) + 2000 ))    # 2000..2026
MILEAGE=$(( (RANDOM * 32768 + RANDOM) % 100000 + 1 ))   # 1..100000

# Pull a random make, then a random model for that make, via python.
read -r MAKE MODEL < <(python3 - "$DATA" <<'PY'
import json, random, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
make = random.choice(list(data.keys()))
model = random.choice(data[make])
print(make, model)
PY
)

# Escape spaces for env var export.
printf 'export YEAR=%q\n' "$YEAR"
printf 'export MAKE=%q\n' "$MAKE"
printf 'export MODEL=%q\n' "$MODEL"
printf 'export MILEAGE=%q\n' "$MILEAGE"
