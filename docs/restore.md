# Restoring keys from the offline backup

The offline backup contains two independent archives:

| Archive | Contents |
|---|---|
| `keys-*.tar.gz` | project GPG keyring (`keys/gnupg`), `signing.pub`, `trustedkeys.gpg`, `revoke.asc`, `env.sh`, `README.md` |
| `ssh-sourceforge-*.tar.gz` | `~/.ssh/id_ed25519_sourceforge` and `.pub` |

Each archive has a `.sha256` file. The tars preserve Unix permissions; a plain
directory copy on exFAT does not.

## Script (recommended)

`bin/equislinux-restore` is standalone and can run from the repository or from
a copy on the backup disk. It is a **dry-run by default**:

```bash
# Preview
./bin/equislinux-restore \
  --backup-dir /run/media/x/PortableSSD/equislinux-backup-2026-10-17 \
  --workspace "$HOME/repos/equislinux"

# Restore
./bin/equislinux-restore \
  --backup-dir /run/media/x/PortableSSD/equislinux-backup-2026-10-17 \
  --workspace "$HOME/repos/equislinux" \
  --apply
```

If you `cd` into the backup directory, `--backup-dir` is optional:

```bash
cd /run/media/x/PortableSSD/equislinux-backup-2026-10-17
./tools/equislinux-restore --workspace "$HOME/repos/equislinux" --apply
```

The workspace must already exist and be named `equislinux`. The script:

1. verifies the `.sha256` files and the tar archives;
2. refuses to overwrite existing targets unless `--force` is used;
3. restores the keyring with `0700`/`0600`/`0644` permissions;
4. rewrites `GNUPGHOME` in `keys/env.sh` to the current workspace, preserving
   `X_REPO_SIGN_KEY`;
5. installs the SourceForge private key as `0600` and the public key as `0644`;
6. runs a secret-key count and `ssh-keygen -y` verification.

Useful options:

- `--ssh-dir DIR` — restore the SSH key somewhere other than `~/.ssh`.
- `--no-keys` / `--no-ssh` — restore only one part.
- `--force` — move existing `keys/` to `keys.pre-restore.<timestamp>` and an
  existing SourceForge key to `~/.ssh/pre-restore.<timestamp>/`.
- `--skip-checksum` — only if a `.sha256` file is missing.
- `--no-rewrite-env` — keep the old `GNUPGHOME` path.

Run it as your normal user, not as root. If you restore as root, ownership and
`HOME` will be wrong.

## Manual restore

If you prefer to do it by hand:

```bash
BACKUP=/run/media/x/PortableSSD/equislinux-backup-2026-10-17
WS="$HOME/repos/equislinux"

# Verify both archives
(cd "$BACKUP" && sha256sum -c keys-2026-10-17.tar.gz.sha256)
(cd "$BACKUP" && sha256sum -c ssh-sourceforge-2026-10-17.tar.gz.sha256)

# Keyring (workspace must exist)
mkdir -p "$WS"
tar -C "$WS" -xpf "$BACKUP/keys-2026-10-17.tar.gz"
chmod 700 "$WS/keys" "$WS/keys/gnupg"
chmod 600 "$WS/keys/env.sh" "$WS/keys/revoke.asc"

# The env.sh in the backup points to the old workspace.
# Edit its GNUPGHOME line to:
#   export GNUPGHOME="$WS/keys/gnupg"

# SourceForge key
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
tar -C "$HOME" -xpf "$BACKUP/ssh-sourceforge-2026-10-17.tar.gz"
chmod 600 "$HOME/.ssh/id_ed25519_sourceforge"
chmod 644 "$HOME/.ssh/id_ed25519_sourceforge.pub"
```

## After restoring

```bash
# Load the signing key path
source "$HOME/repos/equislinux/keys/env.sh"

# Check that the keyring is readable (count, not key material)
GNUPGHOME="$HOME/repos/equislinux/keys/gnupg" gpg --list-secret-keys

# Check the SSH key loads
ssh-keygen -y -f "$HOME/.ssh/id_ed25519_sourceforge" >/dev/null

# Install the new sudo rules
"$HOME/repos/equislinux/utils/bin/equislinux-sudo" --apply

# GitHub is not part of this backup; re-authenticate if needed
gh auth login
```

Do not commit `keys/`, `env.sh`, `revoke.asc` or `~/.ssh` to any repository.
If the backup disk leaves your home, encrypt it or keep the archives encrypted.

## Inventory

- `keys/` directory copy and `keys-2026-10-17.tar.gz` — project GPG material.
- `ssh-sourceforge-2026-10-17.tar.gz` — SourceForge SSH key.
- Both `.sha256` files verified when written.
- No GitHub SSH key and no personal GPG secret key are part of this backup.
