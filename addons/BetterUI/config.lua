-- BetterUI contributors, MIT. DragonUI architecture adaptation; see THIRD_PARTY_NOTICES.md.
local _, addon = ...
addon.name, addon.version, addon.target, addon.schema = "BetterUI", "0.1.0", "4.3.4:15595", 1
addon.state = { files = true, initialized = false, enabled = false, login = false, options = false }
addon.clientLocale = GetLocale() == "ruRU" and "ruRU" or "enUS"
addon.locale = addon.clientLocale
-- A stable proxy: references captured by later files survive database initialization.
addon.L = setmetatable({}, { __index = function(_, key)
    return LibStub("AceLocale-3.0-DragonUI"):GetLocale("BetterUI", addon.locale)[key]
end })
function addon:ResolveLocale()
    local pref = self.db and self.db.global.locale or "auto"
    self.locale = pref == "enUS" and "enUS" or self.clientLocale
    if pref == "ruRU" and self.clientLocale == "ruRU" then self.locale = "ruRU" end
end
-- Like DragonUI's config layer, reads follow the current profile, never a cached old table.
addon.config = setmetatable({}, { __index = function(_, key)
    return addon.db and addon.db.profile[key]
end })
