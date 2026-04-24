# wifi-setup

DKMS installer and diagnostics for Realtek USB wifi adapters based on the **RTL8811AU / RTL8812AU / RTL8821AU / RTL8814AU** chipsets (aircrack-ng `88XXau` driver family).

Built in response to a specific breakage on this machine, but written to be reusable on any Debian/Ubuntu system with a similar adapter.

---

## The problem this solves

After a kernel upgrade (`6.12.73` → `6.12.74+deb13+1`), the USB wifi adapter (`0BDA:0811`, an RTL8821AU chipset) stopped working. Symptoms:

- `lsusb` saw the adapter
- No `wlan*` interface was created
- No driver module bound to the device
- `modprobe 8812au` succeeded silently but the module's refcount stayed at zero

Root cause: the installed DKMS package (`rtl8812au/5.13.6-23`) came from a **stripped-down fork** — the `hal/rtl8821a/` directory was missing from the source tree, and the Makefile had `CONFIG_RTL8821A = n`. Flipping the flag failed to build (missing headers), and the compiled module didn't include `0BDA:0811` in its USB alias table, so udev never triggered a probe.

## The fix

Replace the stripped source with the full **aircrack-ng [`rtl8812au`](https://github.com/aircrack-ng/rtl8812au)** driver (package name `realtek-rtl88xxau`, currently v5.6.4.2~20230501). It builds as `88XXau.ko` and supports the entire AU family by default (8811/8812/8821/8814).

---

## Requirements

- Debian / Ubuntu with `dkms` installed
- Matching `linux-headers-$(uname -r)` for the running kernel
- Root privileges (sudo)
- Driver source at `/home/zlatan/rtl8812au` **or** network access so `install.sh` can clone from GitHub (override with `SRC_DIR=` / `SRC_REPO=`)

## Quick start

```bash
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

1. Ensures the driver source exists (clones from `SRC_REPO` if missing)
2. Removes any stale `rtl8812au` DKMS package (the stripped 8812A-only fork)
3. Unloads any leftover `8812au` kernel module
4. `dkms add` + `dkms install` for `realtek-rtl88xxau`
5. `modprobe 88XXau`
6. Verifies the module loaded, has `0BDA:0811` in its alias table, and created a `wl*` interface

Environment variables:

| Var         | Default                                          | Purpose                                      |
| ----------- | ------------------------------------------------ | -------------------------------------------- |
| `SRC_DIR`   | `/home/zlatan/rtl8812au`                         | Local path to driver source                  |
| `SRC_REPO`  | `https://github.com/aircrack-ng/rtl8812au.git`   | Upstream repo to clone from if `SRC_DIR` missing |

### `uninstall.sh`

Unloads `88XXau` and removes the `realtek-rtl88xxau` DKMS package. Does **not** delete the driver source tree.

```bash
sudo ./uninstall.sh
```

### `diagnose.sh`

Writes a full snapshot of the wifi subsystem state to `/tmp/wifi-diagnose-TIMESTAMP.txt`: USB device list, loaded modules, DKMS status, driver aliases, recent dmesg, modprobe.d config, nmcli state.

```bash
sudo ./diagnose.sh     # sudo recommended for full dmesg
```

Useful when the adapter breaks again in a new way, or for sharing state in a bug report.

---

## Kernel upgrades

DKMS auto-rebuilds the module against each new kernel on package upgrade, as long as:

- The source at `SRC_DIR` stays on disk
- The matching `linux-headers-<new-kernel>` is installed

If a rebuild fails, check:

```
/var/lib/dkms/realtek-rtl88xxau/<version>/build/make.log
```

Common causes: kernel API drift (the driver is from 2023; newer kernels sometimes need small patches), or missing headers.

## Kernel 6.14+

Starting with Linux 6.14, the in-tree `rtw88` driver supports these chipsets natively and is the preferred path. If you upgrade to 6.14+:

```bash
sudo ./uninstall.sh
```

…and rely on `rtw88` — no third-party DKMS needed.

---

## Verifying manually

```bash
lsusb | grep 0bda:0811                   # adapter present
lsmod | grep 88XXau                      # module loaded
modinfo 88XXau | grep 0BDA               # driver knows this device
ip -br link show | grep '^wl'            # wifi interface exists
nmcli device status                      # NetworkManager sees it
```

## Reference

- Adapter: Realtek `0BDA:0811` — RTL8821AU, USB 802.11ac dual-band
- Driver: [aircrack-ng/rtl8812au](https://github.com/aircrack-ng/rtl8812au)
- DKMS package name: `realtek-rtl88xxau`
- Built module: `88XXau`
