# AutoMate Maestro Screenshot Harness

Automates sign-up → add-vehicle → Service Plan across many vehicles on an iOS Simulator, capturing a screenshot of the maintenance timeline and archiving the Perplexity OEM-schedule JSON that backed each run.

## Prerequisites

1. `brew install maestro` (or see https://maestro.mobile.dev)
2. Xcode iOS Simulator booted with AutoMate installed and the Perplexity API key configured (the app reads it from `Secrets.swift` at build time).
3. `python3` available on PATH (used by `gen_mmy.sh`).

Boot a simulator from Xcode (Window → Devices and Simulators → pick one → run the app once) before running the suite.

## Layout

```
maestro/
  flows/      # Maestro YAML, one file per phase
  data/       # vins.csv + makes_models.json
  scripts/    # run_suite.sh, gen_mmy.sh, extract_json.sh
  screenshots/  (gitignored)
  results/      (gitignored)
```

## Running

Full suite (all VINs in `data/vins.csv` + 10 random make/model/year vehicles):

```bash
./maestro/scripts/run_suite.sh
```

Knobs:

```bash
VINS_ONLY=1 ./maestro/scripts/run_suite.sh          # VIN pass only
MMY_ONLY=1  ./maestro/scripts/run_suite.sh          # randomized pass only
MMY_COUNT=25 MMY_ONLY=1 ./maestro/scripts/run_suite.sh
VINS_CSV=path/to/other.csv ./maestro/scripts/run_suite.sh
```

Each run produces:

- `maestro/screenshots/{timestamp}_{slug}.png`
- `maestro/results/{timestamp}_{slug}.json` (copied from the app's `Documents/oem_schedules/`)

## Dry-running a single flow

Set env vars by hand, then:

```bash
export MODE=vin VIN=1HGCV1F34LA000001 MILEAGE=52000
export EMAIL="automate+manual@test.com" PASSWORD="Test!123aA" FIRST=Test LAST=User
export SCREENSHOT_PATH="$PWD/maestro/screenshots/manual.png"
maestro test maestro/flows/main.yaml
```

If a selector misses, open `maestro studio` on the running simulator to live-inspect the hierarchy and edit the offending yaml.

## Known fragilities

- Every selector is text-based (the app has no accessibility identifiers). UI copy changes will break flows — fix by updating the matching `text:` value in the relevant yaml.
- The year wheel picker in the make/model/year flow uses `tapOn: "Select ${YEAR}"` as `optional: true`. If the tap misses on your simulator, replace with scripted `swipe` commands tuned for your device size.
- Screenshots are viewport-only. The Service Plan timeline can scroll beyond one screen; for a full-page capture you'd need to stitch multiple screenshots with `scroll` between them.
- Timestamped signups accumulate real Supabase users. If volume grows, add a cleanup script using the Supabase service-role key.
