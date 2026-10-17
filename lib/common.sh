#!/usr/bin/env bash
# Shared helpers for EquisLinux operator utilities.
# shellcheck shell=bash

x_die() { printf 'error: %s\n' "$*" >&2; exit 1; }
x_warn() { printf 'warning: %s\n' "$*" >&2; }
x_info() { printf '%s\n' "$*"; }

x_have() { command -v -- "$1" >/dev/null 2>&1; }

x_config_file() {
    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/equislinux/workspace"
}

x_is_workspace() {
    local ws=$1
    [[ -d $ws ]] || return 1
    [[ $(basename -- "$ws") == equislinux ]] || return 1
    if [[ -f $ws/.equislinux-workspace ]]; then
        return 0
    fi
    # Fallback for a fresh clone before the marker is created.
    [[ -d $ws/x && -d $ws/scripts && -d $ws/xpm ]]
}

x_find_workspace() {
    local explicit=${1:-}
    local candidate cfg line utils_parent

    if [[ -n $explicit ]]; then
        candidate=$(realpath -e -- "$explicit" 2>/dev/null) || x_die "workspace not found: $explicit"
        x_is_workspace "$candidate" || x_die "not an EquisLinux workspace: $candidate"
        printf '%s\n' "$candidate"
        return 0
    fi

    if [[ -n ${X_WORKSPACE:-} ]]; then
        candidate=$(realpath -e -- "$X_WORKSPACE" 2>/dev/null) || x_die "X_WORKSPACE does not exist: $X_WORKSPACE"
        x_is_workspace "$candidate" || x_die "X_WORKSPACE is not an EquisLinux workspace: $candidate"
        printf '%s\n' "$candidate"
        return 0
    fi

    cfg=$(x_config_file)
    if [[ -f $cfg ]]; then
        while IFS= read -r line; do
            [[ -z $line || $line == \#* ]] && continue
            candidate=$(realpath -e -- "$line" 2>/dev/null) || x_die "workspace from $cfg does not exist: $line"
            x_is_workspace "$candidate" || x_die "workspace from $cfg is not valid: $candidate"
            printf '%s\n' "$candidate"
            return 0
        done <"$cfg"
        x_die "no workspace path found in $cfg"
    fi

    # When these utilities are cloned inside the workspace, this is the
    # normal path: <workspace>/utils/bin/... -> <workspace>.
    if [[ -n ${UTILS_ROOT:-} ]]; then
        utils_parent=$(dirname -- "$UTILS_ROOT")
        if [[ -n $utils_parent && $utils_parent != "." ]] && x_is_workspace "$utils_parent"; then
            realpath -e -- "$utils_parent"
            return 0
        fi
    fi

    for candidate in \
        "$HOME/Documents/repos/equislinux" \
        "$HOME/Documents/equislinux" \
        "$HOME/repos/equislinux" \
        "$HOME/src/equislinux" \
        "$HOME/equislinux"; do
        [[ -d $candidate ]] || continue
        candidate=$(realpath -e -- "$candidate" 2>/dev/null) || continue
        if x_is_workspace "$candidate"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

x_require_workspace() {
    local ws
    if ! ws=$(x_find_workspace "${1:-}"); then
        x_warn "could not locate the EquisLinux workspace"
        x_warn "set X_WORKSPACE, create $(x_config_file), or pass --workspace PATH"
        x_warn "expected layout: .../equislinux/{x,scripts,xpm,xpkg,...,utils,ops}"
        return 1
    fi
    printf '%s\n' "$ws"
}

x_in_git_worktree() {
    local dir=$1
    x_have git || return 1
    git -C "$dir" rev-parse --show-toplevel >/dev/null 2>&1
}

x_abs_path() {
    realpath -m -- "$1"
}
