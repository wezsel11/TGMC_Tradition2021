# TerraGov Marine Corps: Tradition 2021

This is the TerraGov Marine Corps codebase as it was on **2021-01-07**, revived to build and run on modern BYOND and to be hosted the same way as modern TGMC. Server hosts can run it instead of modern TGMC.

- **Gameplay** is kept as it was on 2021-01-07. No weapons, items or other content from later TGMC seasons were added.
- **Under the hood** it was brought up to date, mostly by backporting pieces of modern TGMC: BYOND 516 support, the build and deploy tooling, security and performance fixes, and interface improvements such as TGChat, the stat panel and TGUI windows.
- **Database:** it uses TGMC's own database schema (2.5), so a TGMC community's existing database (admins, ranks, bans, notes, playtime) works as it does with modern TGMC.

| | |
|---|---|
| BYOND | 516.1659 (also compiles on 513, 514 and 515) |
| Hosting | [DEPLOYING.md](DEPLOYING.md): tgstation-server, local Windows build, Docker |
| Changes | [CHANGELOG-TRADITION.md](CHANGELOG-TRADITION.md) |
| Bugs | Report them in this repository's issues, not on the official TGMC repository. |

## Original README


 This is a fork based off the July-2018 version of ColonialMarines. To see the original, GPL repo, go [here](https://github.com/MrStonedOne/cmhistory)

Code and other contributions are licensed under AGPL unless otherwise specified below

Artwork added after -this commit- is CC-BY-NC 3.0

Sprites added in the PR https://github.com/tgstation/TerraGov-Marine-Corps/pull/367 are licensed under CC-BY-NC 3.0
See commit 36b8db4952be79a79b28a6738889d9e9eb23b12a

Sprites added in the PR https://github.com/tgstation/TerraGov-Marine-Corps/pull/3877 are licensed under CC-BY-NC-SA 3.0
See commit e5d1580b14371ca4bfb8d2c4ae2f028b78cf4659

Sprites added in commit d407e97e26ee5e6bb1daf945a8eb3bd9a6b11976 are CC-BY-NC 3.0

All sounds added/remixed in the PR https://github.com/tgstation/TerraGov-Marine-Corps/pull/5261 are licensed under CC-BY-NC-SA 3.0

Sound added in PR https://github.com/tgstation/TerraGov-Marine-Corps/pull/5603 is taken from https://freesound.org/people/nicStage/sounds/127731/ (CC Attribution)

The TGS DMAPI API is licensed as a subproject under the MIT license.
