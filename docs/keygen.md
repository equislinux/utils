# Signing key generator

`bin/equislinux-keygen` generates the ed25519 signing key for the `[x]`
repository and its public/revocation material. The private keyring is written
outside every git worktree, by default to `<workspace>/keys`.

## Defaults

- Output: `<workspace>/keys`
- Algorithm: ed25519, signing only
- Expiry: never (`0`); pass `--expiry 2y` etc. if desired
- Passphrase: **protected by default** (pinentry)
- Refuses to run as root
- Refuses to write inside a git worktree
- Refuses a non-empty output directory unless `--force`

## Commands

```bash
# Print the plan; no directories or keys are created
./bin/equislinux-keygen --dry-run

# Generate a passphrase-protected key (default)
./bin/equislinux-keygen

# Development/automation only: no passphrase
./bin/equislinux-keygen --no-passphrase

# Custom location, identity or expiry
./bin/equislinux-keygen --out /media/offline/keys \
  --name "X Linux Repository" --email dev@xscriptor.com --expiry 2y

# Rotate: move the previous keys directory to keys.bak.<timestamp>
./bin/equislinux-keygen --force
```

Other options: `--workspace PATH`, `--protect` (explicit default),
`--no-passphrase`, `--force`, `--out`, `--name`, `--email`, `--expiry`.

## Output

| Path | Purpose | Share |
|------|---------|-------|
| `gnupg/` | secret keyring and GNUPGHOME | **never** |
| `signing.pub` | ASCII public key | yes |
| `trustedkeys.gpg` | binary keyring for consumers | yes |
| `revoke.asc` | revocation certificate | keep separately |
| `env.sh` | `GNUPGHOME` + `X_REPO_SIGN_KEY` | no |
| `README.md` | generated backup/rotation notes | no |

`keys/` is mode `0700`; `env.sh` and `revoke.asc` are `0600`.

## Backup

Copy `gnupg/` and `revoke.asc` to an offline medium; keep a permission-
preserving archive if the destination is exFAT/NTFS. Test the backup by
listing the secret key from the restored copy. The private keyring must never
be committed or uploaded unencrypted.

See the private operations runbook for the backup procedure and inventory.

## Rotation

`--force` does **not** delete the old key: it moves the whole keys directory to
`<keys>.bak.<timestamp>` before generating the new one. A rotation is still a
trust transition:

1. Re-sign the repository DB/packages with the new key.
2. Update the keyring embedded in the ISO/live environment and WSL rootfs.
3. Give existing installations a transition package signed by the old key, if
   the old private key is still available.
4. Revoke the old key if it was compromised.
5. Verify fresh and updated installations.

The private operations runbook contains the full rotation procedure.

## Signing

```bash
source <workspace>/keys/env.sh
(cd <workspace>/x-repo && ./build-packages.sh --index-only)
```

`env.sh` contains an absolute `GNUPGHOME`. If the workspace path changes,
update it deliberately or regenerate the file with the key generator (without
rotating the keyring).

## Verification

The generator performs a sign/verify self-test. To check an existing keyring:

```bash
GNUPGHOME=<workspace>/keys/gnupg gpg --list-secret-keys
```

Do not paste private key material into logs or chat.

## Troubleshooting

- `keys directory is not empty`: use `--force` only if you intend to rotate;
  it moves the old directory to a backup first.
- `refusing to write keys inside a git worktree`: choose `--out` outside the
  repositories (the default `<workspace>/keys` is already outside them).
- Pinentry/gpg errors: ensure a working pinentry and a local terminal; for
  automation use `--no-passphrase` only in a development context.
- `do not run this as root`: the keyring must belong to your user.
