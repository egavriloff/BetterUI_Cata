-- BetterUI contributors, MIT. Adapted NeticSoul/DragonUI normal skins/power/dragon maps; see THIRD_PARTY_NOTICES.md.
local _, addon = ...
local UF = { entries = {} }
addon.UnitFrames = UF
local ART = "Interface\\AddOns\\BetterUI\\Textures\\UnitFrames\\"
local powerNames = { [0] = "Mana", [1] = "Rage", [2] = "Focus", [3] = "Energy", [6] = "RunicPower" }
local dragons = {
    elite = { 0.001953125, 0.314453125, 0.322265625, 0.630859375 },
    rare = { 0.00390625, 0.31640625, 0.64453125, 0.953125 },
    rareelite = { 0.001953125, 0.388671875, 0.001953125, 0.31835937 },
}
local function points(frame)
    local result = {}
    for i = 1, frame:GetNumPoints() do
        result[i] = { frame:GetPoint(i) }
    end
    return result
end
local function restorePoints(frame, saved)
    frame:ClearAllPoints()
    for _, point in ipairs(saved) do
        frame:SetPoint(unpack(point))
    end
end
local function text(parent, x, y, width)
    local font = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    font:SetPoint("CENTER", parent, "TOPLEFT", x, y)
    font:SetWidth(width)
    return font
end
local function texture(parent, file, layer, x, y, width, height)
    local region = parent:CreateTexture(nil, layer)
    region:SetTexture(file)
    region:SetSize(width, height)
    region:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    return region
end
local function bar(parent, x, y, width, height)
    local frame = CreateFrame("StatusBar", nil, parent)
    frame:SetSize(width, height)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame.label = text(frame, width / 2, -height / 2, width)
    return frame
end
function UF:Config(id)
    return addon.db.profile.unitframes[id]
end
function UF:Update(id)
    local entry = self.entries[id]
    if not entry then
        return
    end
    local cfg = self:Config(id)
    -- Blizzard alone owns vehicle unit rebinding and protected animation geometry.
    local active = entry.applied
        and addon.state.enabled
        and cfg.enabled
        and not (id == "player" and entry.frame.state == "vehicle")
    entry.skin:SetAlpha(active and 1 or 0)
    if active or entry.suppressed then
        for region, alpha in pairs(entry.alphas) do
            region:SetAlpha(active and 0 or alpha)
        end
    end
    entry.suppressed = active
    if not active then
        return
    end
    local unit = entry.frame.unit or id
    local exists = UnitExists(unit)
    entry.portrait:SetAlpha(exists and cfg.portrait and 1 or 0)
    if exists then
        SetPortraitTexture(entry.portrait, unit)
    end
    entry.name:SetText(exists and UnitName(unit) or "")
    local level = exists and UnitLevel(unit) or 0
    entry.level:SetText(level < 0 and "??" or (exists and tostring(level) or ""))
    local className, class = UnitClass(unit)
    local color = RAID_CLASS_COLORS[class]
    entry.class:SetText(exists and UnitIsPlayer(unit) and className or "")
    entry.name:SetTextColor(color and color.r or 1, color and color.g or 0.82, color and color.b or 0)
    local minimum, maximum = entry.nativeHealth:GetMinMaxValues()
    entry.health:SetMinMaxValues(minimum, maximum)
    entry.health:SetValue(entry.nativeHealth:GetValue())
    entry.health:SetStatusBarColor(0, 1, 0)
    minimum, maximum = entry.nativePower:GetMinMaxValues()
    entry.power:SetMinMaxValues(minimum, maximum)
    entry.power:SetValue(entry.nativePower:GetValue())
    local typeID = UnitPowerType(unit)
    local powerColor = PowerBarColor[typeID]
    if powerColor then
        entry.power:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)
    else
        entry.power:SetStatusBarColor(1, 1, 1)
    end
    local prefix = ART .. "Bars\\UI-HUD-UnitFrame-" .. entry.artName .. "-PortraitOn-Bar-"
    -- Unknown vehicle/alternate power retains its native texture/color, not a fake mana type.
    local name = powerNames[typeID]
    entry.power:SetStatusBarTexture(name and prefix .. name or entry.nativePower:GetStatusBarTexture():GetTexture())
    local status = UnitIsGhost(unit) and addon.L["Ghost"] or (UnitIsDead(unit) and addon.L["Dead"] or nil)
    if not UnitIsConnected(unit) then
        status = addon.L["Offline"]
    end
    entry.health.label:SetText(
        exists and cfg.healthText and (status or (UnitHealth(unit) .. " / " .. UnitHealthMax(unit))) or ""
    )
    entry.power.label:SetText(
        exists and cfg.powerText and not status and (UnitPower(unit) .. " / " .. UnitPowerMax(unit)) or ""
    )
    local classification = id == "player" and "elite" or UnitClassification(unit)
    if classification == "worldboss" then
        classification = "rareelite"
    end
    local cell = dragons[classification]
    entry.dragon:SetAlpha(cfg.dragon and cell and exists and 1 or 0)
    if cell then
        if id == "player" then
            entry.dragon:SetTexCoord(cell[2], cell[1], cell[3], cell[4])
        else
            entry.dragon:SetTexCoord(unpack(cell))
        end
    end
