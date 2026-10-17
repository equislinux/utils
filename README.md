# EquisLinux utilities

Operator utilities for the EquisLinux production workspace. These are **not**
runtime components of the distribution: they help maintainers locate the
workspace, grant the narrow sudo permissions needed by release/validation
scripts, and generate the repository signing key.

## Workspace contract

The utilities expect one directory named `equislinux` containing every
repository at the same level:

```
.../equislinux/
├── x/
├── scripts/
├── xpm/
├── xpkg/
├── x-repo/
├── web/
├── wiki/
├── wsl/
├── wsl-scripts/
├── utils/        <- this repository
└── ops/          <- private operations notes (not required here)
```

The parent of the workspace is not fixed: `~/Documents/repos/equislinux`,
`~/Documents/equislinux`, `~/repos/equislinux`, etc. are all valid.

Workspace discovery order:

1. `--workspace PATH` (where supported)
2. `X_WORKSPACE`
3. `~/.config/equislinux/workspace` (single path)
4. the parent directory of this repository (normal case)
5. common locations under `$HOME`

A `.equislinux-workspace` marker at the workspace root makes detection
unambiguous. There is intentionally no `.env`: it is working-directory
dependent and easy to commit by accident. See
[`docs/workspace-layout.md`](docs/workspace-layout.md).

## Clone the workspace

`equislinux-clone` bootstraps a new machine by cloning every repository in the
organization into a workspace named `equislinux`. It also refreshes existing
checkouts with `git fetch --all --prune --tags`.

From a checkout:

```bash
./bin/equislinux-clone --dest ~/repos/equislinux
```

On a machine without the repository (the script is standalone):

```bash
curl -fsSL \
  https://raw.githubusercontent.com/equislinux/utils/main/bin/equislinux-clone \
  -o /tmp/equislinux-clone
bash /tmp/equislinux-clone --dest "$HOME/repos/equislinux"
```

Or directly through a pipe:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/equislinux/utils/main/bin/equislinux-clone \
  | bash -s -- --dest "$HOME/repos/equislinux"
```

- Requires `gh` installed and authenticated (`gh auth login`) and `git`.
- Private repositories (`ops`) are cloned when the current `gh` session can
  see them. The script never reads or stores tokens. Use `--no-private` to
  leave them out and clone them manually.
- Every branch currently on the remote is fetched. By default the script also
  creates local tracking branches; use `--no-local-branches` to keep only
  `origin/*`.
- Useful options: `--dry-run`, `--only NAME`, `--org NAME`.
- Full details: [`docs/cloning.md`](docs/cloning.md).

## Commands

```bash
# Print the detected workspace, or pin it explicitly
./bin/equislinux-workspace
./bin/equislinux-workspace --init /path/to/equislinux
./bin/equislinux-workspace --set-default

# Show the sudo rules that would be installed (no changes)
./bin/equislinux-sudo --dry-run

# Install them (asks for your sudo password); removes the legacy
# /etc/sudoers.d/xlnux-sprint file automatically
./bin/equislinux-sudo --apply

# Inspect or remove them
sudo ./bin/equislinux-sudo status
sudo ./bin/equislinux-sudo remove

# Legacy aliases from xlnux-sudo.sh are accepted:
#   --status, --remove, --create (create = install --apply)

# Plan a signing key, then generate it outside any git worktree
./bin/equislinux-keygen --dry-run
./bin/equislinux-keygen                 # passphrase-protected (default)
./bin/equislinux-keygen --no-passphrase # development/automation only
```

The sudo rules cover only the scripts that need root:

- `scripts/test/generations-btrfs.sh`
- `x/xbuild.sh`
- `wsl/publish-sf.sh`
- `wsl/build-rootfs.sh`

## Security notes

- **NOPASSWD on a script the target user can edit is equivalent to
  passwordless root.** This utility warns about it and offers `--strict` for
  root-owned layouts, but it is meant for a single-user development machine,
  not as a security boundary.
- Key material is written to `<workspace>/keys` by default and the generator
  refuses to write inside a git worktree. Never commit `gnupg/`, `env.sh` or
  `revoke.asc`.
- The key generator protects the key with a passphrase by default. The
  `--no-passphrase` mode is only for development and automated signing; keep
  an offline backup either way.
- The sudo utility validates the generated file with `visudo` before
  installing it and backs up the previous sudoers file under
  `/var/backups/equislinux`.

## Development

```bash
make check
```

The smoke test runs `bash -n`, shellcheck (when available), workspace
discovery, the sudo dry-run, and the keygen help. It never touches real keys
or sudoers.

## License

GPL-3.0-or-later. See [`LICENSE`](LICENSE).
