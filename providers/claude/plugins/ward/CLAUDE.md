# Ward — Claude Code Context

Ward is a hierarchical secrets manager. It organises encrypted secrets in layers — a root file defines shared config, environment files add or override specifics. No duplication, no syncing, no drift.

## Key concepts

**Vault**: a directory of `.ward` files discovered recursively. Each project has one or more vaults configured in `.ward/config.yaml`.

**`.ward` file**: an encrypted YAML document. Each file is a map with a single root key (the "anchor") that defines where in the hierarchy it lives.

**Dot-path**: a dotted key path used to target a specific node in the merged tree. Example: `myapp.environments.staging`.

**Ancestry**: ward determines which files are ancestors of a target by comparing their map-branch structure — not their file path. A file is an ancestor if its root key covers the same branch without conflicting.

**Merge**: files are merged from least to most specific (root → leaf). Leaf values override ancestors. Same-level conflicts are errors.

## Project structure

```
.ward/
  config.yaml          ← vault paths, encryption config
  vault/
    secrets.ward        ← shared secrets (root anchor)
    staging.ward        ← staging overrides
    production.ward     ← production overrides
```

## Configuration (.ward/config.yaml)

```yaml
encryption:
  key_file: .ward.key      # path to key file (gitignored)
  # key_env: WARD_KEY      # alternative: read key from env var

vaults:
  - path: ./.ward/vault
  - path: ./infra/secrets
  - path: ../.commons/ward/vaults/ruby   # outside project root is fine

default_dir: .ward/vault   # where `ward new <name>` places files
```

## Commands

### `ward init`
Initialise ward in the current directory. Creates `.ward/config.yaml`, generates `.ward.key`, and creates an initial `.ward/vault/secrets.ward`. Prints the `WARD_KEY` token for CI use.

```sh
ward init
```

### `ward new <name>`
Create a new encrypted `.ward` file and open it in `$EDITOR`.

```sh
ward new staging                          # → .ward/vault/staging.ward
ward new infra/prod                       # → infra/prod.ward (relative to CWD)
ward new ./.commons/ward/vaults/ruby/prod # → .commons/ward/vaults/ruby/prod.ward
```

If the file is outside existing vaults, it is automatically added to `.ward/config.yaml`.

### `ward edit [file]`
Decrypt a `.ward` file, open in `$EDITOR`, re-encrypt on save. Defaults to the first file in the default vault.

```sh
ward edit
ward edit .ward/vault/staging.ward
```

### `ward view [dot.path]`
Print the merged tree with source file and line for each value.

```sh
ward view
ward view myapp.environments.staging
```

Output:
```
myapp:
  name: acme                                            ← .ward/vault/secrets.ward:2
  staging:
    database_url: postgres://staging.acme.internal/app  ← .ward/vault/staging.ward:4
```

### `ward envs [dot.path] [--prefixed]`
Print the env vars that would be injected by `exec`.

```sh
ward envs                              # flat leaf names, all vaults merged
ward envs myapp.environments.staging   # scoped to that path
ward envs --prefixed                   # full dot-path as env var name
```

### `ward exec [dot.path] -- <command>`
Merge secrets and inject as env vars, then run a command.

```sh
ward exec myapp.environments.staging -- rails server
ward exec myapp.environments.staging -- env | grep DATABASE
```

### `ward get <dot.path>`
Print the merged value at a dot-path.

```sh
ward get myapp.staging.database_url
```

### `ward inspect <dot.path>`
Inspect the ancestry chain for a dot-path — which files contribute, in what order.

### `ward raw <file>`
Print the raw decrypted YAML of a `.ward` file without merging.

### `ward export [dot.path]`
Export merged secrets as a `.env` file or JSON.

### `ward vaults`
List all configured vaults and the files discovered in each.

### `ward config`
Open `.ward/config.yaml` in `$EDITOR`.

### `ward override`
Apply local overrides without modifying encrypted files.

## WARD_KEY — CI usage

`ward init` prints a `WARD_KEY=ward-<base64>` token. Set it in CI instead of mounting the key file:

```sh
export WARD_KEY=ward-AAAA...
ward exec myapp.environments.staging -- deploy
```

## Env var naming

| Scenario | Env var |
|---|---|
| No dot-path, no `--prefixed` | Flat leaf name: `DATABASE_URL` |
| No dot-path, `--prefixed` | Full dot-path: `MYAPP_STAGING_DATABASE_URL` |
| With dot-path | Scoped to path, flat leaf name: `DATABASE_URL` |

## Common patterns

**Add a new environment:**
```sh
ward new production
# opens $EDITOR — write YAML with same root key as secrets.ward
```

**Use ward in a Makefile:**
```makefile
run:
    ward exec myapp.environments.staging -- go run ./cmd/server
```

**Use ward in Docker:**
```sh
ward exec myapp.environments.staging -- docker compose up
```

**Multiple vaults (monorepo):**
```yaml
vaults:
  - path: ./.ward/vault
  - path: ../.commons/ward/vaults/shared
```

## Conflict resolution

Same-level conflicts are errors — ward tells you exactly where each conflicting definition lives:

```
conflict: cannot merge key "database_url" — defined in multiple files at the same level:
  → .ward/vault/conflict_a.ward:5
    database_url: postgres://conflict-a.internal/app
  → .ward/vault/conflict_b.ward:5
    database_url: postgres://conflict-b.internal/app

  to resolve:
    1. remove the key from one of the files
    2. move it to a common ancestor if shared across environments
```
