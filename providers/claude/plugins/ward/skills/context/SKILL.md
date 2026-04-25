# ward:context

Use this skill when working with ward in a project — setting up secrets, creating vaults, configuring environments, or debugging merge issues.

## File hierarchy

Always create ward files in the correct location based on context:

- **Project-level secrets** → `.ward/vault/secrets.ward` (base, shared across all envs)
- **Per-environment secrets** → `.ward/vault/<env>.ward` (e.g. `staging.ward`, `production.ward`)
- **Shared secrets (monorepo)** → path declared in `.ward/config.yaml` under `vaults`, e.g. `../.commons/ward/vaults/shared/`
- **Out-of-vault files** → only when the path is explicitly declared in `config.yaml`

Before creating any file, run `ward vaults` to check which paths are already registered. New files must be inside a registered vault path or added to `config.yaml` first. Never create `.ward` files in arbitrary locations.

## Setting up ward in a project

```sh
ward init
```

Creates `.ward/config.yaml`, generates `.ward.key` (gitignore it), and creates the first `.ward/vault/secrets.ward`.

Add `.ward.key` to `.gitignore`:
```sh
echo ".ward.key" >> .gitignore
```

For CI, use the `WARD_KEY` token printed by `ward init`:
```sh
export WARD_KEY=ward-AAAA...
```

## Creating vault files

```sh
ward new staging        # → .ward/vault/staging.ward
ward new production     # → .ward/vault/production.ward
ward new infra/prod     # → infra/prod.ward (outside default vault)
```

Each file opens in `$EDITOR`. Write YAML with the same root key as `secrets.ward`.

## Editing secrets

```sh
ward edit                          # edit first file in default vault
ward edit .ward/vault/staging.ward # edit specific file
```

## Viewing and inspecting

```sh
ward view                              # full merged tree with origins
ward view myapp.environments.staging   # scoped to a dot-path
ward envs myapp.environments.staging   # env vars that would be injected
ward inspect myapp.environments.staging # ancestry chain
ward vaults                            # list all vaults and discovered files
```

## Running commands with secrets

```sh
ward exec myapp.environments.staging -- rails server
ward exec myapp.environments.staging -- docker compose up
ward exec myapp.environments.staging -- env | grep DATABASE
```

## Debugging issues

**Wrong or missing value:**
1. Run `ward view <dot.path>` — check the origin of each value
2. Run `ward inspect <dot.path>` — verify ancestry chain
3. Run `ward vaults` — confirm the file is being discovered

**Conflict error:**
Two files at the same ancestry level define the same key. To resolve:
- Remove the key from one of the files
- Or move it to a common ancestor

**Key not found:**
- Check `.ward/config.yaml` for `key_file` or `key_env`
- Verify `WARD_KEY` is set in the environment
- Check that `.ward.key` exists and is not empty

**File not discovered:**
- Run `ward vaults` — the file's directory must be listed
- Use `ward new` to create files (it auto-registers new vaults)

## Multiple vaults (monorepo)

```yaml
# .ward/config.yaml
vaults:
  - path: ./.ward/vault
  - path: ../.commons/ward/vaults/shared
```

## Common patterns

**Makefile:**
```makefile
run:
    ward exec myapp.environments.staging -- go run ./cmd/server
```

**Docker:**
```sh
ward exec myapp.environments.staging -- docker compose up
```

**Export as .env:**
```sh
ward export myapp.environments.staging
```
