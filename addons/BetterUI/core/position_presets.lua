-- BetterUI contributors, MIT. DragonUI preset contracts; see THIRD_PARTY_NOTICES.md.
local _, addon = ...
local Serializer = LibStub("AceSerializer-3.0")
local HEADER = "!BUICATA1!"
local LIMIT = 16384
function addon:ExportPreset(kind)
    if kind ~= "positions" and kind ~= "settings" then
        return nil, "Invalid data"
    end
    local data = self:Snapshot(kind)
    return HEADER .. Serializer:Serialize({ target = self.target, schema = self.schema, kind = kind, data = data })
end
-- Bound recursion before entering the upstream deserializer. AceSerializer escapes literal ^.
local function bounded(payload)
    local depth, tokens = 0, 0
    for tag in payload:gmatch("%^(.)") do
        tokens = tokens + 1
        if tag == "T" then
            depth = depth + 1
        elseif tag == "t" then
            depth = depth - 1
        end
        if depth < 0 or depth > 5 or tokens > 512 then
            return false
        end
    end
    return depth == 0
end
function addon:DecodePreset(text)
    if type(text) ~= "string" or #text > LIMIT or text:sub(1, #HEADER) ~= HEADER then
        return nil, "Invalid data"
    end
    local payload = text:sub(#HEADER + 1)
    if payload:sub(1, 2) ~= "^1" or payload:find("%^%^") ~= #payload - 1 or not bounded(payload) then
        return nil, "Invalid data"
    end
    local function pack(...)
        return { n = select("#", ...), ... }
    end
    local result = pack(Serializer:Deserialize(payload))
    local envelope = result[2]
    if not result[1] or result.n ~= 2 or type(envelope) ~= "table" then
        return nil, "Invalid data"
    end
    local allowed = { target = true, schema = true, kind = true, data = true }
    for k in pairs(envelope) do
        if not allowed[k] then
            return nil, "Invalid data"
        end
    end
    if envelope.target ~= self.target or envelope.schema ~= self.schema then
        return nil, "Wrong target or schema"
    end
    if envelope.kind ~= "positions" and envelope.kind ~= "settings" then
        return nil, "Invalid data"
    end
    if not self.ValidateSettings(envelope.data, envelope.kind) then
        return nil, "Invalid data"
    end
    return envelope
end
function addon:ApplySnapshot(data, kind)
    -- Fully validate/copy before the first mutation. Caller must pass the combat guard.
    if not self:CanChange() then
        return false
    end
    if not self.ValidateSettings(data, kind) then
        return false, "Invalid data"
    end
    local copy = self.Copy(data)
    if kind == "positions" then
        copy.widget.enabled = self.db.profile.widget.enabled
    end
    if copy.unitframes then
        for _, id in ipairs({ "player", "target" }) do
            if kind == "settings" then
                self.db.profile.unitframes[id] = copy.unitframes[id]
            else
                local cfg, position = self.db.profile.unitframes[id], copy.unitframes[id]
                cfg.x, cfg.y, cfg.scale = position.x, position.y, position.scale
            end
        end
    end
    self.db.profile.widget, self.db.profile.window = copy.widget, copy.window
    if kind == "settings" then
        self.db.profile.editorShowGrid = copy.editorShowGrid
    end
    self:RefreshConfig()
    return true
end
function addon:ImportPreset(text)
    if not self:CanChange() then
        return false
    end
    local envelope, reason = self:DecodePreset(text)
    if not envelope then
        return false, reason
    end
    if self.Editor.active then
        self.Editor:Finish(false)
    end
    BetterUIBackup = self.Copy(self.db.sv)
    return self:ApplySnapshot(envelope.data, envelope.kind)
end
function addon:LayoutAction(action, name)
    if not self:CanChange() then
        return false
    end
    if not self.ValidName(name) then
        return false, "Invalid name"
    end
    local store = self.db.profile.layouts
    if action == "save" then
        store[name] = self:Snapshot("positions")
    elseif action == "load" then
        if not store[name] then
            return false, "Invalid name"
        end
        if self.Editor.active then
            self.Editor:Finish(false)
        end
        return self:ApplySnapshot(store[name], "positions")
    elseif action == "delete" then
        store[name] = nil
    else
        return false, "Invalid data"
    end
    return true
end
