
#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

TRIALS="${TRIALS:-10}"
PACKAGE="${PACKAGE:-odd_or_even}"
REGISTRY_URL="${REGISTRY_URL:-http://verdaccio:4873/}"

mkdir -p results

# Build every image before starting any measured trial.
docker compose build npm115 npm116 npm121

for service in npm115 npm116 npm121; do
  case "$service" in
    npm115) expected="11.15.0" ;;
    npm116) expected="11.16.0" ;;
    npm121) expected="12.1.0" ;;
  esac

  for trial in $(seq 1 "$TRIALS"); do
    run_id="${service}-trial-$(printf '%03d' "$trial")"
    out="results/$run_id"
    mkdir -p "$out"

    echo "Running $run_id"

    # Record the container and host metadata outside the timed command.
    {
      echo "run_id=$run_id"
      echo "service=$service"
      echo "expected_npm=$expected"
      echo "package=$PACKAGE"
      echo "registry=$REGISTRY_URL"
      echo "trial=$trial"
      date -u +"started_utc=%Y-%m-%dT%H:%M:%SZ"
      docker image inspect "npm-paper:$expected" \
        --format 'image_id={{.Id}}'
    } > "$out/metadata.txt"

    # Each run starts from an empty project and npm cache.
    # Only the npm install command is timed.
    docker compose run --rm --no-deps \
      -v "$PWD/results:/results" \
      -e EXPECTED_NPM="$expected" \
      -e PACKAGE="$PACKAGE" \
      -e REGISTRY_URL="$REGISTRY_URL" \
      -e RUN_ID="$run_id" \
      -e OUT_DIR="/results/$run_id" \
      "$service" sh -lc '
        set -eu

        test "$(npm --version)" = "$EXPECTED_NPM"

        mkdir -p "/tmp/npm-trial-$RUN_ID/project" \
                 "/tmp/npm-trial-$RUN_ID/cache"

        cd "/tmp/npm-trial-$RUN_ID/project"

        # Prepare the project before timing the package installation.
        npm init -y > /dev/null

        if npm install-scripts --help > /dev/null 2>&1; then
          node -e "const fs = require(\"node:fs\"); const path = \"package.json\"; const manifest = JSON.parse(fs.readFileSync(path, \"utf8\")); fs.writeFileSync(path, JSON.stringify(manifest, null, 2) + String.fromCharCode(10));"
        fi

        printf "node=%s\nnpm=%s\n" \
          "$(node --version)" "$(npm --version)" \
          > "$OUT_DIR/runtime.txt"

        npm config get registry >> "$OUT_DIR/runtime.txt"

        # Use the same registry, with an isolated cache for this trial.
        set +e
        /usr/bin/time -f \
          "elapsed_seconds=%e\nuser_seconds=%U\nsystem_seconds=%S\nmax_rss_kb=%M" \
          -o "$OUT_DIR/time.txt" \
          npm install "$PACKAGE" \
            --registry="$REGISTRY_URL" \
            --cache="/tmp/npm-trial-$RUN_ID/cache" \
            --foreground-scripts \
            --loglevel=verbose \
            --no-audit \
            --no-fund \
          > "$OUT_DIR/install.log" 2>&1
        rc=$?
        set -e

        echo "$rc" > "$OUT_DIR/exit-code.txt"

        # Preserve the result even if installation failed.
        npm ls --all --json \
          > "$OUT_DIR/dependency-tree.json" 2>&1 || true

        if [ -f package-lock.json ]; then
          cp package-lock.json "$OUT_DIR/package-lock.json"
        fi

        exit "$rc"
      ' || {
        echo "FAILED: $run_id (see $out/install.log)"
        # Continue so that all npm versions and trials are attempted.
      }

    date -u +"finished_utc=%Y-%m-%dT%H:%M:%SZ" \
      >> "$out/metadata.txt"
  done
done

echo "Finished. Results are in results/."
