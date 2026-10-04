# Changelog: TGMC Tradition 2021

Changes made to the TerraGov Marine Corps codebase of 2021-01-07 to run it on
modern BYOND and deploy it like modern TGMC. Gameplay content is unchanged: no
weapons, items or other content from later seasons were added.

See `DEPLOYING.md` for how to host it.

## Runs on modern BYOND

- Compiles on BYOND 513, 514, 515 and 516 (0 errors, 0 warnings)
- Fixed BYOND 515/516 incompatibilities: library calls (`call_ext`), list
  sorting, number-keyed lists, switch ranges and static initializers
- Original gameplay behaviour preserved where old code relied on old BYOND quirks

## Interface on BYOND 516

- UI windows (vendors, closets, consoles) work in BYOND 516's new browser
  instead of showing a white screen
- tgui upgraded from v3 to 4.3
- New chat (TGChat) with tabs and filters, with the old chat as fallback
- Chat settings are saved between sessions
- "Save chat log" works again

## Deployable like modern TGMC

- TGS integration updated to DMAPI 7.4.0
- Build system from modern TGMC (`BUILD.cmd`, Node 22, Yarn 4); tgui is built
  from source
- rust_g updated from 0.4.5 to 3.x
- TGS deploy config (`.tgs4.yml`, PreCompile scripts) and `dependencies.sh`
  matched to modern TGMC
- Removed obsolete TGS3, BSQL and extools files
- Linux deploy fixed for BYOND 516: `PreCompile.sh` no longer installs
  `libssl1.1:i386` (missing on Ubuntu 22.04+, which BYOND 516 needs) and no
  longer runs apt as root on every deploy
- Dockerfile rewritten: Ubuntu 22.04, BYOND 516, builds through `PreCompile.sh`
- Works against the current TGMC database (schema 2.5)

## Security fixes from modern TGMC

- Mentors could edit, empty or shuffle any list through crafted View Variables
  links; VV now requires the VAREDIT permission
- BYOND's client-side debug VV is blocked, as it ignored VV read protections
- The admin href token is hidden from View Variables
- Reading player notes through admin links requires the BAN permission, as
  modern TGMC (mentors could read them)
- The list of variables that must never be copied is protected from editing
- Fixed the round-end SQL query and null values in death records
- Fixed HTML injection through carbon copies
- Non-ASCII text is rejected in OOC, flavor text, supply requests and command
  announcements; supply request reasons are capped at 250 characters
