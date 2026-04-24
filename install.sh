#!/usr/bin/env bash
# rtl88xxau-kit — install.sh
#
# Installs the aircrack-ng realtek-rtl88xxau driver via DKMS.
# Supports Realtek RTL8811/8812/8821/8814AU USB Wi-Fi adapters on
# Debian-based distros. See README.md for context and troubleshooting.
#
# https://github.com/ZlatanOmerovic/rtl88xxau-kit

set -euo pipefail

SRC_REPO="${SRC_REPO:-https://github.com/aircrack-ng/rtl8812au.git}"
PACKAGE_NAME="realtek-rtl88xxau"
MODULE_NAME="88XXau"
OLD_PACKAGE="rtl8812au"
OLD_MODULE="8812au"

log()  { printf '==> %s\n' "$*"; }
warn() { printf 'warn: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "must run as root (use sudo)"

command -v dkms >/dev/null || die "dkms not installed (apt install dkms)"
[[ -d "/lib/modules/$(uname -r)/build" ]] \
    || die "kernel headers missing for $(uname -r) — apt install linux-headers-$(uname -r)"

resolve_src_dir() {
    [[ -n "${SRC_DIR:-}" ]] && { printf '%s' "$SRC_DIR"; return; }

    local script_dir sudo_home candidate
    script_dir=$(dirname "$(readlink -f "$0")")
    sudo_home=""
    [[ -n "${SUDO_USER:-}" ]] && sudo_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)

    for candidate in \
        "$script_dir/../rtl8812au" \
        "${sudo_home:+$sudo_home/rtl8812au}" \
        "${HOME:-/root}/rtl8812au"
    do
        [[ -z "$candidate" ]] && continue
        if [[ -f "$candidate/dkms.conf" ]]; then
            printf '%s' "$candidate"
            return
        fi
    done

    # No existing source — pick a reasonable clone destination
    printf '%s/rtl8812au' "${sudo_home:-${HOME:-/root}}"
}

SRC_DIR=$(resolve_src_dir)

ensure_source() {
    if [[ -f "$SRC_DIR/dkms.conf" ]]; then
        log "using source at $SRC_DIR"
        return
    fi
    command -v git >/dev/null || die "git not installed and no source at $SRC_DIR"
    log "cloning $SRC_REPO -> $SRC_DIR"
    # Clone as the invoking user if possible, so ownership stays sensible
    if [[ -n "${SUDO_USER:-}" ]] && command -v sudo >/dev/null; then
        sudo -u "$SUDO_USER" git clone --depth 1 "$SRC_REPO" "$SRC_DIR"
    else
        git clone --depth 1 "$SRC_REPO" "$SRC_DIR"
    fi
}

remove_stale_dkms() {
    if dkms status 2>/dev/null | grep -q "^$OLD_PACKAGE/"; then
        log "removing stale $OLD_PACKAGE DKMS package"
        local versions v
        versions=$(dkms status | awk -F'[/,]' -v p="$OLD_PACKAGE" '$1==p{print $2}' | sort -u)
        while IFS= read -r v; do
            [[ -z "$v" ]] && continue
            dkms remove "$OLD_PACKAGE/$v" --all 2>/dev/null || true
        done <<< "$versions"
    fi
    if lsmod | awk '{print $1}' | grep -qx "$OLD_MODULE"; then
        log "unloading $OLD_MODULE module"
        rmmod "$OLD_MODULE" 2>/dev/null || warn "could not unload $OLD_MODULE (in use?)"
    fi
}

install_driver() {
    local version
    version=$(awk -F'"' '/^PACKAGE_VERSION=/{print $2}' "$SRC_DIR/dkms.conf")
    [[ -n "$version" ]] || die "could not read PACKAGE_VERSION from $SRC_DIR/dkms.conf"
    log "package: $PACKAGE_NAME/$version"

    if dkms status | grep -q "^$PACKAGE_NAME/$version"; then
        log "$PACKAGE_NAME/$version already registered — reinstalling cleanly"
        dkms remove "$PACKAGE_NAME/$version" --all 2>/dev/null || true
    fi

    log "dkms add $SRC_DIR"
    dkms add "$SRC_DIR"

    log "dkms install $PACKAGE_NAME/$version (this takes ~30s)"
    dkms install "$PACKAGE_NAME/$version"
}

load_module() {
    if lsmod | awk '{print $1}' | grep -qx "$MODULE_NAME"; then
        log "$MODULE_NAME already loaded — reloading"
        rmmod "$MODULE_NAME" 2>/dev/null || warn "could not unload $MODULE_NAME (in use?)"
    fi
    log "modprobe $MODULE_NAME"
    modprobe "$MODULE_NAME"
}

verify() {
    log "verifying..."
    local fail=0

    if lsmod | awk '{print $1}' | grep -qx "$MODULE_NAME"; then
        echo "  ok: module $MODULE_NAME loaded"
    else
        echo "  FAIL: module $MODULE_NAME not loaded" >&2
        fail=1
    fi

    if modinfo "$MODULE_NAME" 2>/dev/null | grep -qi "alias.*v0BDA"; then
        echo "  ok: module advertises Realtek (0BDA) USB IDs"
    else
        warn "no 0BDA aliases found — your adapter may not be supported"
    fi

    if ip -br link show | awk '{print $1}' | grep -qE "^wl"; then
        echo "  ok: wlan interface present:"
        ip -br link show | awk '$1 ~ /^wl/ {print "    " $0}'
    else
        warn "no wlan interface yet — try replugging the USB adapter"
        fail=1
    fi

    return $fail
}

main() {
    ensure_source
    remove_stale_dkms
    install_driver
    load_module
    sleep 1
    if verify; then
        log "done. scan with: nmcli device wifi list"
    else
        die "verification failed — check 'dmesg | tail -30' for details"
    fi
}

main "$@"
