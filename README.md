# ses-led-control

Control the **Identify (locate)** and **Fault** LEDs of disk slots in enclosures
that speak **SES** (SCSI Enclosure Services) — e.g. Supermicro / LSI expander
backplanes attached to an HBA in IT mode. Built for Linux in general, with
TrueNAS SCALE as the primary use case.

TrueNAS SCALE ships `sg_ses` but has **no built-in way** to drive enclosure
locate/fault LEDs — this fills that gap with the tooling already on the system.

[![shellcheck](https://github.com/nmuellerdo/ses-led-control/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/nmuellerdo/ses-led-control/actions/workflows/shellcheck.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-informational.svg)](LICENSE)

It lists **every** slot of every SES enclosure (including empty ones), maps the
installed disk to its slot via the SAS address, shows the slot status and the
IDENT/FAULT LED state, and lets you toggle those LEDs — interactively or from a
one-shot command.

```text
#   ENCL:SLOT   STATUS       DEV      SERIAL             MODEL                SIZE     FW       IDENT  FAULT
----------------------------------------------------------------------------------------------------------------
0   sg3:0       populated    sda      WDC-SN-0001        WD40EFRX             3.6T     82.0     off    off
1   sg3:7       populated    sdb      ZAB1234            ST8000               7.3T     SN02     off    ON
2   sg5:2       empty        -        -                  -                    -        -        ON     off

number = toggle IDENT | f<n> = toggle FAULT | x = all LEDs off | r = reload | q = quit
>
```

## What it does

- Enumerates SES enclosures with `lsscsi -g`.
- Maps disks to slots by SAS address, using the enclosure **Additional Element
  Status** (`aes`) page and each disk's `sas_address` in sysfs.
- Reads slot status and LED state from the **Enclosure Status** (`es`) page.
- Switches LEDs with `sg_ses --index=<type>,<idx> --set|--clear=ident|fault`.
- Handles both the `Array device slot` and `Device slot` element types
  automatically.

It does **not** write to disks and performs no destructive action beyond
changing an LED. LED control depends entirely on the backplane's SES support —
if the hardware can't do it, this tool can't make it.

## Requirements

- **root** to switch LEDs (`list`, `--help`, `--version` run unprivileged).
- [`sg3-utils`](https://sg.danny.cz/sg/sg3_utils.html) — provides `sg_ses`
- `util-linux` — provides `lsblk`
- `lsscsi`
- `awk`

On Debian/Ubuntu/TrueNAS SCALE:

```sh
sudo apt-get install -y sg3-utils util-linux lsscsi
```

## Run

It's a single self-contained script — no install, no clone. Download just the
script into any folder and run it with `bash`. This is also the way to use it on
**TrueNAS SCALE**, where `/usr` (and `/usr/local/bin`) is mounted read-only:

```sh
curl -fsSLO https://raw.githubusercontent.com/nmuellerdo/ses-led-control/main/bin/ses-led-control
sudo bash ses-led-control
```

This starts the interactive menu. Re-run the same `curl` any time to update to
the latest version.

> Command blocks in this README contain no `#` comments on purpose: the TrueNAS
> SCALE root shell is zsh, which passes pasted `# …` along as arguments.

## Usage

> Examples below call `ses-led-control` for brevity. If you downloaded the
> script, run it with `bash ses-led-control …` from that folder (prefix `sudo`
> to switch LEDs).

### Interactive

```sh
sudo bash ses-led-control
```

Then, at the prompt:

| Input   | Action                         |
| ------- | ------------------------------ |
| `<n>`   | toggle the IDENT LED of row n  |
| `f<n>`  | toggle the FAULT LED of row n  |
| `x`     | clear all IDENT and FAULT LEDs |
| `r`     | reload the table               |
| `q`     | quit                           |

### Non-interactive (CLI)

```sh
ses-led-control list
sudo ses-led-control ident on <target>
sudo ses-led-control ident off <target>
sudo ses-led-control fault on <target>
sudo ses-led-control fault off <target>
sudo ses-led-control off-all
ses-led-control --version
ses-led-control --help
```

`list` prints the table and exits (no root needed); `ident`/`fault` switch the
respective LED; `off-all` clears every IDENT and FAULT LED.

`--dry-run` prints the `sg_ses` commands instead of running them, and works
without root — handy for scripts and for confirming which slot you're about to
light up:

```sh
$ ses-led-control --dry-run fault on sg3:7
sg_ses --index=arr,7 --set=fault /dev/sg3
```

### Targets

`<target>` can be any of:

| Form       | Example    | Meaning                               |
| ---------- | ---------- | ------------------------------------- |
| `/dev/sdX` | `/dev/sdf` | a block device                        |
| `sdX`      | `sdf`      | a block device (short form)           |
| `<serial>` | `ZAB1234`  | a disk serial (as shown in the table) |
| `sgN:slot` | `sg3:7`    | enclosure device + slot index         |

Example — locate a disk by serial, then mark another as faulty:

```sh
sudo ses-led-control ident on ZAB1234
sudo ses-led-control fault on /dev/sdf
```

## IDENT vs. FAULT

- **IDENT** (a.k.a. *locate* / *identify*) is the LED you turn on yourself to
  physically find a drive — "which bay is `sdf`?". It usually shows as blue or a
  steady/blinking white LED, depending on the backplane.
- **FAULT** marks a slot as failed. Some setups drive it automatically (e.g. a
  ZFS failure); you can also set it by hand to flag a disk for replacement. It is
  typically red/amber.

Both are just SES element bits — this tool sets or clears them. What color/blink
pattern the backplane shows is up to the hardware.

## Safety

- This switches LEDs on **real hardware** and needs root to do so.
- It never writes to disks; the only state it changes is LED state.
- `--dry-run` lets you preview the exact `sg_ses` invocation first.
- `off-all` is a safe reset if you lose track of what's lit.

## Troubleshooting

### Empty table / "no slots read"

Reading the enclosure status pages usually requires root. Run `list` as root:

```sh
sudo ses-led-control list
```

### "No SES enclosure found"

`lsscsi -g` reports no enclosure. Your backplane may not expose SES, or the HBA
may be in RAID (not IT/HBA) mode. Confirm with:

```sh
lsscsi -g | grep -i enclosu
```

### The `sg_ses -p es` parser and version differences

The slot state is parsed from the human-readable output of `sg_ses -p es`. The
field **names** in that output can vary slightly between `sg3-utils` versions,
so the parser keys on these tokens (in `bin/ses-led-control`, function
`build_slots`):

- element types `Element type: Array device slot` / `Device slot`
- per-slot markers `Overall descriptor:` and `Element <n> descriptor:`
- the `status:` field
- `Ident=<0|1>`
- `Fault reqstd=<0|1>`

A typical descriptor looks like this:

```text
    Element 7 descriptor:
      Predicted failure=0, Disabled=0, Swap=0, status: OK
      OK=1, Reserved device=0, Hot spare=0, Cons check=0
      ...
      Enclosure bypassed B=0, Ready to insert=0, RMV=0, Ident=0
      Report=0, App client bypassed B=0, Fault sensed=0, Fault reqstd=0
```

If your `sg_ses` labels these differently, the table columns for STATUS / IDENT
/ FAULT may come up blank or wrong. To adapt, run:

```sh
sudo sg_ses -p es /dev/sgN
```

and adjust the matching patterns in `build_slots` (the `/Ident=/`,
`/Fault reqstd=/` and `status:` rules) to match your output. If you hit this,
please open an issue and paste the output of `sg_ses -p es /dev/sgN` — that's
exactly what's needed to widen the parser.

## Development

Run the linter and the offline self-test (no hardware needed):

```sh
shellcheck -x --shell=bash bin/ses-led-control tests/*.sh
bash tests/dry-run-parity.sh
```

The self-test sources the tool, injects a synthetic enclosure state, and asserts
that target resolution and the `--dry-run` command output are correct. Both run
in CI on every push.

## Uninstall

Nothing is installed system-wide — just delete the script:

```sh
rm -f ses-led-control
```

## Acknowledgements

- Developed and tested on **TrueNAS SCALE** against a Supermicro SC846P chassis
  with an LSI SAS3x36 expander backplane.
- Written with the help of **Claude** (Anthropic), using Claude Code.

## License

[MIT](LICENSE) © 2026 Niclas Müller
