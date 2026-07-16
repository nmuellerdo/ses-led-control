#!/usr/bin/env bash
#
# dry-run-parity.sh - offline self-test for ses-led-control
#
# Sources the tool, injects a synthetic enclosure state, and asserts that:
#   * every <target> form (device, serial, sgN:slot) resolves to the right row,
#   * an unknown target is rejected,
#   * --dry-run prints exactly the sg_ses command line the real run would issue.
#
# No SES hardware, no root, no sg_ses/lsblk needed. Runs in CI.
#
# Usage: bash tests/dry-run-parity.sh
set -uo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=bin/ses-led-control disable=SC1091
source "$here/../bin/ses-led-control"

fail=0
check() { # <label> <got> <want>
  if [[ "$2" == "$3" ]]; then
    printf 'ok   %s\n' "$1"
  else
    printf 'FAIL %s: got [%s] want [%s]\n' "$1" "$2" "$3"
    fail=1
  fi
}

# --- synthetic state: two enclosures, three slots (one empty) ---------------
R_ENC=(/dev/sg3 /dev/sg3 /dev/sg5)
R_ET=(arr arr dev)
R_IDX=(0 7 2)
R_ID=(0 0 1)
R_FA=(0 1 0)
R_ST=(OK OK Not_installed)
DISK_AT["/dev/sg3 0"]="sda${SEP}WDC-SN-0001${SEP}WD40EFRX${SEP}3.6T${SEP}82.0"
DISK_AT["/dev/sg3 7"]="sdb${SEP}ZAB1234${SEP}ST8000${SEP}7.3T${SEP}SN02"

# --- target resolution ------------------------------------------------------
check "resolve /dev/sdX"  "$(resolve_target /dev/sda)"  "0"
check "resolve sdX"       "$(resolve_target sdb)"       "1"
check "resolve serial"    "$(resolve_target ZAB1234)"   "1"
check "resolve sgN:slot"  "$(resolve_target sg3:7)"     "1"
check "resolve /dev/sgN:slot" "$(resolve_target /dev/sg5:2)" "2"
if resolve_target does-not-exist >/dev/null 2>&1; then
  printf 'FAIL unknown target should not resolve\n'; fail=1
else
  printf 'ok   unknown target rejected\n'
fi

# --- dry-run command parity -------------------------------------------------
DRY_RUN=1
check "dry-run ident set" \
  "$(led_apply "${R_ENC[1]}" "${R_ET[1]}" "${R_IDX[1]}" ident --set)" \
  "sg_ses --index=arr,7 --set=ident /dev/sg3"
check "dry-run fault clear" \
  "$(led_apply "${R_ENC[2]}" "${R_ET[2]}" "${R_IDX[2]}" fault --clear)" \
  "sg_ses --index=dev,2 --clear=fault /dev/sg5"

# --- menu row validation (guards the interactive array subscript) -----------
check "menu_row plain"    "$(menu_row 1)" "1"
check "menu_row zero"     "$(menu_row 0)" "0"
check "menu_row base10"   "$(menu_row 02)" "2"
if menu_row 1x >/dev/null 2>&1;  then echo "FAIL menu_row accepted '1x'"; fail=1; else echo "ok   menu_row rejects '1x'"; fi
if menu_row 9 >/dev/null 2>&1;   then echo "FAIL menu_row accepted out-of-range"; fail=1; else echo "ok   menu_row rejects out-of-range"; fi
rm -f INJECTED
# shellcheck disable=SC2016  # single quotes are intentional: pass the literal payload, unexpanded
if menu_row '0,R_ENC[$(touch INJECTED)]' >/dev/null 2>&1; then echo "FAIL menu_row accepted injection"; fail=1; fi
if [[ -e INJECTED ]]; then echo "FAIL menu_row executed injected command"; fail=1; rm -f INJECTED; else echo "ok   menu_row: injection rejected, no code executed"; fi

if [[ $fail -eq 0 ]]; then
  echo "PASS: all parity checks green"
else
  echo "FAILURES above"
fi
exit "$fail"
