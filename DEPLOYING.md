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

`config/` and `data/` are static files; on first deploy `config/` is
populated from this repository. Use this repository's `config/` rather
than a modern TGMC config. Modern config keys unknown to this codebase are
only logged and ignored, but defaults and maps differ.

### Database

The code expects schema **2.0**; modern TGMC is at **2.5**. Everything
between 2.0 and 2.5 is additive or widens column types (see
`SQL/database_changelog.md` on modern TGMC), and no column used in 2021 was
removed, so this code should work against a current TGMC database. On
start it logs a schema mismatch warning (2.0 vs 2.5) and continues.

Running without a database is possible (`SQL_ENABLED` off), but then bans,
notes and player data from the database are not available.

## Building locally

- `BUILD.cmd`: builds tgui and compiles `tgmc.dme`
- `bin/server.cmd`: builds and runs DreamDaemon on port 1337
- `bin/tgui-dev.cmd`: tgui development server

Built tgui bundles are committed in `tgui/public/`, so a plain
`dm.exe tgmc.dme` also works without Node.

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
| TGS Linux path (`PreCompile.sh`) | **not tested**, identical to modern TGMC |
| Against a current TGMC database | **not tested**, schema analysis only |
| Full round with multiple players, round end and restart | **not tested** |
| GitHub Actions CI | not updated |
