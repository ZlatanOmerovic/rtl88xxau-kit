---
name: Bug report
about: Something isn't working after running install.sh
title: "[bug] "
labels: bug
assignees: ''
---

## What happened

<!-- A clear description of the problem. Include exact commands run and what you expected vs. what occurred. -->

## Distro and kernel

- Distro: <!-- e.g. Debian 13 (trixie), Ubuntu 24.04 -->
- Kernel: <!-- output of `uname -r` -->
- DKMS version: <!-- output of `dkms --version` -->

## Adapter

<!-- Output of `lsusb | grep -i realtek` -->

```
```

## Diagnostic snapshot

Run `sudo ./diagnose.sh` and paste the contents of the generated `/tmp/wifi-diagnose-*.txt` file below, or attach it:

```
```

## Build log (if install.sh failed at the DKMS build step)

Paste tail of `/var/lib/dkms/realtek-rtl88xxau/<version>/build/make.log`:

```
```
