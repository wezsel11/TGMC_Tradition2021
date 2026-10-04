# Deploying TGMC "Tradition 2021"

This branch is the TerraGov Marine Corps codebase as of **2021-01-07**
(mini-silos, after the Hunt gamemode was removed), revived to build and run
on modern BYOND and deploy through the same pipeline as modern TGMC.

Gameplay content is kept as it was on 2021-01-07. Only engine, tooling and
UI infrastructure were updated, mostly by taking the corresponding pieces
from modern TGMC.

## Requirements

Pinned in `dependencies.sh`, identical to modern TGMC:

| Dependency | Version |
|---|---|
| BYOND | 516.1659 (also compiles on 513, 514 and 515) |
| rust_g | 3.11.0 (Linux: built by `PreCompile.sh`; Windows: `rust_g.dll` in the repo) |
| Node | 22.11.0 (downloaded automatically by `tools/bootstrap`) |
| TGS DMAPI | 7.4.0 |

## Deploying with tgstation-server

The repository contains `.tgs4.yml` and `tools/tgs4_scripts/` from modern
TGMC, so an instance pointed at this repository and branch should deploy
like modern TGMC:

1. Point the instance's repository at this repo and branch.
2. Set the instance's BYOND version to 516.1659 (or later 516).
3. Deploy. `PreCompile` builds rust_g (Linux) and tgui, then TGS compiles
   `tgmc.dme`.

On Linux, BYOND 516 needs glibc 2.34 or newer (Ubuntu 22.04+). `PreCompile.sh`
installs missing build packages with apt; if the TGS user has no passwordless
sudo, install them once yourself:

    sudo apt-get install -y lib32z1 git pkg-config libssl-dev:i386 libssl-dev zlib1g-dev:i386 g++-multilib

(Modern TGMC's `PreCompile.sh` installs `libssl1.1:i386` unconditionally, which
fails on Ubuntu 22.04+; this repository uses tgstation's package list instead.)

`config/` and `data/` are static files; on first deploy `config/` is
populated from this repository. Use this repository's `config/` rather
than a modern TGMC config. Modern config keys unknown to this codebase are
only logged and ignored, but defaults and maps differ.

### Database

The code expects schema **2.0**; modern TGMC is at **2.5**. Everything
between 2.0 and 2.5 is additive or widens column types (see
`SQL/database_changelog.md` on modern TGMC), and no column used in 2021 was
removed, so this code works against a current TGMC database. On start it
logs a schema mismatch warning (2.5 vs 2.0) and continues. Tested against
MariaDB 10.11 with the modern TGMC schema, on Windows and Linux: connection,
round start, end and shutdown records, player and connection logging, and
admins loaded from the database.

Running without a database is possible (`SQL_ENABLED` off), but then bans,
notes and player data from the database are not available.

## Building locally

- `BUILD.cmd`: builds tgui and compiles `tgmc.dme`
- `bin/server.cmd`: builds and runs DreamDaemon on port 1337
- `bin/tgui-dev.cmd`: tgui development server

Built tgui bundles are committed in `tgui/public/`, so a plain
`dm.exe tgmc.dme` also works without Node.

## Docker

    docker build -t tgmc .
    docker run -p 1337:1337 -v tgmc-data:/tgmc/data tgmc

The image is Ubuntu 22.04 with the BYOND version from `dependencies.sh`. It
builds through `tools/tgs4_scripts/PreCompile.sh`, so a successful image build
also means the TGS Linux path works. Mount your own config with
`-v /path/to/config:/tgmc/config`.

## BYOND 516 notes

BYOND 516 replaced the client's Internet Explorer browser with WebView2.
The 2021 UI code was adapted the way modern TGMC handles it:

- `tgui/public/tgui.html`: detects WebView2, uses `cef_to_byond()` instead of
  `byond://` navigation, sends `ready` at the end of `<body>`, maps
  `msSaveBlob` to the "Save as" file picker, and uses `byondstorage`
  (`hubStorage`) so chat settings persist
- `interface/skin.dmf`: chat panes switch through `legacy_output_selector`
- library calls use `call_ext()` on 515+

## Verification status

| | Status |
|---|---|
| Compiles on BYOND 513, 514, 515 and 516 (0 errors, 0 warnings) | tested |
| Local server on Windows, BYOND 516 | tested: boots, plays, vendors, closets, TGChat |
| TGS Windows path (`PreCompile.bat` + DM compile, clean checkout) | simulated, works |
| TGS Linux path (`PreCompile.sh` on Ubuntu 22.04, rust_g, tgui, DM compile, boot) | tested in Docker |
| Against a current TGMC database (schema 2.5) | tested on Windows and Linux: rounds, players, connections, DB admins |
| Round end and restart (one player, with database) | tested |
| Full round with multiple players | **not tested** |
| GitHub Actions CI | not updated |
