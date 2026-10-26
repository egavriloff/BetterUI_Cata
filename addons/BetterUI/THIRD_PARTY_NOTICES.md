# BetterUI Phase 1 notices

Architecture and profile/editor/LoD contracts are adapted from NeticSoul/DragonUI,
revision 82a6c52c93ad5eae8eda520c14204f9db72e868e, https://github.com/NeticSoul/DragonUI.
DragonUI's own code: Copyright (c) 2026 NeticSoul and DragonUI contributors, MIT;
full notice in LICENSES/MIT-DragonUI.txt. Newly authored Phase 1 Lua code is
Copyright (c) 2026 BetterUI contributors and offered under the same MIT terms.
This is a per-component notice, not a blanket license for future donor imports.

Embedded libraries under libs/ are byte-for-byte copies from that revision:
LibStub (public domain, its file header); CallbackHandler-1.0, AceAddon-3.0,
AceEvent-3.0, AceDB-3.0, AceConsole-3.0, AceSerializer-3.0 and the
AceLocale-3.0-DragonUI fork (Ace3 terms, LICENSES/Ace3.txt).
These libraries are embedded in BetterUI, not distributed as standalone libraries.
Upstream-generated loadstring dispatchers in AceAddon/CallbackHandler operate only
on fixed internal source strings; no user input is evaluated by BetterUI.

Phase 2.1 normal Player/Target skin geometry, power map and dragon atlas cells are
adapted from DragonUI modules/unitframes/{uf_core,uf_skins,player,target_style,text_system}.lua
at the same pinned revision. Newly authored adapter code uses the same MIT terms.
Selected files under Textures/UnitFrames/{HD,Bars,Player}/ and uiunitframeboss2x.blp are
byte-identical game artwork from DragonUI/Textures/UnitFrames at that revision.
Copyright Blizzard Entertainment. These artworks are NOT covered by MIT and are
included only for use with World of Warcraft, as stated in DragonUI LICENSE.txt.
The visual-fidelity correction adds the missing HD/Target-NameStrip.tga and
Player/ui-hud-unitframe-player-portraiton-cornerembellishment-2x.blp from that same
revision. The original 17 imported texture files remain byte-identical.
No donor fonts, gameplay libraries, NewEra or ClassicAPI are bundled.
Client textures/fonts/templates referenced at runtime are Blizzard's own assets.
World of Warcraft is a Blizzard Entertainment trademark. This project is unofficial.
Full provenance and unchanged vendor SHA256s: docs/upstreams.md and docs/phase1-vendor-lock.json
in the source repository.
