---
name: New adapter confirmed working
about: Help grow the tested-adapters compatibility table
title: "[tested] "
labels: tested-adapter
assignees: ''
---

Thank you for confirming your adapter works! Fill in the details below and I'll add it to the README.

## Adapter

- USB ID: <!-- e.g. 0BDA:0811 — output of `lsusb | grep -i realtek` -->
- Chipset: <!-- e.g. RTL8821AU -->
- Brand / model: <!-- e.g. TP-Link Archer T2U Plus, Alfa AWUS036ACH -->

## Environment

- Distro: <!-- e.g. Ubuntu 24.04, Debian 12 bookworm, Linux Mint 22 -->
- Kernel: <!-- output of `uname -r` -->
- Driver version installed: <!-- output of `dkms status | grep realtek-rtl88xxau` -->

## Verification

- [ ] `lsmod | grep 88XXau` shows the module loaded
- [ ] `ip -br link show` shows a `wl*` interface
- [ ] Successfully connected to a Wi-Fi network

## Notes (optional)

<!-- Anything unusual about setup, observed speeds, 5 GHz support, power management quirks, etc. -->
