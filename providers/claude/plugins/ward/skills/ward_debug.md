# ward:debug

Use this skill when the user reports unexpected values, missing secrets, merge conflicts, or ancestry issues with ward.

## What to do

Given a dot-path (e.g. `myapp.environments.staging`), run the following to diagnose:

### 1. Inspect ancestry chain

```sh
ward inspect <dot.path>
```

This shows which files contribute to the target, in order from least to most specific.

### 2. View merged tree with origins

```sh
ward view <dot.path>
```

Shows the merged result with source file and line for each value. Look for unexpected origins.

### 3. Check for conflicts

If ward refuses to merge, it prints the conflicting files and keys. Read the error carefully — it tells you exactly which files define the same key at the same ancestry level.

To resolve:
- Remove the key from one of the conflicting files
- Or move it to a common ancestor

### 4. Inspect raw file content

```sh
ward raw <file.ward>
```

Shows the decrypted YAML of a single file without merging. Useful to verify what a file actually contains.

### 5. List vaults and discovered files

```sh
ward vaults
```

Confirms which directories are being scanned and which `.ward` files are discovered.

### 6. Check env vars

```sh
ward envs <dot.path>
```

Shows the final env vars that would be injected. Compare with expected values.

## Common issues

**Value is wrong or missing:**
- Run `ward view <dot.path>` and check the origin of each value
- A file at a more specific level may be overriding unexpectedly
- The file may not be in the vault path — check `ward vaults`

**Conflict error:**
- Two files at the same ancestry level define the same key
- Use `ward inspect` to see the full ancestry chain
- Move the shared key to a common ancestor file

**Ward can't find the key:**
- Check `.ward/config.yaml` for `key_file` or `key_env`
- Verify `WARD_KEY` is set in the environment if using CI
- Check that `.ward.key` exists and is not empty

**File not discovered:**
- Check `ward vaults` — the file's directory must be listed as a vault
- Run `ward new` to create new files (it auto-registers new vaults)
