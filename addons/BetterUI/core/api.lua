-- BetterUI contributors, MIT. DragonUI registry/queue contracts; see THIRD_PARTY_NOTICES.md.
local _, addon = ...
function addon:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff50c8ffBetterUI|r: " .. tostring(message))
end
function addon:Error(message)
    self.lastError = tostring(message)
    self:Print("|cffff5555" .. self.lastError .. "|r")
end
function addon:CanChange()
    if self.disabledReason or not self.state.enabled or not self.db then
        self:Error(self.disabledReason or self.L["Not ready"]); return false
    end
    if InCombatLockdown() then self:Error(self.L["Cannot change settings in combat."]); return false end
    return true
end
local Queue = { pending = {}, order = {} }
addon.CombatQueue = Queue
function Queue:Add(id, func, ...)
    assert(type(id) == "string" and type(func) == "function", "Invalid queue operation")
    if not self.pending[id] then self.order[#self.order + 1] = id end
    self.pending[id] = { func = func, args = { n = select("#", ...), ... } }
    return "queued"
end
function Queue:Clear()
    self.pending, self.order = {}, {}
end
function Queue:ExecuteOrQueue(id, func, ...)
    if InCombatLockdown() then return self:Add(id, func, ...) end
    local ok, err = pcall(func, ...)
    if not ok then addon:Error(id .. ": " .. tostring(err)); return "failed", err end
    return "executed"
end
function Queue:Process()
    if InCombatLockdown() then return "queued" end
    local order, pending = self.order, self.pending
    self:Clear()
    local result = "executed"
    for _, id in ipairs(order) do
        local job = pending[id]
        local status = self:ExecuteOrQueue(id, job.func, unpack(job.args, 1, job.args.n))
        if status == "failed" then result = "failed" end
        if status == "queued" and result ~= "failed" then result = "queued" end
    end
    return result
end
local Registry = { order = {}, entries = {} }
addon.ModuleRegistry = Registry
function Registry:Register(id, spec)
    assert(not self.entries[id], "Duplicate module: " .. id)
    assert(type(spec.refresh) == "function" and type(spec.disable) == "function", "Incomplete module")
    self.order[#self.order + 1] = id
    self.entries[id] = spec
    spec.state = "disabled"
end
function Registry:Refresh()
    for _, id in ipairs(self.order) do
        local spec = self.entries[id]
        local enabled
        local ok, err = pcall(function()
            enabled = spec.enabled()
            if enabled then return spec.refresh() else return spec.disable() end
        end)
        spec.state = ok and (enabled and "enabled" or "disabled") or "failed"
        if not ok then addon:Error(id .. ": " .. tostring(err)) end
    end
end
function Registry:Disable()
    for i = #self.order, 1, -1 do
        local id, spec = self.order[i], self.entries[self.order[i]]
        local ok, err = pcall(spec.disable)
        spec.state = ok and "disabled" or "failed"
        if not ok then addon:Error(id .. ": " .. tostring(err)) end
    end
end
function addon:RefreshConfig()
    if not self.state.enabled or self.disabledReason then return end
    return self.CombatQueue:ExecuteOrQueue("refresh", function()
        addon.ModuleRegistry:Refresh()
        if addon.Editor.frames.window then addon.Editor:Apply("window") end
        if addon.OptionsPanel then addon.OptionsPanel:Refresh() end
    end)
end
function addon:SetWidgetEnabled(on)
    if not self:CanChange() then return false end
    if self.Editor.active then self.Editor:Finish(false) end
    self.db.profile.widget.enabled = on and true or false
    self:RefreshConfig()
    return true
end
