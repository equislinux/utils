# Sudo rules utility

`bin/equislinux-sudo` manages the narrow `NOPASSWD` rules used by the release
and validation scripts. It resolves the workspace at runtime, so the rule
paths follow the actual checkout instead of a hardcoded home directory.

## Commands

```bash
# Show the rules that would be written (default; no changes)
./bin/equislinux-sudo

# Write /etc/sudoers.d/equislinux (asks for your sudo password)
./bin/equislinux-sudo --apply

# Inspect or remove them
sudo ./bin/equislinux-sudo status
sudo ./bin/equislinux-sudo remove
```

Legacy spellings from the old `xlnux-sudo.sh` are accepted:

```bash
sudo ./bin/equislinux-sudo --create   # same as install --apply
sudo ./bin/equislinux-sudo --status
sudo ./bin/equislinux-sudo --remove
```

## What it grants

The allowlist is intentionally small:

- `scripts/test/generations-btrfs.sh`
- `x/xbuild.sh`
- `wsl/publish-sf.sh`
- `wsl/build-rootfs.sh`

For each one it writes both forms, when applicable:

```
<user> ALL=(root) NOPASSWD: /usr/bin/bash /absolute/path/to/script
<user> ALL=(root) NOPASSWD: /absolute/path/to/script
```

The file is installed as `/etc/sudoers.d/equislinux` with mode `0440` and
root ownership. The legacy `/etc/sudoers.d/xlnux-sprint` is removed on
`--apply` unless `--keep-legacy` is used.

## Workspace and path changes

The workspace is discovered with `--workspace`, `X_WORKSPACE`, the
`~/.config/equislinux/workspace` file, the parent of this repository, or the
common locations. If the workspace move or is renamed, rerun:

```bash
./bin/equislinux-sudo --apply
```

The old absolute paths would otherwise remain in sudoers.

## Safety

- **`NOPASSWD` on a script the target user can edit is equivalent to
  passwordless root.** The utility prints a warning. `--strict` refuses
  user-writable targets for root-owned layouts, but this is a convenience for
  a single-user development machine, not a security boundary.
- The generated file is validated with `visudo -cf` before installation.
- The previous file is backed up under `/var/backups/equislinux`.
- Changes take effect immediately; **no reboot is required**. Removing the
  file revokes future invocations. An already-running process keeps its
  privileges.
- After `remove`, `sudo -k` clears any cached sudo timestamp.
- `--user USER` grants the rules to another account; the default is
  `SUDO_USER` or the invoking user.

## Verification

```bash
sudo ./bin/equislinux-sudo status
sudo -n -l | grep -i equislinux
sudo -n /usr/bin/bash /absolute/path/to/scripts/test/generations-btrfs.sh
```

The last command should work only while the rules are installed. After
`remove`, it should fail with a password requirement.

## Troubleshooting

- `sudo: a password is required`: run the command interactively; `--apply`,
  `status` and `remove` need root.
- `workspace not found`: pass `--workspace /path/to/equislinux`, export
  `X_WORKSPACE`, or run `equislinux-workspace --set-default`.
- `visudo rejected the generated rules`: nothing is installed; the previous
  file is restored. Check the reported path and rerun.
- `path exists but...`: the four expected scripts must exist in the workspace;
  clone/pull the repositories first.
