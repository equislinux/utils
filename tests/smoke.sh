#!/usr/bin/env bash
# Smoke tests: syntax, discovery, sudo dry-run and keygen help.
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)
fail=0

for f in "$ROOT"/bin/* "$ROOT"/lib/*.sh; do
    [[ -f $f ]] || continue
    if ! bash -n "$f"; then
        echo "syntax error: $f" >&2
        fail=1
    fi
done

ws=$("$ROOT/bin/equislinux-workspace")
if [[ $(basename -- "$ws") != equislinux ]]; then
    echo "unexpected workspace: $ws" >&2
    fail=1
fi
if [[ ! -d $ws/x || ! -d $ws/scripts ]]; then
    echo "workspace is missing expected repositories: $ws" >&2
    fail=1
fi

sudo_out=$("$ROOT/bin/equislinux-sudo" --dry-run)
if ! grep -q 'NOPASSWD' <<<"$sudo_out"; then
    echo "sudo dry-run did not produce NOPASSWD rules" >&2
    fail=1
fi
if ! grep -q 'generations-btrfs.sh' <<<"$sudo_out"; then
    echo "sudo dry-run is missing the generations test target" >&2
    fail=1
fi

"$ROOT/bin/equislinux-keygen" --help >/dev/null

if command -v shellcheck >/dev/null 2>&1; then
    if ! shellcheck -x "$ROOT"/bin/* "$ROOT"/lib/*.sh; then
        echo "shellcheck failed" >&2
        fail=1
    fi
fi

if [[ $fail -ne 0 ]]; then
    exit 1
fi
echo "smoke: OK (workspace: $ws)"
