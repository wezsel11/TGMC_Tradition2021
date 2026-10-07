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
- Uses TGMC's own database schema (2.5); see "TGMC database compatibility" below

## Security fixes from modern TGMC

- Mentors could edit, empty or shuffle any list through crafted View Variables
  links; VV now requires the VAREDIT permission
- BYOND's client-side debug VV is blocked, as it ignored VV read protections
- The admin href token is hidden from View Variables
- Reading player notes through admin links requires the BAN permission, as
  modern TGMC (mentors could read them)
- The list of variables that must never be copied is protected from editing
- Fixed the round-end SQL query; null area names no longer break death records
- Fixed HTML injection through carbon copies
- Non-ASCII text is rejected in OOC, flavor text, supply requests and command
  announcements; supply request reasons are capped at 250 characters

## Rounds and maps

- The default game mode is Distress Signal (it fell back to Extended)
- Vapor Processing, Desert Outpost, Whiskey Outpost and Marine HQ are out of
  the map rotation; a saved next map that is no longer in the rotation is
  never loaded
- Larva queue, as modern TGMC: dead players queue fairly for a new larva, see
  their position in the Status tab, keep their place while on the respawn
  timer, and spawn prompts time out after 20 seconds
- Round end statistics show where larvas came from

## Interface

- HTML stat panel, as modern TGMC, with an object tab when you Alt-click a tile
- TGUI Say: a small input bar for say, radio, me, OOC and LOOC. Tab changes
  the channel, Up and Down go through the last messages, and the bar can be
  dragged. It can be turned off in the game preferences
- TGUI input boxes for text and number prompts, with a preference to go back
  to the old popups
- Hive Status and the health analyzer open in TGUI windows, showing the same
  information as before
- Chat reliability layer: messages are no longer lost or duplicated
- Balloon alerts: xeno ability messages ("wait 3 seconds", "not enough
  plasma") float above your head instead of filling chat
- BYOND 516: windows scale with the monitor DPI, old windows use proper HTML,
  chat logs can be saved, and floating overlays layer correctly
- Smoother movement and runechat

## Controls and quality of life

- Xeno abilities have default keys, shown on the ability buttons; ability
  tooltips explain what they do
- Pheromones and resin structures are picked from a radial menu, and the
  pheromone keys always work
- Bags: clicking an open bag closes it, a bag opens when an item doesn't fit,
  and Ctrl-click takes out the first item
- Alternate quick equip (Shift+E) with its own preferred slot; "Inside Belt"
  can be chosen as a preferred slot
- New keybinds: toggle suit light, interact with the other hand, toggle
  automatic magazine ejection (also a Weapons verb)
- "Hotkeys" verb in the Preferences tab
- Short labels on autoinjectors, hyposprays and pill bottles
- Checking yourself for injuries shows bleeding
- Vendors say why they refuse you
- Requisitions: search field, and identical crates are grouped in orders
- Less chat spam when shooting objects and walls
- Ghosts see reagents on examine, can Shift-click examine while following,
  and their window only flashes for offers to rejoin the round
- The health analyzer's {B} and {T} untreated markers were shown for treated
  limbs; they now match the legend

## Performance

- Faster overlays, icon2html, INVOKE_ASYNC, element ids and item action lists,
  as modern TGMC
- Master controller and garbage collector improvements, and hard-delete
  fixes, from modern TGMC
- Runechat runs on the timer subsystem
- Sounds only check players on the same z-level

## Administration and logging

- JSON logging: every categorized log line is also written to
  `game.log.json` in the round log folder (one JSON object per line); the text
  logs are unchanged
- "Log Viewer" admin verb (LOG permission): the round's logs in a TGUI window, with category
  filters and search
- Admin links in human examine, observer Ctrl+Shift-click for admins, and
  quick create paths

## Reliability

- A down database no longer freezes the server: Connect() reset its failure
  counter on every call, so every query made a new blocking connection
  attempt. It now backs off after 5 failures, as modern TGMC
- The chat no longer crashes when audio playback fails
- Text prompts that were missing their user work again

## TGMC database compatibility

A TGMC community's own database (admins, ranks, bans, notes, playtime) works
the same as with modern TGMC.

- `SQL/` holds TGMC's schema 2.5 and its changelog; the code reports 2.5, so
  there is no schema mismatch warning on a TGMC database
- Admin permissions match modern TGMC: the RUNTIME, LOG and POLLS
  permissions exist, ranks are saved without losing them, EVERYTHING has the
  same value, server logs and the Log Viewer need LOG, and the poll panel
  needs POLLS
- `config/admin_ranks.txt` is modern TGMC's rank file
- `config/admins.txt` no longer makes about 100 /tg/station staff keys
  protected admins on every server (it is now only a commented example)
- Bans for IC and Deadchat (made on modern TGMC) are enforced, and can be
  given from the ban panel
- The "Medical Officer" job is stored as TGMC's "Medical Doctor" for job bans
  and playtime, so both work across servers
- Death records are written again: the query had unbound values since 2021
  (TGMC #5883)
- Blackbox feedback no longer uses `INSERT DELAYED`, which fails on InnoDB
  (TGMC #16416)
- Notes record the player's living playtime, as modern TGMC

## Fixes from the final review

- Hive Status no longer keeps updating for a ghost who respawns as a marine
  (it showed xeno locations live); it uses modern TGMC's hive window state
- TGS: the event handler is connected, so admins see deploy and restart
  notices; the changelog script also accepts the one-argument form that the
  TGS PreSynchronize scripts use
- Docker: legacy instrument sounds are deployed and the boiler cursor is
  compiled in
- All unit tests pass again; test rounds start without players, as modern TGMC
- GitHub: inherited automation for the official repository was removed; CI
  checks the tgui bundles, lint and the Docker build
- `PreCompile.sh` installs missing build packages more reliably
- README, DEPLOYING.md and CONTRIBUTING.md describe this release for hosts
