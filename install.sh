#!/usr/bin/env bash
#
# install.sh - install ses-led-control into PREFIX (default: /usr/local)
#
# Copies bin/ses-led-control to $PREFIX/bin and, if present, the man page to
# $PREFIX/share/man/man1. Idempotent: re-running just overwrites the target.
#
# Usage:
#   sudo ./install.sh              # install to /usr/local
#   PREFIX=$HOME/.local ./install.sh   # user-local install (no root)
# ---------------------------------------------------------------------------
set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"
BINDIR="$PREFIX/bin"
MANDIR="$PREFIX/share/man/man1"
SRC_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

die() { printf '%s\n' "$*" >&2; exit 1; }

[[ -f "$SRC_DIR/bin/ses-led-control" ]] \
  || die "bin/ses-led-control not found next to install.sh"

install -d "$BINDIR" 2>/dev/null || die "Cannot create $BINDIR (try sudo, or set PREFIX)"
if ! install -m 0755 "$SRC_DIR/bin/ses-led-control" "$BINDIR/ses-led-control" 2>/dev/null; then
  die "Cannot write to $BINDIR. Re-run with sudo, or set PREFIX to a writable location."
fi
echo "Installed $BINDIR/ses-led-control"

if [[ -f "$SRC_DIR/man/ses-led-control.1" ]]; then
  if install -d "$MANDIR" 2>/dev/null \
     && install -m 0644 "$SRC_DIR/man/ses-led-control.1" "$MANDIR/ses-led-control.1" 2>/dev/null; then
    echo "Installed $MANDIR/ses-led-control.1"
  else
    echo "Note: could not install the man page to $MANDIR (skipped)." >&2
  fi
fi

echo "Done. Run: ses-led-control --help"
