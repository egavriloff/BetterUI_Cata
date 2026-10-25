-- BetterUI contributors, MIT. DragonUI editable-frame/session contract; see THIRD_PARTY_NOTICES.md.
local _, addon = ...
local Editor = { frames = {}, active = false }
addon.Editor = Editor
local function windowStyle(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.04, 0.07, 0.10, 0.95)
end
addon.StyleWindow = windowStyle
function Editor:Apply(id)
    local frame, cfg = self.frames[id], addon.db.profile[id]
    if not frame then
        return
    end
    local scale = math.min(
        cfg.scale,
        (UIParent:GetWidth() - 16) / frame:GetWidth(),
        (UIParent:GetHeight() - 16) / frame:GetHeight()
    )
    frame:SetScale(scale)
    -- Geometry stored in UIParent units. Changing the element scale never shifts its centre.
    frame:ClearAllPoints()
    local limitX = math.max(0, UIParent:GetWidth() / 2 - frame:GetWidth() * scale / 2 - 8)
    local limitY = math.max(0, UIParent:GetHeight() / 2 - frame:GetHeight() * scale / 2 - 8)
    frame:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        math.max(-limitX, math.min(limitX, cfg.x)) / scale,
        math.max(-limitY, math.min(limitY, cfg.y)) / scale
    )
end
function Editor:Capture(id)
    local frame = self.frames[id]
    frame:StopMovingOrSizing()
    local x, y = frame:GetCenter()
    local cx, cy = UIParent:GetCenter()
    local relativeScale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local cfg = addon.db.profile[id]
    cfg.x, cfg.y = x * relativeScale - cx, y * relativeScale - cy
end
function addon:RegisterEditableFrame(id, frame)
    assert(not Editor.frames[id], "Duplicate editable frame")
    assert(id == "widget" or id == "window", "Unknown editable frame config")
    Editor.frames[id] = frame
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    -- The options window uses its title handle, independently of HUD sessions.
    if id == "window" then
        return
    end
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if Editor.active and not InCombatLockdown() then
            Editor.dragging = id
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function()
        if Editor.dragging == id then
            Editor:Capture(id)
            Editor.dragging = nil
        end
    end)
end
function Editor:RegisterWindowDragHandle(handle)
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function()
        if self.windowDrag or not self.frames.window:IsShown() or not addon:CanChange() then
            return
        end
        self.windowDrag = { profile = addon.db:GetCurrentProfile(), config = addon.db.profile.window }
        self.frames.window:StartMoving()
    end)
    handle:SetScript("OnDragStop", function()
        self:StopWindowDrag(true)
    end)
end
function Editor:StopWindowDrag(save)
    local drag = self.windowDrag
    if not drag then
        return
    end
    self.windowDrag = nil
    self.frames.window:StopMovingOrSizing()
    if
        save
        and not InCombatLockdown()
        and addon.state.enabled
        and addon.db:GetCurrentProfile() == drag.profile
        and addon.db.profile.window == drag.config
    then
        self:Capture("window")
    end
    if InCombatLockdown() then
        addon.CombatQueue:Add("window-drag-stop", function()
            self:Apply("window")
        end)
    else
        self:Apply("window")
    end
end
function Editor:RestoreHUD(snapshot)
    local profile = addon.db.profile
    profile.widget = addon.Copy(snapshot.widget)
    profile.editorShowGrid = snapshot.editorShowGrid
end
function Editor:Grid()
    if self.grid then
        if self.gridWidth == UIParent:GetWidth() and self.gridHeight == UIParent:GetHeight() then
            return self.grid
        end
        self.grid:Hide()
        for _, texture in ipairs(self.lines) do
            texture:Hide()
        end
    end
    local grid = self.grid or CreateFrame("Frame", nil, UIParent)
    grid:SetAllPoints(UIParent)
    grid:SetFrameStrata("BACKGROUND")
    self.lines = self.lines or {}
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    self.gridWidth, self.gridHeight = width, height
    local index = 0
    local function line()
        index = index + 1
        local t = self.lines[index] or grid:CreateTexture(nil, "BACKGROUND")
        self.lines[index] = t
        t:ClearAllPoints()
        t:SetTexture(0.2, 0.7, 1, 0.16)
        t:Show()
        return t
    end
    for x = 0, width, 32 do
        local t = line()
        t:SetWidth(1)
        t:SetPoint("TOPLEFT", grid, "TOPLEFT", x, 0)
        t:SetPoint("BOTTOMLEFT", grid, "BOTTOMLEFT", x, 0)
    end
    for y = 0, height, 32 do
        local t = line()
        t:SetHeight(1)
        t:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -y)
        t:SetPoint("TOPRIGHT", grid, "TOPRIGHT", 0, -y)
    end
    self.grid = grid
    return grid
