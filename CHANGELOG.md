# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-07-16

### Changed
- Recommended usage is now a single-file download: `curl` the script into any
  folder and run `sudo bash ses-led-control`. No install, no clone. TrueNAS
  SCALE mounts `/usr` read-only, so a system-wide install could not write there.

### Removed
- `install.sh` - there is no separate install step anymore.

## [0.1.0] - 2026-07-16

### Added
- Initial release.
- Slot overview across all SES enclosures, listing the installed disk
  (device, serial, model, size, firmware), the slot status, and the IDENT and
  FAULT LED state - including empty slots.
- Interactive menu: `<n>` toggles IDENT, `f<n>` toggles FAULT, `x` clears all
  LEDs, `r` reloads, `q` quits.
- Non-interactive CLI: `list`, `ident on|off <target>`, `fault on|off <target>`,
  `off-all`, `-h|--help`, `--version`.
- `<target>` resolution by block device (`/dev/sdX` or `sdX`), disk serial
  number, or `sgN:slot`.
- `--dry-run` prints the `sg_ses` commands instead of running them; works
  without root.
- Root is required only for operations that actually switch LEDs; `list`,
  `--help` and `--version` run unprivileged.
- Automatic handling of both `Array device slot` and `Device slot` element types.
- Offline parity self-test (`tests/dry-run-parity.sh`) and a shellcheck CI
  workflow.

[Unreleased]: https://github.com/nmuellerdo/ses-led-control/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/nmuellerdo/ses-led-control/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/nmuellerdo/ses-led-control/releases/tag/v0.1.0
