# Contributing to rtl88xxau-kit

Contributions are welcome — especially those that grow the tested-adapter compatibility matrix or improve support for distros I don't personally have access to.

## Ways to contribute

### Report a tested adapter

If `install.sh` worked for you on an adapter or distro not yet listed in the README, please open a [New adapter confirmed working](../../issues/new?template=new_adapter.md) issue. Fill in the template (USB ID, chipset, distro, kernel) and I'll add your row to the compatibility table.

### Report a bug

If the installer fails, the module doesn't load, or the adapter doesn't come up, open a [Bug report](../../issues/new?template=bug_report.md) and attach the output of `sudo ./diagnose.sh` (produced at `/tmp/wifi-diagnose-*.txt`).

### Pull requests

PRs are welcome for:

- Support for additional adapters / chipsets
- Clearer error messages or improved diagnostics
- Extra distro coverage in CI (Linux Mint, Pop!_OS, Raspberry Pi OS, etc.)
- Kernel-version-specific patches when new kernel APIs break the build

## Development setup

1. Fork and clone the repo
2. Make your changes on a feature branch
3. Run `shellcheck install.sh uninstall.sh diagnose.sh` locally (CI will re-run it)
4. If your change touches install/uninstall behavior, test on a real Debian- or Ubuntu-based machine with an actual RTL88xxAU adapter
5. Open a PR with a clear description of what changed and why

## CI

Every PR runs these jobs:

| Job                  | What it checks                                                                |
| -------------------- | ----------------------------------------------------------------------------- |
| **ShellCheck**       | Lint all scripts (severity: warning)                                          |
| **bash -n**          | Syntax check inside `debian:bookworm-slim`, `debian:trixie-slim`, `ubuntu:22.04`, `ubuntu:24.04` |
| **DKMS availability**| Confirms `dkms` and `git` install cleanly on each target distro               |

All three must pass before merge.

## Code style

- Scripts use `#!/usr/bin/env bash` and `set -euo pipefail`
- Use the existing `log()` / `warn()` / `die()` helpers for output
- Keep the footprint small — this kit should stay readable in a single sitting
- Keep shell features portable enough to work on bash 5.x across Debian 12+ / Ubuntu 22.04+

## License

By submitting a pull request, you agree your contribution will be licensed under the [MIT License](LICENSE).
