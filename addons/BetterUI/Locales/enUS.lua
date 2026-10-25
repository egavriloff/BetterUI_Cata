-- BetterUI contributors. MIT; architecture attribution in THIRD_PARTY_NOTICES.md.
local L = LibStub("AceLocale-3.0-DragonUI"):NewLocale("BetterUI", "enUS", true, true)
local keys = {"Settings", "Edit Mode", "Profiles", "Profile", "Name", "Apply", "Cancel", "Save", "Reset", "Delete", "Copy", "Close",
    "Scale", "Window scale", "Language", "Show diagnostic widget", "Show grid", "Layout", "Save layout", "Load layout", "Delete layout",
    "Create / select", "Copy from", "Delete profile", "Reset profile", "Default for new characters", "Use current profile",
    "Per-character profiles", "Preset", "Export settings", "Export positions", "Import", "Confirm", "Session saved", "Session cancelled",
    "Cannot change settings in combat.", "Options unavailable", "Not ready", "Invalid name", "Unknown profile", "Active profile cannot be deleted",
    "Invalid data", "Wrong target or schema", "Future database schema; saved data was not changed.", "Unsupported client; expected 4.3.4 (15595).",
    "English on this client cannot display Russian reliably.", "Reload required for language change.", "Diagnostics", "auto", "enUS", "ruRU",
    "Changes apply immediately out of combat.", "Edit the widget or settings window; Save commits, Cancel restores.",
    "This action replaces or removes saved settings. Continue?", "Paste a BetterUI preset, then Import.", "Imported", "Enabled", "Disabled", "Profile changed; reopen the confirmation."}
for _, key in ipairs(keys) do L[key] = true end
