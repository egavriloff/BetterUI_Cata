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

No donor artwork, fonts, gameplay libraries, NewEra or ClassicAPI are bundled.
Client textures/fonts/templates referenced at runtime are Blizzard's own assets.
World of Warcraft is a Blizzard Entertainment trademark. This project is unofficial.
Full provenance and unchanged vendor SHA256s: docs/upstreams.md and docs/phase1-vendor-lock.json
in the source repository.
