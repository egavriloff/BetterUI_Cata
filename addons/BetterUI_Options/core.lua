-- BetterUI contributors, MIT. DragonUI LoD boundary; see BetterUI/THIRD_PARTY_NOTICES.md.
local addon = BetterUI
assert(addon and addon.state.initialized, "BetterUI must initialize before its options")
addon.LO = setmetatable({}, { __index = function(_, key)
    return LibStub("AceLocale-3.0-DragonUI"):GetLocale("BetterUI_Options", addon.locale)[key]
end })
addon.OptionsPanel = { tabs = {}, order = {} }
function addon.OptionsPanel:RegisterTab(id, title, build)
    assert(not self.tabs[id], "Duplicate options tab")
    self.order[#self.order + 1] = id
    self.tabs[id] = { title = title, build = build }
end
