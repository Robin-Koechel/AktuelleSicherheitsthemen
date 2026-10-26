# npm Lifecycle Script Experiment

This repository is a local experiment comparing dependency installation with npm 11.15.0, npm 11.16.0, and npm 12.1.0. It publishes two sample packages to a local Verdaccio registry, installs `odd_or_even` repeatedly, and records timing, runtime, dependency, and lifecycle-script output for each run.

The lifecycle hooks in `efficient_sum_calculator` are demonstration scripts: they print a banner for `preinstall`, `install`, and `postinstall`. They do not perform the behaviors implied by the package description or script filename. Keep the experiment on the local registry and do not use these packages as production dependencies.

## Repository Layout

- `compose.yaml`: Verdaccio plus one long-running container for each tested npm version.
- `Dockerfile`: Node 24.15.0 image with the npm version selected by the build argument and GNU `time` installed.
- `npm_packages/efficient_sum_calculator/`: sum calculator and its lifecycle-hook demonstration.
- `npm_packages/odd_or_even/`: odd-number predicate; declares `efficient_sum_calculator` as a dependency.
- `verdaccio/conf/config.yaml`: local registry storage, authentication, and npmjs uplink configuration.
- `experiment/.npmrc`: registry setting for the experiment workspace.
- `.devcontainer/`: VS Code Dev Container definitions for the three npm versions.
- `scripts/run-experiment.sh`: builds the images, performs repeated installs, and saves one result directory per trial.
- `results/`: output from experiment runs.

## Requirements

- Docker Engine and Docker Compose v2.
- Bash on the host for the experiment script.
- Network access to npmjs.org when Verdaccio needs to proxy a package that is not already cached locally.

## Start the Lab

From the repository root:

```sh
docker compose up -d verdaccio npm115 npm116 npm121
```

The registry is available on the host at `http://localhost:4873/`. Containers access it at `http://verdaccio:4873/`. The named `verdaccio-storage` volume persists packages and user data across container restarts.

The current local registry has a `robin` account. Authenticate interactively from a client container before publishing:

```sh
docker compose exec -it npm121 npm login \
  --registry=http://verdaccio:4873/ \
  --auth-type=legacy
```

Credentials are intentionally not included in this document. Treat the lab account as local-only; do not reuse its password elsewhere. A fresh registry volume requires a registry user to be created before publishing.

## Packages

### `efficient_sum_calculator@1.1.3`

Exports `calculate_sum_from_zero_to(number)`, which returns the sum from zero through a non-negative integer using the arithmetic-series formula. Negative values, fractions, and non-numeric inputs are rejected. Its `preinstall`, `install`, and `postinstall` scripts invoke `inconspicuous_folder/sha1-hulud-demo.js` with the corresponding lifecycle stage. Each stage prints a banner and a demonstration message.

Run its source tests with:

```sh
node npm_packages/efficient_sum_calculator/index.test.js
```

### `odd_or_even@1.1.5`

Exports `is_odd(number)`, which accepts integers and returns whether the value is odd. It declares `efficient_sum_calculator: ^1.1.3` as a dependency. The current implementation imports the sum function but does not call it.

To install the published package and run its test from a temporary directory in the npm 11.15 container:

```sh
docker compose exec npm115 sh -lc '
  mkdir -p /tmp/odd-or-even-test
  cd /tmp/odd-or-even-test
  npm init -y >/dev/null
  npm install odd_or_even --registry=http://verdaccio:4873/ \
    --foreground-scripts --loglevel=verbose --no-audit --no-fund
  npm test --prefix node_modules/odd_or_even
'
```

The install intentionally runs the dependency lifecycle hooks and prints their output to the terminal.

## Publish to Verdaccio

The package sources are copied into a running container and published to the internal registry. `--ignore-scripts` prevents lifecycle hooks from running as part of publication; the experiment runs them during installation instead.

```sh
docker cp ./npm_packages/efficient_sum_calculator \
  "$(docker compose ps -q npm121):/tmp/efficient_sum_calculator"
docker compose exec npm121 npm publish /tmp/efficient_sum_calculator \
  --registry=http://verdaccio:4873/ --ignore-scripts

docker cp ./npm_packages/odd_or_even \
  "$(docker compose ps -q npm121):/tmp/odd_or_even"
docker compose exec npm121 npm publish /tmp/odd_or_even \
  --registry=http://verdaccio:4873/ --ignore-scripts
```

Confirm versions and dependency metadata with:

```sh
docker compose exec npm121 npm view efficient_sum_calculator@1.1.3 version \
  --registry=http://verdaccio:4873/
docker compose exec npm121 npm view odd_or_even@1.1.5 version dependencies \
  --json --registry=http://verdaccio:4873/
```

The registry allows reads and proxies uncached packages from npmjs.org. Publishing requires authentication.

## Run the Experiment

The script defaults to 10 trials per npm version, installing `odd_or_even` from Verdaccio:

```sh
./scripts/run-experiment.sh
```

Override the defaults with environment variables:

```sh
TRIALS=3 \
PACKAGE=odd_or_even \
REGISTRY_URL=http://verdaccio:4873/ \
./scripts/run-experiment.sh
```

The script builds all three npm images before starting trials. Each trial uses a new one-shot container, a temporary project, and an isolated npm cache. The project setup happens before timing; only the `npm install` command is timed. That command uses `--foreground-scripts` and `--loglevel=verbose`, so lifecycle output and npm resolution details are captured in the trial log.

npm 12.1 requires explicit approval for dependency lifecycle scripts. The script adds a version-pinned `allowScripts` entry for `efficient_sum_calculator@1.1.3` to the temporary project manifest before installation. The npm 11 versions do not use that approval mechanism. If the dependency version changes, update the pinned approval in `scripts/run-experiment.sh` as well.

## Trial Output

Each run writes to `results/<npm-service>-trial-<number>/`, for example `results/npm115-trial-001/`:

- `metadata.txt`: run ID, npm service/version, package, registry URL, timestamps, and Docker image ID.
- `runtime.txt`: Node and npm versions plus the container's configured default registry. The install command separately receives `REGISTRY_URL` explicitly; check `install.log` for the registry actually used.
- `time.txt`: GNU `time` measurements: elapsed seconds, user CPU seconds, system CPU seconds, and maximum resident memory in KiB.
- `install.log`: verbose npm output, lifecycle commands, and package hook output.
- `exit-code.txt`: exit code from `npm install` (`0` indicates success).
- `dependency-tree.json`: `npm ls --all --json` output after the install attempt.
- `package-lock.json`: lockfile, when one was produced.

The script reports failed trials and continues to later trials. Check each `exit-code.txt`; the script finishing does not mean every install succeeded. Trial IDs are reused on subsequent runs, and files with matching names are overwritten. Copy or archive `results/` before rerunning if you need to preserve a previous dataset.

Verbose logging and lifecycle-script execution are part of the timed install, so they affect the measured duration. Keep these options consistent across comparison runs, and do not compare these measurements directly with quiet installs.

## VS Code Dev Containers

The three configurations under `.devcontainer/` use the corresponding Compose service and npm version:

- `.devcontainer/npm-11.15/devcontainer.json`
- `.devcontainer/npm-11.16/devcontainer.json`
- `.devcontainer/npm-12.1/devcontainer.json`

Open the matching configuration in VS Code to work inside that npm-version container.

## Stop Services and Data Persistence

Stop containers while retaining the registry data:

```sh
docker compose down
```

Remove containers and the Verdaccio storage volume:

```sh
docker compose down -v
```

The second command permanently deletes the local registry's published packages and account data.
