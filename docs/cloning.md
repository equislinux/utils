# Cloning the workspace

`bin/equislinux-clone` clones (or refreshes) every repository in the
`equislinux` GitHub organization into one directory named `equislinux`.
It uses the local `gh` session, so private repositories work without putting
tokens or passwords in the script.

## Local use

```bash
# From this repository
./bin/equislinux-clone --dest ~/repos/equislinux

# From the directory that should become the workspace
cd ~/repos/equislinux
./bin/equislinux-clone --here

# Public repositories only
./bin/equislinux-clone --dest ~/Documents/equislinux --no-private

# One repository (useful for testing)
./bin/equislinux-clone --only ops --dest /tmp/test/equislinux
```

The destination must be named `equislinux`; the script creates it and writes
the `.equislinux-workspace` marker if missing. `--here` uses the current
directory when its basename is already `equislinux`; otherwise it creates
`./equislinux` inside the current directory. It cannot be combined with
`--dest`.

## Remote use

The script is standalone and can be fetched and executed on a new machine:

```bash
curl -fsSL \
  https://github.com/equislinux/utils/raw/refs/heads/main/bin/equislinux-clone \
  -o /tmp/equislinux-clone
bash /tmp/equislinux-clone --dest "$HOME/repos/equislinux"
```

Or through an SSH host with the workspace mounted/available:

```bash
ssh host 'bash -s -- --dest "$HOME/repos/equislinux"' \
  < bin/equislinux-clone
```

The target machine needs `gh` installed and authenticated
(`gh auth login`), and `git`.

## Private repositories

- The script lists repositories with `gh repo list`, which includes private
  repositories visible to the current account. `ops` is cloned when the
  session can see it.
- No token is read, printed or stored by the script; `gh` supplies the
  credentials through its configured git protocol. HTTPS is recommended:
  `gh config set git_protocol https`.
- If the private repository is not visible or authentication fails, the
  operation is reported as a failure. Use `--no-private` to skip private
  repositories intentionally and clone them manually.
- `gh auth status` must succeed before anything is cloned.

## Branches

A normal `git clone` fetches every branch currently present on the remote.
By default this script also creates **local tracking branches** for all of
them, so `git branch` shows the full set. Use `--no-local-branches` to leave
only `origin/*` refs.

- Deleted remote branches are not recreated.
- Existing repositories are refreshed with `git fetch --all --prune --tags`;
  the working tree is not pulled or reset.
- Local branches for branches that no longer exist on the remote are not
  deleted automatically; clean them up manually if desired.

## Workspace detection

With no `--dest`, the destination is chosen from:

1. `X_WORKSPACE`
2. `~/.config/equislinux/workspace`
3. the parent of this checkout (`utils/../`)
4. the current directory if it is named `equislinux`
5. `~/Documents/repos/equislinux`, `~/repos/equislinux`,
   `~/Documents/equislinux`, or `~/equislinux` (first existing parent)

## Options

```
--dest DIR / --workspace DIR   workspace root (must be named equislinux)
--here                         current directory, or ./equislinux inside it
--org NAME                     GitHub organization (default: equislinux)
--no-private / --public-only   skip private repositories
--no-local-branches            only fetch origin/* refs
--only NAME                    one repository (repeatable)
--dry-run                      print the plan without writing
--help                         show usage
```

## Examples

```bash
# Refresh an existing workspace (fetch all remotes/tags, create missing
# local branches, leave working trees alone)
./bin/equislinux-clone --dest ~/repos/equislinux

# Plan without touching the filesystem
./bin/equislinux-clone --dest ~/repos/equislinux --dry-run

# Public-only workspace
./bin/equislinux-clone --dest ~/repos/equislinux --no-private
```

## Troubleshooting

- `gh is not authenticated`: run `gh auth login`.
- `clone failed: ops`: the private repository is not visible to the current
  account or the git protocol is not configured; check `gh auth status` and
  `gh config get git_protocol`, or use `--no-private`.
- `workspace directory must be named 'equislinux'`: pass a path whose last
  component is `equislinux`.
- Existing non-git directory with the same name as a repository: the script
  reports the conflict and continues with the others; move it away and rerun.