end
function Editor:Start()
    if not addon:CanChange() then
        return false
    end
    if self.active then
        return true
    end
    self.snapshot = { widget = addon.Copy(addon.db.profile.widget), editorShowGrid = addon.db.profile.editorShowGrid }
    self.active = true
    if addon.db.profile.editorShowGrid then
        self:Grid():Show()
    end
    addon:RefreshConfig()
    return true
end
function Editor:Abort()
    if self.dragging then
        self:Capture(self.dragging)
        self.dragging = nil
    end
    self.active = false
    if self.frames.widget then
        self.frames.widget:EnableMouse(false)
    end
    if self.grid then
        self.grid:Hide()
    end
end
function Editor:Finish(save)
    if not addon:CanChange() then
        return false
    end
    if not self.active then
        return true
    end
    self:Abort()
    local snapshot = self.snapshot
    self.snapshot = nil
    if not save then
        self:RestoreHUD(snapshot)
    end
    addon:RefreshConfig()
    addon:Print(addon.L[save and "Session saved" or "Session cancelled"])
    return true
end
function Editor:Shutdown()
    self:StopWindowDrag(false)
    self:Abort()
    local saved = self.snapshot
        or (self.cancelled and self.cancelled.profile == addon.db:GetCurrentProfile() and self.cancelled.snapshot)
    if saved and addon.db then
        self:RestoreHUD(saved)
    end
    self.snapshot, self.cancelled = nil, nil
end
function Editor:CombatStart()
    self:StopWindowDrag(false)
    if not self.active then
        return
    end
    -- These are exclusively our unprotected frames. Stop dragging/hide immediately;
    -- defer restoration of session configuration until regen. Never move stock UI.
    self:Abort()
    local snapshot, profile = self.snapshot, addon.db:GetCurrentProfile()
    self.snapshot = nil
    self.cancelled = { snapshot = snapshot, profile = profile }
    addon.CombatQueue:Add("cancel-editor", function()
        if addon.db:GetCurrentProfile() == profile then
            self:RestoreHUD(snapshot)
            addon:RefreshConfig()
        end
        self.cancelled = nil
    end)
    if addon.OptionsPanel then
        addon.OptionsPanel.frame:Hide()
    end
end
function addon:ResetPositions()
    if not self:CanChange() then
        return false
    end
    if Editor.active then
        Editor:Finish(false)
    end
    local p, d = self.db.profile, self.defaults.profile
    p.widget.x, p.widget.y, p.widget.scale = d.widget.x, d.widget.y, d.widget.scale
    p.window = self.Copy(d.window)
    self:RefreshConfig()
    return true
end
local widget
local function refresh()
    if not widget then
        widget = CreateFrame("Frame", "BetterUI_Status", UIParent)
        widget:SetSize(270, 64)
        windowStyle(widget)
        widget.text = widget:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        widget.text:SetPoint("CENTER")
        widget.text:SetWidth(244)
        addon:RegisterEditableFrame("widget", widget)
    end
    Editor:Apply("widget")
    widget:EnableMouse(Editor.active)
    widget.text:SetText(
        "BetterUI " .. addon.version .. " | 15595\n" .. addon.L["Profile"] .. ": " .. addon.db:GetCurrentProfile()
    )
    widget:Show()
    if Editor.active and addon.db.profile.editorShowGrid then
        Editor:Grid():Show()
    elseif Editor.grid then
        Editor.grid:Hide()
    end
    if Editor.frames.window then
        Editor:Apply("window")
    end
end
local function disable()
    if widget then
        widget:StopMovingOrSizing()
        widget:Hide()
    end
end
addon.ModuleRegistry:Register("diagnostic-widget", {
    enabled = function()
        return addon.db.profile.widget.enabled or Editor.active
    end,
    refresh = refresh,
    disable = disable,
})
