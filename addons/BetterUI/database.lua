-- BetterUI contributors, MIT. AceDB scopes follow DragonUI; see THIRD_PARTY_NOTICES.md.
local _, addon = ...
addon.defaults = {
    global = { locale = "auto", defaultProfile = "" },
    char = { logins = 0 },
    profile = {
        widget = { enabled = true, x = 0, y = 100, scale = 1 },
        window = { x = 0, y = 0, scale = 1 },
        unitframes = {
            player = {
                enabled = true,
                visible = true,
                x = -350,
                y = -200,
                scale = 1,
                portrait = true,
                dragon = false,
                combatHighlight = true,
                healthText = true,
                powerText = true,
            },
            target = {
                enabled = true,
                visible = true,
                x = 350,
                y = -200,
                scale = 1,
                portrait = true,
                dragon = true,
                combatHighlight = true,
                healthText = true,
                powerText = true,
            },
        },
        editorShowGrid = true,
        layouts = {},
    },
}
function addon.Copy(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        error("Cyclic settings table")
    end
    seen[value] = true
    local out = {}
    for k, v in pairs(value) do
        out[k] = addon.Copy(v, seen)
    end
    seen[value] = nil
    return out
end
function addon.Finite(n, min, max)
    return type(n) == "number" and n == n and n >= min and n <= max
end
function addon.ValidName(name)
    return type(name) == "string" and #name > 0 and #name <= 48 and name:find("%S") and not name:find("[%c]")
end
local function geometry(t, widget)
    if type(t) ~= "table" then
        return false
    end
    local allowed = { x = true, y = true, scale = true, enabled = widget }
    for k in pairs(t) do
        if not allowed[k] then
            return false
        end
    end
    return addon.Finite(t.x, -10000, 10000)
        and addon.Finite(t.y, -10000, 10000)
        and addon.Finite(t.scale, 0.5, 1.5)
        and (not widget or type(t.enabled) == "boolean")
end
function addon.ValidateUnitFrame(t, kind)
    if type(t) ~= "table" then
        return false
    end
    local allowed = { x = true, y = true, scale = true }
    local flags = { "enabled", "visible", "portrait", "dragon", "healthText", "powerText" }
    if kind == "settings" then
        -- Additive option: older settings exports omitted it; nil keeps the default.
        allowed.combatHighlight = true
        if t.combatHighlight ~= nil and type(t.combatHighlight) ~= "boolean" then
            return false
        end
        for _, key in ipairs(flags) do
            allowed[key] = true
            if type(t[key]) ~= "boolean" then
                return false
            end
        end
    end
    for key in pairs(t) do
        if not allowed[key] then
            return false
        end
    end
    return addon.Finite(t.x, -10000, 10000) and addon.Finite(t.y, -10000, 10000) and addon.Finite(t.scale, 0.5, 1.5)
end
function addon.ValidateSettings(t, kind)
    if type(t) ~= "table" then
        return false
    end
    local allowed = { widget = true, window = true, unitframes = true, editorShowGrid = kind == "settings" }
    for k in pairs(t) do
        if not allowed[k] then
            return false
        end
    end
    -- Additive extension: old Phase 1 presets keep current unit-frame settings.
    if t.unitframes ~= nil then
        if type(t.unitframes) ~= "table" then
            return false
        end
        for key in pairs(t.unitframes) do
            if key ~= "player" and key ~= "target" then
                return false
            end
        end
        for _, key in ipairs({ "player", "target" }) do
            if not addon.ValidateUnitFrame(t.unitframes[key], kind) then
                return false
            end
        end
    end
    return geometry(t.widget, kind == "settings")
        and geometry(t.window, false)
        and (kind ~= "settings" or type(t.editorShowGrid) == "boolean")
end
function addon:Snapshot(kind)
    local p = self.db.profile
    local out = { widget = self.Copy(p.widget), window = self.Copy(p.window) }
    out.unitframes = {}
    for _, id in ipairs({ "player", "target" }) do
        local cfg = p.unitframes[id]
        out.unitframes[id] = kind == "settings" and self.Copy(cfg) or { x = cfg.x, y = cfg.y, scale = cfg.scale }
    end
    if kind == "settings" then
        out.editorShowGrid = p.editorShowGrid
    end
    if kind == "positions" then
        out.widget.enabled = nil
    end
    return out
end
local function fill(t, defaults)
    for k, v in pairs(defaults) do
        if t[k] == nil then
            t[k] = addon.Copy(v)
        elseif type(v) == "table" and type(t[k]) == "table" then
            fill(t[k], v)
        end
    end
end
-- Operates on a copy. Rejection never mutates the stored SV or a newer schema.
function addon:PrepareDatabase(raw)
    if raw == nil then
        return { schema = self.schema, target = self.target }, false
    end
    if type(raw) ~= "table" then
        return nil, "Invalid data"
    end
    if raw.schema ~= nil and (not self.Finite(raw.schema, 0, self.schema) or raw.schema % 1 ~= 0) then
        return nil, "Future database schema; saved data was not changed."
    end
    if raw.target and raw.target ~= self.target then
        return nil, "Wrong target or schema"
    end
    for _, k in ipairs({ "global", "profiles", "profileKeys", "char" }) do
        if raw[k] ~= nil and type(raw[k]) ~= "table" then
            return nil, "Invalid data"
        end
    end
    local work = self.Copy(raw)
    work.profiles, work.global = work.profiles or {}, work.global or {}
    fill(work.global, self.defaults.global)
    if not ({ auto = true, enUS = true, ruRU = true })[work.global.locale] then
        return nil, "Invalid data"
    end
    if work.global.defaultProfile ~= "" and not self.ValidName(work.global.defaultProfile) then
        return nil, "Invalid name"
    end
    for key, profile in pairs(work.profiles) do
        if not self.ValidName(key) or type(profile) ~= "table" then
            return nil, "Invalid data"
        end
        fill(profile, self.defaults.profile)
        local settings = {
            widget = profile.widget,
            window = profile.window,
            unitframes = profile.unitframes,
            editorShowGrid = profile.editorShowGrid,
        }
        if not self.ValidateSettings(settings, "settings") or type(profile.layouts) ~= "table" then
            return nil, "Invalid data"
        end
        for name, layout in pairs(profile.layouts) do
            if not self.ValidName(name) or not self.ValidateSettings(layout, "positions") then
                return nil, "Invalid data"
            end
        end
    end
    for key, name in pairs(work.profileKeys or {}) do
        if type(key) ~= "string" or not self.ValidName(name) then
            return nil, "Invalid data"
        end
    end
    for key, char in pairs(work.char or {}) do
        if
            type(key) ~= "string"
            or type(char) ~= "table"
            or (char.logins ~= nil and not self.Finite(char.logins, 0, 1e12))
        then
            return nil, "Invalid data"
        end
    end
    work.schema, work.target = self.schema, self.target
    return work, raw.schema ~= self.schema
end
function addon:InitializeDatabase()
    local prepared, migrated = self:PrepareDatabase(BetterUIDB)
    if not prepared then
        return false, migrated
    end
    if migrated then
        BetterUIBackup = self.Copy(BetterUIDB)
    end
    BetterUIDB = prepared
    local default = prepared.global and prepared.global.defaultProfile
    self.db = LibStub("AceDB-3.0"):New("BetterUIDB", self.defaults, default ~= "" and default or nil)
    self.db.RegisterCallback(self, "OnProfileShutdown", "EndHUDSession")
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
    return true
end
function addon:ProfileAction(action, name)
    if not self:CanChange() then
        return false
    end
    if action ~= "reset" and action ~= "default" and not self.ValidName(name) then
        return false, "Invalid name"
    end
    if self.Editor.active then
        self.Editor:Finish(false)
    end
    local db = self.db
    if action == "select" then
        db:SetProfile(name)
    elseif action == "copy" or action == "delete" then
        if not db.sv.profiles[name] then
            return false, "Unknown profile"
        end
        if name == db:GetCurrentProfile() then
            return false, "Active profile cannot be deleted"
        end
        BetterUIBackup = self.Copy(db.sv)
        if action == "copy" then
            db:CopyProfile(name)
        else
            db:DeleteProfile(name)
            if db.global.defaultProfile == name then
                db.global.defaultProfile = ""
            end
        end
    elseif action == "reset" then
        BetterUIBackup = self.Copy(db.sv)
        db:ResetProfile()
    elseif action == "default" then
        db.global.defaultProfile = name == true and db:GetCurrentProfile() or ""
    else
        return false, "Invalid data"
    end
    self:RefreshConfig()
    return true
end
function addon:SetLocale(pref)
    if not self:CanChange() then
        return false
    end
    if not ({ auto = true, enUS = true, ruRU = true })[pref] then
        return false, "Invalid data"
    end
    if pref == "ruRU" and self.clientLocale ~= "ruRU" then
        return false, "English on this client cannot display Russian reliably."
    end
    self.db.global.locale = pref
    local desired = pref == "auto" and self.clientLocale or pref
    self.state.pendingReload = desired ~= self.locale
    self:Print(self.L["Reload required for language change."])
    return true
end

function addon:EndHUDSession()
    if self.Editor.active then
        self.Editor:Finish(false)
    end
end