end
function UF:Create(id)
    assert(not InCombatLockdown(), "Cannot initialize unit frames in combat")
    local player = id == "player"
    local frame = player and PlayerFrame or TargetFrame
    local entry = {
        frame = frame,
        artName = player and "Player" or "Target",
        alphas = {},
        nativeHealth = frame.healthbar,
        nativePower = frame.manabar,
        home = points(frame),
        scale = frame:GetScale(),
        userPlaced = frame:IsUserPlaced(),
        statehidden = frame:GetAttribute("statehidden"),
    }
    self.entries[id] = entry
    -- Snapshot only the visual regions this skin suppresses; never unregister native events.
    local regions = player
            and { PlayerFrameTexture, PlayerFrameBackground, PlayerPortrait, PlayerName, PlayerLevelText }
        or { frame.borderTexture, frame.nameBackground, frame.portrait, frame.name, frame.levelText }
    regions[#regions + 1], regions[#regions + 2] = entry.nativeHealth, entry.nativePower
    for _, region in ipairs(regions) do
        entry.alphas[region] = region:GetAlpha()
    end
    local skin = CreateFrame("Frame", nil, frame)
    entry.skin = skin
    skin:SetSize(232, 100)
    skin:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    skin:EnableMouse(false)
    local canvasX, canvasY = player and 33 or -21, 0
    texture(skin, ART .. "HD\\" .. entry.artName .. "-BACKGROUND", "BACKGROUND", canvasX, canvasY, 256, 128)
    entry.portrait = texture(skin, nil, "ARTWORK", player and 42 or 129.25, -12, 56, 56)
    local hx, hy = player and 100 or 2, player and -30 or -31.25
    entry.health = bar(skin, hx, hy, 125, 20)
    entry.health:SetStatusBarTexture(ART .. "Bars\\UI-HUD-UnitFrame-" .. entry.artName .. "-PortraitOn-Bar-Health")
    entry.power = bar(skin, player and 100 or 2, -54, player and 125 or 133, 10)
    -- Border is on a higher frame than the fills; text stays readable above both.
    local foreground = CreateFrame("Frame", nil, skin)
    foreground:SetAllPoints(skin)
    foreground:SetFrameLevel(entry.health:GetFrameLevel() + 1)
    foreground:EnableMouse(false)
    texture(foreground, ART .. "HD\\" .. entry.artName .. "-BORDER", "ARTWORK", canvasX, canvasY, 256, 128)
    entry.dragon = texture(foreground, ART .. "uiunitframeboss2x", "OVERLAY", player and 25.5 or 122, -4, 80, 79)
    entry.name = text(foreground, player and 162 or 66, -23, 116)
    entry.level = text(foreground, player and 68 or 158, -72, 40)
    entry.class = text(foreground, player and 162 or 66, -76, 128)
    local mover = CreateFrame("Frame", nil, UIParent)
    mover:SetSize(232, 100)
    mover:SetFrameStrata("DIALOG")
    addon.StyleWindow(mover)
    text(mover, 116, -18, 220):SetText(addon.L[player and "Player Frame" or "Target Frame"])
    entry.mover = mover
    addon:RegisterEditableFrame(id, mover)
    mover:Hide()
    skin:SetAlpha(0)
    return entry
end
function UF:Restore(id)
    local entry = self.entries[id]
    if not entry or not entry.applied then
        return
    end
    assert(not InCombatLockdown(), "Cannot restore protected unit frames in combat")
    entry.applied = false
    entry.suppressed = false
    entry.skin:SetAlpha(0)
    entry.mover:Hide()
    for region, alpha in pairs(entry.alphas) do
        region:SetAlpha(alpha)
    end
    restorePoints(entry.frame, entry.home)
    entry.frame:SetScale(entry.scale)
    entry.frame:SetUserPlaced(entry.userPlaced)
    if entry.hidden then
        UnregisterStateDriver(entry.frame, "visibility")
        entry.frame:SetAttribute("statehidden", entry.statehidden)
        entry.hidden = nil
        if id == "player" then
            entry.frame:Show()
        else
            TargetFrame_Update(entry.frame)
        end
    end
end
function UF:Refresh(id)
    if InCombatLockdown() then
        return addon.CombatQueue:Add("unitframes-" .. id, function()
            UF:Refresh(id)
        end)
    end
    if not addon.state.enabled or not self:Config(id).enabled then
        return self:Restore(id)
    end
    local entry = self.entries[id] or self:Create(id)
    entry.applied = true
    local cfg = self:Config(id)
    addon.Editor:Apply(id)
    if not (id == "player" and entry.frame.state == "vehicle") then
        entry.frame:SetUserPlaced(true)
        entry.frame:SetScale(entry.mover:GetScale())
        entry.frame:ClearAllPoints()
        local scale = entry.mover:GetScale()
        local x, y = entry.mover:GetCenter()
        local cx, cy = UIParent:GetCenter()
        entry.frame:SetPoint("CENTER", UIParent, "CENTER", x - cx / scale, y - cy / scale)
    end
    if not cfg.visible then
        RegisterStateDriver(entry.frame, "visibility", "hide")
        entry.hidden = true
    elseif entry.hidden then
        UnregisterStateDriver(entry.frame, "visibility")
        entry.frame:SetAttribute("statehidden", entry.statehidden)
        entry.hidden = nil
        if id == "player" then
            entry.frame:Show()
        else
            TargetFrame_Update(entry.frame)
        end
    end
    if addon.Editor.active then
        entry.mover:Show()
    else
        entry.mover:Hide()
    end
    self:Update(id)
end
function UF:Disable(id)
    if self.entries[id] then
        self.entries[id].mover:Hide()
    end
    if InCombatLockdown() then
        return addon.CombatQueue:Add("unitframes-" .. id, function()
            UF:Restore(id)
        end)
    end
    self:Restore(id)
end
function addon:SetUnitFrame(id, key, value)
    if not self:CanChange() then
        return false
    end
    if id ~= "player" and id ~= "target" then
        return false, "Invalid data"
    end
    if key == "reset" then
        self.db.profile.unitframes[id] = self.Copy(self.defaults.profile.unitframes[id])
    else
        local candidate = self.Copy(self.db.profile.unitframes[id])
        candidate[key] = value
        if not self.ValidateUnitFrame(candidate, "settings") then
            return false, "Invalid data"
        end
        self.db.profile.unitframes[id] = candidate
    end
    self:RefreshConfig()
    return true
end
local events = CreateFrame("Frame")
for _, event in ipairs({
    "PLAYER_TARGET_CHANGED",
    "UNIT_HEALTH",
    "UNIT_HEALTH_FREQUENT",
    "UNIT_MAXHEALTH",
    "UNIT_POWER",
    "UNIT_POWER_FREQUENT",
    "UNIT_MAXPOWER",
    "UNIT_PORTRAIT_UPDATE",
    "UNIT_NAME_UPDATE",
    "UNIT_LEVEL",
    "UNIT_DISPLAYPOWER",
    "UNIT_CLASSIFICATION_CHANGED",
    "UNIT_CONNECTION",
    "UNIT_FLAGS",
    "CVAR_UPDATE",
    "PLAYER_DEAD",
    "PLAYER_ALIVE",
    "PLAYER_UNGHOST",
    "PLAYER_ENTERING_WORLD",
}) do
    events:RegisterEvent(event)
end
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        addon.CombatQueue:Process()
    end
    UF.pending = true
end)
-- Run after native event handlers, never assume frame registration order. The single
-- state comparison also catches Blizzard's asynchronous vehicle animation completion.
events:SetScript("OnUpdate", function()
    if not addon.db then
        return
    end
    local vehicle = PlayerFrame.state == "vehicle"
    if UF.vehicle ~= vehicle then
        UF.vehicle = vehicle
        UF.pending = true
        if not vehicle then
            UF:Refresh("player")
        end
    end
    if UF.pending then
        UF.pending = nil
        UF:Update("player")
        UF:Update("target")
    end
end)
for _, id in ipairs({ "player", "target" }) do
    local key = id
    addon.ModuleRegistry:Register("unitframe-" .. key, {
        enabled = function()
            return UF:Config(key).enabled
        end,
        refresh = function()
            UF:Refresh(key)
        end,
        disable = function()
            UF:Disable(key)
        end,
    })
end
