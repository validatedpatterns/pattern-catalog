# Pattern Catalog

A catalog of [Validated Patterns](https://validatedpatterns.io) metadata, served as a static nginx container for consumption by the [patterns-operator](https://github.com/validatedpatterns/patterns-operator).

## How it works

The `generate-catalog.sh` script queries the GitHub API for all repositories tagged with `pattern` in the `validatedpatterns` and `validatedpatterns-sandbox` organizations. For each repository it:

1. Fetches `pattern-metadata.yaml` and normalizes it into a consistent schema
2. Fetches `values-secret.yaml.template` if present
3. Writes per-pattern files under `catalog/<pattern-name>/`
4. Generates a `catalog/catalog.yaml` index listing all discovered patterns

The resulting `catalog/` directory is served by an nginx container image that the patterns-operator deploys on-cluster.

## Prerequisites

- `gh` (GitHub CLI, authenticated)
- `yq` v4+
- `jq`
- `podman`

## Usage

### Regenerate the catalog

The catalog data must be regenerated locally and committed before pushing.
The CI pipeline does **not** run `generate-catalog.sh` — it only builds the
container from whatever is already in `catalog/`.

```sh
make generate-catalog   # or ./generate-catalog.sh directly
git add catalog/
git commit -m "Update catalog"
git push origin main    # or stable-v1
```

### List all pattern repositories

```sh
./list-all-patterns.sh
```

### Build and push the container image locally

```sh
make pattern-ui-catalog-build
make pattern-ui-catalog-push
```

## CI/CD

A GitHub Actions workflow (`.github/workflows/build-and-push.yml`) triggers on
pushes to `main` or `stable-v1` when files in `catalog/`, `templates/`, or the
workflow itself change:

1. **validate-yaml** — validates all YAML files under `catalog/` with `yamllint`
2. **build-container** — builds the image for amd64 and arm64 in parallel on native runners
3. **push-multiarch-manifest** — assembles a multi-arch manifest, pushes to Quay, and signs with cosign (only in the upstream `validatedpatterns/pattern-ui-catalog` repo)

| Branch      | Image tag     |
|-------------|---------------|
| `main`      | `:latest`     |
| `stable-v1` | `:stable-v1`  |

The workflow requires `QUAY_USERNAME` and `QUAY_PASSWORD` secrets configured in a `quay` environment.

## Repository structure

```
catalog/                  # Generated catalog data (served by nginx)
  catalog.yaml            # Index of all patterns
  <pattern>/pattern.yaml  # Normalized metadata per pattern
  <pattern>/values-secret.yaml.template  # Secret template (if available)
.github/workflows/        # CI/CD workflow
templates/                # Dockerfile template
generate-catalog.sh       # Catalog generation script
list-all-patterns.sh      # Lists all pattern repos
Makefile                  # Build targets
```
