#!/usr/bin/env bash
# Capture a diagnostic snapshot for the Realtek USB wifi adapter.
# Writes to /tmp/wifi-diagnose-TIMESTAMP.txt.
# Run with sudo for full dmesg output.

OUT="/tmp/wifi-diagnose-$(date +%Y%m%d-%H%M%S).txt"

{
    echo "=== date ==="
    date
    echo

    echo "=== uname -a ==="
    uname -a
    echo

    echo "=== os-release ==="
    (cat /etc/os-release 2>/dev/null || echo "n/a") | head -10
    echo

    echo "=== lsusb (full) ==="
    lsusb
    echo

    echo "=== lsusb -d 0bda:0811 (adapter detail) ==="
    lsusb -d 0bda:0811 -v 2>/dev/null | head -25
    echo

    echo "=== ip -br link ==="
    ip -br link show
    echo

    echo "=== loaded wifi-related modules ==="
    lsmod | grep -iE "88XX|8812|8821|cfg80211|mac80211|^rtl|^rtw" || echo "(none)"
    echo

    echo "=== dkms status ==="
    dkms status 2>&1 || echo "(dkms not installed)"
    echo

    echo "=== modinfo 88XXau (filename, version, 0BDA aliases) ==="
    modinfo 88XXau 2>&1 | grep -iE "^filename|^version|0[bB][dD][aA]" | head -20 \
        || echo "(module not installed)"
    echo

    echo "=== /etc/modprobe.d entries mentioning rtl/rtw/88XX/8812 ==="
    grep -rE "8812|88XX|rtl88|rtw" /etc/modprobe.d/ /usr/lib/modprobe.d/ 2>/dev/null || echo "(none)"
    echo

    echo "=== rfkill ==="
    if command -v rfkill >/dev/null; then rfkill list; else echo "(rfkill not installed)"; fi
    echo

    echo "=== nmcli device ==="
    if command -v nmcli >/dev/null; then nmcli device status; else echo "(nmcli not installed)"; fi
    echo

    echo "=== dmesg tail (wifi/usb/rtl/8812/8821/firmware) ==="
    if dmesg 2>/dev/null | head -1 >/dev/null; then
        dmesg | grep -iE "usb|rtl|rtw|88XX|8812|8821|wlan|firmware|cfg80211" | tail -80
    else
        echo "(dmesg not readable as non-root — rerun with sudo)"
    fi
} > "$OUT" 2>&1

echo "wrote: $OUT"
