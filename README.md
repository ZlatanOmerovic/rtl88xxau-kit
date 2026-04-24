# rtl88xxau-kit

> DKMS installer + diagnostics for Realtek **RTL88xxAU** USB Wi-Fi adapters on Debian-based systems.

[![CI](https://github.com/ZlatanOmerovic/rtl88xxau-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/ZlatanOmerovic/rtl88xxau-kit/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Tested on Debian 13](https://img.shields.io/badge/tested-Debian_13_trixie-a81d33)
![DKMS compatible](https://img.shields.io/badge/DKMS-compatible-success)

A single-command restore for the Realtek AU-family USB Wi-Fi adapters (RTL8811AU / 8812AU / 8821AU / 8814AU) on Debian, Ubuntu, and their derivatives. Replaces any stale or stripped-down DKMS source with the full **aircrack-ng `realtek-rtl88xxau`** driver, rebuilds via DKMS, and verifies the adapter came up.

---

## Why this exists

On this machine, a routine kernel upgrade (`6.12.73` → `6.12.74+deb13+1`) silently broke an RTL8821AU adapter (USB ID `0BDA:0811`). The old DKMS source (`rtl8812au/5.13.6-23`) turned out to be a stripped-down fork — the `hal/rtl8821a/` directory was missing from the source tree and `CONFIG_RTL8821A = n` in the Makefile. The compiled module didn't include `0BDA:0811` in its USB alias table, so udev never triggered a probe on replug. No `wlan*` interface appeared. The adapter looked dead.

The fix is to swap the stripped source for the **aircrack-ng** driver ([`aircrack-ng/rtl8812au`](https://github.com/aircrack-ng/rtl8812au)), which builds as `88XXau.ko` with the entire AU family enabled by default. This kit automates that swap idempotently.

---

## Supported adapters

| Chipset    | Example USB IDs                          |
| ---------- | ---------------------------------------- |
| RTL8811AU  | `0BDA:A811`, `0BDA:0811` (some revs)     |
| RTL8812AU  | `0BDA:8812`, `0BDA:881A`, `0BDA:881B`    |
| RTL8821AU  | `0BDA:0811`, `0BDA:0821`                 |
| RTL8814AU  | `0BDA:8813`                              |

The upstream driver covers many vendor-branded adapters using these chipsets (TP-Link Archer T-series, Alfa AWUS036AC/ACH, Edimax EW-7822UAC, D-Link DWA-182, etc.). A full list is in the [aircrack-ng driver README](https://github.com/aircrack-ng/rtl8812au).

## Tested environments

| Distro               | Kernel                     | Adapter                       | Status |
| -------------------- | -------------------------- | ----------------------------- | ------ |
| Debian 13 (trixie)   | `6.12.74+deb13+1-amd64`    | `0BDA:0811` (RTL8821AU)       | OK     |

Confirmed your adapter works on a distro not listed here? Open an issue using the **new_adapter** template — I'll add it to the table.

---

## Requirements

- A Debian-based distro (Debian, Ubuntu, Linux Mint, Pop!_OS, etc.)
- `dkms` installed (`apt install dkms`)
- Kernel headers for your running kernel (`apt install linux-headers-$(uname -r)`)
- Root privileges (sudo)
- Either the driver source already on disk **or** network access so `install.sh` can clone it from GitHub

## Quick start

```bash
git clone https://github.com/ZlatanOmerovic/rtl88xxau-kit.git
cd rtl88xxau-kit
sudo ./install.sh
```

Then scan and connect:

```bash
nmcli device wifi list
nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD"
```

---

## Scripts

### `install.sh`

Idempotent. Safe to re-run after kernel upgrades, failed builds, or on a fresh system.

What it does:

1. Ensures the aircrack-ng driver source is available (clones it from `SRC_REPO` if missing)
2. Removes any stale `rtl8812au` DKMS package (the stripped 8812A-only fork)
3. Unloads any leftover `8812au` kernel module
4. `dkms add` + `dkms install` for `realtek-rtl88xxau`
5. `modprobe 88XXau`
6. Verifies the module loaded, advertises your adapter's USB ID, and created a `wl*` interface

Environment variables:

| Variable   | Default                                          | Purpose                                      |
| ---------- | ------------------------------------------------ | -------------------------------------------- |
| `SRC_DIR`  | auto-detected (see below)                        | Local path to driver source                  |
| `SRC_REPO` | `https://github.com/aircrack-ng/rtl8812au.git`   | Upstream repo to clone if `SRC_DIR` missing  |

**`SRC_DIR` auto-detection order**:

1. `SRC_DIR=` env var if set
2. `<script-dir>/../rtl8812au` (side-by-side with `rtl88xxau-kit`)
3. `$SUDO_USER`'s home directory (`~/rtl8812au`)
4. `$HOME/rtl8812au`
5. If none exist — clones into `$SUDO_USER`'s home (or `$HOME` if not sudo'd)

### `uninstall.sh`

Unloads `88XXau` and removes the `realtek-rtl88xxau` DKMS package. **Does not** delete the driver source tree (safe; you may want to reinstall later).

```bash
sudo ./uninstall.sh
```

### `diagnose.sh`

Writes a full snapshot of the Wi-Fi subsystem state to `/tmp/wifi-diagnose-TIMESTAMP.txt`: USB device list, loaded modules, DKMS status, driver aliases, recent dmesg, modprobe.d config, nmcli state.

```bash
sudo ./diagnose.sh   # sudo recommended for full dmesg
```

Useful when the adapter breaks again in a new way, or for attaching to a bug report.

---

## Kernel upgrades

DKMS auto-rebuilds the module against each new kernel at `apt upgrade` time, as long as:

- The source at `SRC_DIR` stays on disk
- The matching `linux-headers-<new-kernel>` package is installed

If a rebuild fails, check:

```
/var/lib/dkms/realtek-rtl88xxau/<version>/build/make.log
```

Common causes: kernel API drift (the upstream driver is from 2023; newer kernels sometimes need small patches), or missing headers.

## Kernel 6.14+ — time to retire this kit

Starting with Linux **6.14**, the in-tree `rtw88` driver supports these chipsets natively and is the preferred path. If you upgrade to 6.14+:

```bash
sudo ./uninstall.sh
```

…and rely on `rtw88` — no third-party DKMS needed.

---

## Verifying manually

```bash
lsusb | grep -i realtek                  # adapter present
lsmod | grep 88XXau                      # module loaded
modinfo 88XXau | grep -i 0BDA            # driver knows your USB ID
ip -br link show | grep '^wl'            # wifi interface exists
nmcli device status                      # NetworkManager sees it
```

---

## Contributing

Contributions welcome — especially tested-adapter reports and distro coverage. See [CONTRIBUTING.md](CONTRIBUTING.md) for how to report bugs, add tested adapters, and open pull requests.

All scripts are linted with `shellcheck` in CI across Debian 12, Debian 13, Ubuntu 22.04, and Ubuntu 24.04.

## License

[MIT](LICENSE) © Zlatan Omerović

## Reference

- Driver: [aircrack-ng/rtl8812au](https://github.com/aircrack-ng/rtl8812au)
- DKMS package name: `realtek-rtl88xxau`
- Built module: `88XXau`
