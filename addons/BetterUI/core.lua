-- BetterUI contributors, MIT. Adapted DragonUI lifecycle; see THIRD_PARTY_NOTICES.md.
local _, addon = ...
_G.BetterUI = addon
addon.core = LibStub("AceAddon-3.0"):NewAddon("BetterUI", "AceConsole-3.0", "AceEvent-3.0")
function addon.core:OnInitialize()
    addon.state.addonLoaded = true
    self:RegisterChatCommand("betterui", function(input) addon:Slash(input) end)
    local version, build, _, interface = GetBuildInfo()
    if version ~= "4.3.4" or tostring(build) ~= "15595" or tonumber(interface) ~= 40300 then
        addon.disabledReason = addon.L["Unsupported client; expected 4.3.4 (15595)."]
        addon:Error(addon.disabledReason); return
    end
    local ok, reason = addon:InitializeDatabase()
    if not ok then addon.disabledReason = addon.L[reason]; addon:Error(addon.disabledReason); return end
    addon:ResolveLocale()
    addon.state.initialized = true
end
function addon.core:OnEnable()
    if not addon.state.initialized then return end
    addon.state.enabled, addon.state.login = true, IsLoggedIn() and true or false
    if not addon.state.sessionCounted then
        addon.db.char.logins = addon.db.char.logins + 1
        addon.state.sessionCounted = true
    end
    self:RegisterEvent("PLAYER_REGEN_DISABLED", function() addon.Editor:CombatStart() end)
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function() addon.CombatQueue:Process() end)
    self:RegisterEvent("DISPLAY_SIZE_CHANGED", function() addon:RefreshConfig() end)
    self:RegisterEvent("UI_SCALE_CHANGED", function() addon:RefreshConfig() end)
    addon:RefreshConfig()
    self:SendMessage("BETTERUI_READY")
end
function addon.core:OnDisable()
    addon.state.enabled = false
    addon.CombatQueue:Clear()
    addon.Editor:Shutdown()
    addon.ModuleRegistry:Disable()
    if addon.OptionsPanel then addon.OptionsPanel.frame:Hide() end
    self:UnregisterAllEvents()
end
function addon:ToggleOptionsUI(force)
    if not self:CanChange() then return false end
    if not IsAddOnLoaded("BetterUI_Options") then
        local ok, reason = LoadAddOn("BetterUI_Options")
        if not ok or not IsAddOnLoaded("BetterUI_Options") then
            self:Error(self.L["Options unavailable"] .. ": " .. tostring(reason or "load failed")); return false
        end
    end
    if not self.OptionsPanel or not self.OptionsPanel.ready then self:Error(self.L["Options unavailable"]); return false end
    self.state.options = true
    if force then self.OptionsPanel.frame:Show()
    elseif self.OptionsPanel.frame:IsShown() then self.OptionsPanel.frame:Hide()
    else self.OptionsPanel.frame:Show() end
    return true
end
