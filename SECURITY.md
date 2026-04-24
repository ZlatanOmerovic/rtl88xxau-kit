# Security

## Reporting a vulnerability

If you believe you've found a security issue in `rtl88xxau-kit` — for example, a command injection, a path-traversal bug, or a privilege-escalation path in one of the scripts — please **do not** open a public issue. Instead:

- Use GitHub's private vulnerability reporting: **Security → Report a vulnerability** in this repo.
- Or email `zlomerovic@hotmail.com` with a minimal reproducer.

I aim to respond within 7 days and ship a fix promptly for legitimate issues.

## Trust model — what `install.sh` actually runs

This kit is a convenience wrapper around DKMS. Running `sudo ./install.sh` trusts the following chain **as root**:

1. **The aircrack-ng `rtl8812au` upstream source** (cloned from GitHub, or from a local path). DKMS compiles its `Makefile` as root and loads the resulting kernel module.
2. **GitHub's TLS and repo integrity** (for the default HTTPS clone).
3. **Your distro's `dkms` and `linux-headers-*` packages** (signed by Debian / Ubuntu / derivative).

If any link in that chain is compromised, running `install.sh` will execute attacker-controlled code as root. This is a property of *all* out-of-tree kernel modules installed via DKMS — not something this kit adds. It is nonetheless worth stating explicitly so you can make an informed decision.

## Caveats you should know about

### `SRC_REPO` accepts any URL

`install.sh` honors `SRC_REPO=<url>` for overriding the upstream driver source (useful for local forks). The URL is **not validated**. If you set `SRC_REPO` to a URL you don't control or don't trust, you will clone and run arbitrary code as root.

Guidance:

- Leave `SRC_REPO` unset unless you have a specific reason to change it.
- If you do override it, point it only at a repo you have audited or own.

### `SRC_DIR` reads whatever is on disk

If `SRC_DIR` (or one of its auto-detected locations) points to a directory you don't control, `install.sh` will build and load the driver from that source. Make sure no one else can write to `~/rtl8812au` (default perms on Debian-based distros do protect it via `0755` on `/home/<user>`, but worth double-checking if you share the machine).

### `diagnose.sh` output may contain identifying information

The `/tmp/wifi-diagnose-*.txt` file produced by `diagnose.sh` can contain:

- MAC address of your Wi-Fi adapter
- USB serial number of the adapter
- SSID names from recent `dmesg` entries
- Hostname (via `uname -a`)
- Loaded-module list and driver versions

As of the latest version the file is written with `umask 077` (mode `600`), so only the invoking user can read it locally. But if you **upload it to an issue, pastebin, or chat**, those identifiers are public. Redact before sharing if that concerns you.

## Known non-issues

The following have been reviewed and are intentional / acceptable:

- `actions/checkout@v4` is major-version pinned rather than SHA-pinned. Dependabot keeps it current.
- Docker Hub images (`debian:*-slim`, `ubuntu:*`) are tag-pulled, not SHA-pinned. CI jobs only run `bash -n` / `apt-get update`; no secrets are mounted.
- CI uses `pull_request` (not `pull_request_target`), so forked PRs run with the fork's limited token — no write access to this repo from untrusted PRs.

## Scope

Out of scope for this project's threat model:

- Compromise of the upstream aircrack-ng driver itself (report to [aircrack-ng/rtl8812au](https://github.com/aircrack-ng/rtl8812au) directly)
- Kernel-level bugs in the compiled module (report upstream)
- Compromise of your distro's package signing keys
