# Deploying TGMC "Tradition 2021"

This repository is the TerraGov Marine Corps codebase as of **2021-01-07**
(mini-silos, after the Hunt gamemode was removed), revived to build and run
on modern BYOND and deploy through the same pipeline as modern TGMC.

Gameplay content is kept as it was on 2021-01-07. Only engine, tooling, UI
infrastructure and database compatibility were updated, mostly by taking the
corresponding pieces from modern TGMC.

- Repository: `https://github.com/wezsel11/TGMC_Tradition2021`
- Branch: `main`

## Requirements

Pinned in `dependencies.sh`, identical to modern TGMC:

| Dependency | Version |
|---|---|
| BYOND | 516.1659 (also compiles on 513, 514 and 515) |
| rust_g | Linux: 3.11.0, built by `PreCompile.sh`. Windows: the committed `rust_g.dll` is 3.10.0, the same file modern TGMC ships. Both have every function the code uses. |
| Node | 22.11.0 (downloaded automatically by `tools/bootstrap`) |
| TGS DMAPI | 7.4.0 |
| Database | MariaDB or MySQL with TGMC's schema **2.5** (optional) |

## Deploying with tgstation-server

`.tgs4.yml` and `tools/tgs4_scripts/` are the same as modern TGMC's. Set up
the instance like a modern TGMC instance:

1. Create an instance and point its repository at the URL above, branch `main`.
2. Set the instance's BYOND version to 516.1659 (or a later 516).
3. Event scripts: copy `tools/tgs4_scripts/PreCompile.sh` (Linux) or
   `PreCompile.bat` (Windows) into the instance's `Configuration/EventScripts`.
   `PreSynchronize.*` (changelog compile on sync) is optional.
4. Static files: create `Configuration/GameStaticFiles/config` with this
   repository's `config/` folder, and an empty `Configuration/GameStaticFiles/data`
   (logs, player saves and the next map are kept there between deploys).
5. Deploy. `PreCompile` builds rust_g (Linux) and tgui, then TGS compiles
   `tgmc.dme`.

**Converting an existing modern TGMC instance:**
- Replace its `PreCompile` event script and its `GameStaticFiles/config` with
  this repository's, because the config defaults and maps differ. TGS never
  replaces an existing static folder by itself.
- Modern TGMC's `PreSynchronize` scripts work with this repository too.
- Use a fresh `data` folder rather than the live modern server's one. Player
  saves from modern TGMC load, but this build writes them back in its older
  format.

**Linux:**
- BYOND 516 needs glibc 2.34 or newer (Ubuntu 22.04+).
- `PreCompile.sh` installs missing build packages with apt. If the TGS user
  has no passwordless sudo, install them once yourself:

      sudo dpkg --add-architecture i386
      sudo apt-get update
      sudo apt-get install -y lib32z1 git pkg-config libssl-dev:i386 libssl-dev zlib1g-dev:i386 g++-multilib

- Modern TGMC's `PreCompile.sh` installs `libssl1.1:i386` unconditionally,
  which fails on Ubuntu 22.04+. This repository uses tgstation's package list
  instead.

## Admins

Out of the box, nobody is an admin. Pick one of:

- **Text files** (the default, `ADMIN_LEGACY_SYSTEM` on in `config/config.txt`):
  list admins as `ckey = Rank` in `config/admins.txt`. The ranks are in
  `config/admin_ranks.txt`, which is modern TGMC's rank file.
- **Database** (`ADMIN_LEGACY_SYSTEM` off): admins and ranks come from the
  database. Admins listed in `config/admins.txt` are still always loaded and
  protected, so only put your own host keys there.

Admin permissions are the same as modern TGMC's, including `RUNTIME`, `LOG`
and `POLLS`. A rank from a TGMC database gives the same powers here:
- `LOG`: server logs, the Log Viewer and player logs;
- `POLLS`: the poll panel;
- ranks in `config/admin_ranks.txt` override same-named database ranks.

`LOCALHOST_RANK` (in `config/config.txt`) only works for a client on the same
machine. It does not work through Docker's port mapping.

## Database

The code uses TGMC's database schema **2.5** (`SQL/tgmc-schema.sql`, the same
file as modern TGMC; migrations in `SQL/database_changelog.md`).

- For a new database, import `SQL/tgmc-schema.sql` and set the details in
  `config/dbconfig.txt` (`SQL_ENABLED`, address, port, database, login).
- An existing TGMC database at 2.5 works as it is. This build reads and
  writes it the way modern TGMC does: admin ranks keep all their flags, bans
  for `IC` and `Deadchat` are enforced, "Medical Officer" bans and playtime
  are stored under TGMC's "Medical Doctor", and notes record playtime.
- A database older than 2.5 must get the migrations from
  `SQL/database_changelog.md` first. Ranks need the 24-bit flag columns
  from 2.3.

Running without a database is possible (`SQL_ENABLED` off), but then bans,
notes, polls and playtime are not available. If the database goes down while
running, the server backs off and retries instead of freezing.

## Building locally

- `BUILD.cmd`: builds tgui and compiles `tgmc.dme`
- `bin/server.cmd`: builds and runs DreamDaemon on port 1337
- `bin/tgui-dev.cmd`: tgui development server

Built tgui bundles are committed in `tgui/public`, so a plain
`dm.exe tgmc.dme` also works without Node.

## Docker

    docker build -t tgmc .
    docker run -p 1337:1337 -v tgmc-data:/tgmc/data tgmc

The image is Ubuntu 22.04 with the BYOND version from `dependencies.sh`. It
builds through `tools/tgs4_scripts/PreCompile.sh`, so a successful image build
also means the TGS Linux path works. The config inside the image is this
repository's `config/`. To use your own, mount it with
`-v /path/to/config:/tgmc/config`. On Docker Desktop for Windows a
bind-mounted config is not read; copy it in with `docker cp` before starting
the container instead.

## License and source code

The code is AGPL-3.0. If you run a modified version, you must offer its
source to your players. Set `GITHUBURL` in `config/config.txt` (the in-game
"Github" button) to your fork.

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
| Unit tests (`-DCIBUILDING`) | tested, all pass |
| Local server on Windows, BYOND 516 | tested: boots, plays, vendors, closets, TGChat, stat panel, TGUI windows |
| TGS Windows path (`PreCompile.bat` + DM compile, clean checkout) | simulated, works |
| TGS Linux path (`PreCompile.sh` on Ubuntu 22.04, rust_g, tgui, DM compile, boot) | tested in Docker |
| Against a TGMC database (schema 2.5) | tested on Windows and Linux: rounds, players, connections, DB admins |
| Database down while running | tested: no freeze, backs off |
| Round end and restart (one player, with database) | tested |
| Full round with multiple players | **not tested** |
| GitHub Actions CI | tgui bundles and lint, Docker build |
