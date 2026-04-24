#!/usr/bin/env bash
# Remove the realtek-rtl88xxau DKMS package and unload its module.
# Does not delete the driver source tree.

set -euo pipefail

PACKAGE_NAME="realtek-rtl88xxau"
MODULE_NAME="88XXau"

log()  { printf '==> %s\n' "$*"; }
warn() { printf 'warn: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "must run as root (use sudo)"
command -v dkms >/dev/null || die "dkms not installed"

if lsmod | awk '{print $1}' | grep -qx "$MODULE_NAME"; then
    log "unloading $MODULE_NAME"
    rmmod "$MODULE_NAME" 2>/dev/null || warn "could not unload $MODULE_NAME (in use?)"
fi

if dkms status 2>/dev/null | grep -q "^$PACKAGE_NAME/"; then
    versions=$(dkms status | awk -F'[/,]' -v p="$PACKAGE_NAME" '$1==p{print $2}' | sort -u)
    while IFS= read -r v; do
        [[ -z "$v" ]] && continue
        log "dkms remove $PACKAGE_NAME/$v"
        dkms remove "$PACKAGE_NAME/$v" --all || true
    done <<< "$versions"
else
    log "$PACKAGE_NAME not in dkms tree — nothing to remove"
fi

log "done. driver source tree left intact."
