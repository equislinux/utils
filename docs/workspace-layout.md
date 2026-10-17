# Workspace layout and discovery

EquisLinux is not a monorepo: each component is its own git repository, and
all of them are siblings inside a directory named `equislinux`.

```
<parent>/equislinux/
├── .equislinux-workspace   # marker, not tracked by any repository
├── x/
├── scripts/
├── xpm/
├── xpkg/
├── x-repo/
├── web/
├── wiki/
├── wsl/
├── wsl-scripts/
├── utils/
├── ops/
└── keys/                   # signing material, never tracked
```

`<parent>` is variable. The supported examples are:

- `~/Documents/repos/equislinux`
- `~/Documents/equislinux`
- `~/repos/equislinux`
- `~/src/equislinux`
- `~/equislinux`

## Discovery order

`lib/common.sh` resolves the workspace in this order:

1. `--workspace PATH` (commands that accept it)
2. `X_WORKSPACE`
3. the first non-comment line of
   `${XDG_CONFIG_HOME:-~/.config}/equislinux/workspace`
4. the parent of the `utils` repository (the normal case)
5. the common locations listed above

An explicit path that does not exist, or that does not look like an
EquisLinux workspace, is a hard error. The fallback locations are only tried
when no explicit path is configured.

To make the workspace explicit on a new machine:

```bash
./bin/equislinux-workspace --init /path/to/equislinux
./bin/equislinux-workspace --set-default
```

`--init` creates the marker. `--set-default` writes the config file, which is
useful when `utils` is cloned outside the workspace or symlinked somewhere
else.

## Why not a `.env` file?

A `.env` file is resolved relative to the current working directory, must be
sourced by every shell, and is easy to commit accidentally. These utilities
are invoked from different directories (including from release scripts); a
user-level config file plus a workspace marker is deterministic and does not
depend on the caller's `cwd`.

If you prefer environment variables, export `X_WORKSPACE` in your shell
profile. Do not commit a `.env` with machine paths to any repository.

## Moving the workspace

The parent can change without editing the utilities: the scripts resolve paths
at runtime. After moving the workspace, re-run the sudo utility so the
absolute paths in `/etc/sudoers.d/equislinux` are regenerated:

```bash
./bin/equislinux-sudo --apply
```

Key material stays at `<workspace>/keys`; if you move the workspace, move
that directory with it (or update `X_KEYS_DIR`). `keys/env.sh` contains an
absolute `GNUPGHOME`, so regenerate it only by running the key generator, or
edit it deliberately after a move.

## Symlinks

The scripts resolve symlinks with `readlink -f`, so a symlink such as
`~/bin/equislinux-sudo -> <workspace>/utils/bin/equislinux-sudo` still
discovers the correct workspace.
