# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.2] - 2026-07-16

### Fixed
- Interactive menu: the row selection is now validated as a plain decimal before
  it is used as an array index. The index was evaluated in an arithmetic context,
  which meant input like `0,R_ENC[$(cmd)]` could run `cmd` as root; malformed
  input such as `08` or `1x` crashed the whole menu; and a leading zero was read
  as octal (`010` toggled slot 8, not row 10). All three are fixed.
- `ident`, `fault` and `off-all` now fail with a clear message when no enclosure
  slots can be read (previously `--dry-run` without root gave a misleading
  "Target not found" or silently did nothing).
- `discover_enclosures` ignores `lsscsi` lines without a real `/dev/sg*` node and
  hints at the sg kernel module instead of a generic error.

### Removed
- The undocumented `menu` command alias, so the interface matches the docs.

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
- Man page (`man/ses-led-control.1`) and a `/usr/local` installer (`install.sh`,
  removed again in 0.1.1).

[Unreleased]: https://github.com/nmuellerdo/ses-led-control/compare/v0.1.2...HEAD
[0.1.2]: https://github.com/nmuellerdo/ses-led-control/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/nmuellerdo/ses-led-control/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/nmuellerdo/ses-led-control/releases/tag/v0.1.0
