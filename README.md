# BetterUI_Cata

Experimental UI addon for **original World of Warcraft Cataclysm 4.3.4,
build 15595** (Interface 40300, Lua 5.1). Cataclysm Classic 4.4.x is not supported.

Phase 1 provides bootstrap, profiles, English/Russian localization, LoadOnDemand
options and the shared HUD editor. Phase 2.1 adds DragonUI-style Player/Target skins
on the original secure Blizzard unit buttons. Static/model checks do not establish in-game compatibility;
client status remains **UNTESTED**.

## Install

Copy both directories from `addons/` into the client's `Interface/AddOns/`:

- `BetterUI`
- `BetterUI_Options` (loaded on demand; requires BetterUI)

Enable `/console scriptErrors 1`, reload, and use `/betterui diag`, `/betterui`,
and `/betterui edit`. Back up saved settings before testing experimental builds.

The Unit Frames settings category controls each frame's styling, visibility, scale,
position, portrait, dragon and HP/power text. HUD movers use the existing Save/Cancel
session; drag the settings window by its title independently. Settings changes are
blocked in combat. Disabling the addon in combat restores protected unit button
geometry/visibility after combat ends. Vehicle mode uses Blizzard's native skin.
Native class resources, menus and target auras remain in use. The normal skin currently
does not display native heal-prediction overlays; disable styling to restore them.
Fat/compact/Forever skins, custom absorb/resource layers and other unit frames are
outside this slice. Report taint, overlap and vehicle issues against the exact build.

Use `/betterui ufdiag` out of combat to inspect every imported texture sheet, expected
file dimensions and detected geometry/load errors. A retained texture path alone does
not prove decoded pixels; inspect each gallery image. Fully exit/restart the client
after installing new image files. Player dragon art requires its decoration option;
normal targets have no dragon, while elite/rare/rareelite/boss targets use their
classification. The normal skin uses the original DragonUI anchors and native client
font families, without an extra class-text row below the frame.

## Source and attribution

This public repository contains the distributable addon files and their notices.
Development tools, Registry, research and client QA records live in a separate
private workspace and are not runtime dependencies.

Architecture and embedded libraries originate from
[NeticSoul/DragonUI at 82a6c52c93ad5eae8eda520c14204f9db72e868e](https://github.com/NeticSoul/DragonUI/tree/82a6c52c93ad5eae8eda520c14204f9db72e868e).
See each addon's `THIRD_PARTY_NOTICES.md`, library headers and
`addons/BetterUI/LICENSES/` for component terms. No blanket license is asserted
for future imports. Selected DragonUI game artwork is bundled under its Blizzard
Entertainment game-use notice; it is excluded from the code's MIT terms. No donor
fonts, NewEra or ClassicAPI are bundled.

World of Warcraft is a Blizzard Entertainment trademark. This project is unofficial.
