-- BetterUI contributors. MIT; architecture attribution in THIRD_PARTY_NOTICES.md.
local L = LibStub("AceLocale-3.0-DragonUI"):NewLocale("BetterUI", "enUS", true, true)
local keys = {
    "Settings",
    "Edit Mode",
    "Profiles",
    "Profile",
    "Name",
    "Apply",
    "Cancel",
    "Save",
    "Reset",
    "Delete",
    "Copy",
    "Close",
    "Scale",
    "Window scale",
    "Language",
    "Show diagnostic widget",
    "Show grid",
    "Layout",
    "Save layout",
    "Load layout",
    "Delete layout",
    "Create / select",
    "Copy from",
    "Delete profile",
    "Reset profile",
    "Default for new characters",
    "Use current profile",
    "Per-character profiles",
    "Preset",
    "Export settings",
    "Export positions",
    "Import",
    "Confirm",
    "Session saved",
    "Session cancelled",
    "Cannot change settings in combat.",
    "Options unavailable",
    "Not ready",
    "Invalid name",
    "Unknown profile",
    "Active profile cannot be deleted",
    "Invalid data",
    "Wrong target or schema",
    "Future database schema; saved data was not changed.",
    "Unsupported client; expected 4.3.4 (15595).",
    "English on this client cannot display Russian reliably.",
    "Reload required for language change.",
    "Diagnostics",
    "auto",
    "enUS",
    "ruRU",
    "Changes apply immediately out of combat.",
    "Edit HUD frames; Save/Cancel affect HUD only. Drag this window by its title.",
    "This action replaces or removes saved settings. Continue?",
    "Paste a BetterUI preset, then Import.",
    "Imported",
    "Enabled",
    "Disabled",
    "Profile changed; reopen the confirmation.",
}
for _, key in ipairs(keys) do
    L[key] = true
end

-- Phase 2.1 unit frames.
L["Unit Frames"] = true
L["Player Frame"] = true
L["Target Frame"] = true
L["Enable styling"] = true
L["Visible"] = true
L["Portrait"] = true
L["Dragon decoration"] = true
L["HP text"] = true
L["Power text"] = true
L["Position X / Y"] = true
L["Apply position"] = true
L["Reset unit frame"] = true
L["Unit frame changes join HUD Save/Cancel. Vehicle art stays native."] = true
L["Dead"] = true
L["Ghost"] = true
L["Offline"] = true

-- Unit-frame visual diagnostics.
L["Unit frame texture diagnostics"] = true
L["Check every image visually; a retained path does not prove texture loading."] = true
L["Verify pixels"] = true
L["Missing texture"] = true
