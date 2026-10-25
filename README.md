# BetterUI_Cata

Experimental UI addon for **original World of Warcraft Cataclysm 4.3.4,
build 15595** (Interface 40300, Lua 5.1). Cataclysm Classic 4.4.x is not supported.

Phase 1 provides bootstrap, profiles, English/Russian localization, LoadOnDemand
options and an editor for two addon-owned frames. Gameplay replacements are not
implemented. Static/model checks do not establish in-game compatibility;
client status remains **UNTESTED**.

## Install

Copy both directories from `addons/` into the client's `Interface/AddOns/`:

- `BetterUI`
- `BetterUI_Options` (loaded on demand; requires BetterUI)

Enable `/console scriptErrors 1`, reload, and use `/betterui diag`, `/betterui`,
and `/betterui edit`. Back up saved settings before testing experimental builds.

## Source and attribution

This public repository contains the distributable addon files and their notices.
Development tools, Registry, research and client QA records live in a separate
private workspace and are not runtime dependencies.

Architecture and embedded libraries originate from
[NeticSoul/DragonUI at 82a6c52c93ad5eae8eda520c14204f9db72e868e](https://github.com/NeticSoul/DragonUI/tree/82a6c52c93ad5eae8eda520c14204f9db72e868e).
See each addon's `THIRD_PARTY_NOTICES.md`, library headers and
`addons/BetterUI/LICENSES/` for component terms. No blanket license is asserted
for future imports. No donor artwork, fonts, NewEra or ClassicAPI are bundled.

World of Warcraft is a Blizzard Entertainment trademark. This project is unofficial.
