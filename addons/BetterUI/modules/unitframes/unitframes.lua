-- BetterUI contributors, MIT. Adapted NeticSoul/DragonUI normal skins/power/dragon maps; see THIRD_PARTY_NOTICES.md.
local _, addon = ...
local UF = { entries = {} }
addon.UnitFrames = UF
local V = addon.UnitFrameVisuals
local powerNames = { [0] = "Mana", [1] = "Rage", [2] = "Focus", [3] = "Energy", [6] = "RunicPower" }
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
    entry.className, entry.classToken = className, class
    -- The donor normal layout has no third class row; class identity stays native.
    entry.name:SetTextColor(1, 0.82, 0)
    local minimum, maximum = entry.nativeHealth:GetMinMaxValues()
    entry.health:SetMinMaxValues(minimum, maximum)
    entry.health:SetValue(entry.nativeHealth:GetValue())
    V:BarTexture(entry.health, entry.artName .. "Health")
    V:Crop(entry.health, entry.nativeHealth:GetValue() - minimum, maximum - minimum)
    minimum, maximum = entry.nativePower:GetMinMaxValues()
    entry.power:SetMinMaxValues(minimum, maximum)
    entry.power:SetValue(entry.nativePower:GetValue())
    local typeID = UnitPowerType(unit)
    local name = powerNames[typeID]
    if name then
        V:BarTexture(entry.power, entry.artName .. name)
    else
        -- Preserve real native texture semantics for nonstandard power, never substitute mana.
        entry.power:SetStatusBarTexture(entry.nativePower:GetStatusBarTexture():GetTexture())
        entry.power.visualKey = nil
    end
    V:Crop(entry.power, entry.nativePower:GetValue() - minimum, maximum - minimum)
    if id ~= "player" and exists then
        local r, g, b = UnitSelectionColor(unit)
        V:NameColor(entry, r, g, b, UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit))
    end
    -- Match 15595 TargetFrame_CheckDead's zero-health transition as well as flags.
    local dead = UnitIsDead(unit) or (exists and UnitHealth(unit) <= 0)
    local status = UnitIsGhost(unit) and addon.L["Ghost"] or (dead and addon.L["Dead"] or nil)
    if not UnitIsConnected(unit) then
        status = addon.L["Offline"]
    end
    entry.health.label:SetText(
        exists and (status or (cfg.healthText and (UnitHealth(unit) .. " / " .. UnitHealthMax(unit)))) or ""
    )
    entry.power.label:SetText(
        exists and cfg.powerText and not status and (UnitPower(unit) .. " / " .. UnitPowerMax(unit)) or ""
    )
    local classification = id == "player" and "elite" or UnitClassification(unit)
    local decorated = V:Dragon(entry, id == "player", classification)
    entry.dragon:SetAlpha(cfg.dragon and decorated and exists and 1 or 0)
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
    local function remember(region)
        if region then
            entry.alphas[region] = region:GetAlpha()
        end
    end
    -- Exact 15595 decorative regions only. Native Show/Hide, threat calculations,
    -- combat/rest icons and numeric threat remain owned by Blizzard. Suppress the
    -- glow textures, not their animated parent frame (PlayerStatusGlow).
    remember(frame.threatIndicator)
    if player then
        for _, name in ipairs({ "PlayerStatusTexture", "PlayerAttackBackground", "PlayerRestGlow", "PlayerAttackGlow" }) do
            remember(_G[name])
        end
    else
        remember(_G["TargetFrameBackground"])
        remember(frame.highLevelTexture)
        remember(frame.deadText)
    end
    -- 15595 TextStatusBar hover/CVars show TextString on a sibling text frame,
    -- not under the StatusBar. Mask only these bound HP/power FontStrings;
    -- retain their Show/Hide state, lockShow, updates and native mouse scripts.
    for _, status in ipairs({ entry.nativeHealth, entry.nativePower }) do
        if status.TextString then
            entry.alphas[status.TextString] = status.TextString:GetAlpha()
        end
    end
    V:Create(entry)
    V:Layout(entry, player, self:Config(id).dragon)
    local mover = CreateFrame("Frame", nil, UIParent)
    mover:SetSize(232, 100)
    mover:SetFrameStrata("DIALOG")
    addon.StyleWindow(mover)
    local label = mover:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", mover, "TOP", 0, -18)
    label:SetWidth(220)
    label:SetText(addon.L[player and "Player Frame" or "Target Frame"])
    entry.mover = mover
    addon:RegisterEditableFrame(id, mover)
    mover:Hide()
    entry.skin:SetAlpha(0)
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
    V:Layout(entry, id == "player", cfg.dragon)
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
    if self.visualPanel then
        self.visualPanel:Hide()
    end
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
function UF:PrintVisualDiagnostics()
    for _, id in ipairs({ "player", "target" }) do
        local entry = self.entries[id]
        if entry then
            local cfg = self:Config(id)
            local classification = id == "player" and "elite" or UnitClassification(entry.frame.unit or id)
            local issues = V:Issues(entry)
            addon:Print(
                id
                    .. " visual: "
                    .. (#issues == 0 and "geometry OK; pixel loading UNCONFIRMED" or table.concat(issues, "; "))
            )
            addon:Print(
                id
                    .. " dragon: option="
                    .. tostring(cfg.dragon)
                    .. " classification="
                    .. tostring(classification)
                    .. " alpha="
                    .. tostring(entry.dragon and entry.dragon:GetAlpha() or "missing")
                    .. " scale="
                    .. entry.frame:GetScale()
            )
        end
    end
end
function UF:ShowVisualDiagnostics()
    self:PrintVisualDiagnostics()
    if not addon:CanChange() then
        return false
    end
    if not self.visualPanel then
        local frame = CreateFrame("Frame", nil, UIParent)
        self.visualPanel = frame
        frame:SetFrameStrata("DIALOG")
        frame:SetSize(840, 670)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        frame:SetScale(math.min(1, (UIParent:GetWidth() - 24) / 840, (UIParent:GetHeight() - 24) / 670))
        addon.StyleWindow(frame)
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16)
        title:SetText(addon.L["Unit frame texture diagnostics"])
        local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -45)
        hint:SetWidth(800)
        hint:SetText(addon.L["Check every image visually; a retained path does not prove texture loading."])
        local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        close:SetSize(100, 24)
        close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -12)
        close:SetText(addon.L["Close"])
        close:SetScript("OnClick", function()
            frame:Hide()
        end)
        self.visualTiles = {}
        for i, info in ipairs(V.assets) do
            local x, y = 18 + ((i - 1) % 4) * 204, -90 - math.floor((i - 1) / 4) * 112
            local tile = CreateFrame("Frame", nil, frame)
            tile:SetSize(194, 106)
            tile:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
            local background = tile:CreateTexture(nil, "BACKGROUND")
            background:SetAllPoints(tile)
            background:SetTexture(0.12, 0.12, 0.12, 1)
            local image = tile:CreateTexture(nil, "ARTWORK")
            local scale = math.min(184 / info.width, 76 / info.height)
            image:SetSize(info.width * scale, info.height * scale)
            image:SetPoint("TOP", tile, "TOP", 0, 0)
            image:SetTexCoord(0, 1, 0, 1)
            local label = tile:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            label:SetPoint("BOTTOM", tile, "BOTTOM", 0, 2)
            label:SetWidth(194)
            self.visualTiles[i] = { image = image, label = label }
        end
    end
    for i, info in ipairs(V.assets) do
        local tile = self.visualTiles[i]
        local accepted = V:Bind(tile.image, info.key)
        tile.label:SetText(
            info.key
                .. " "
                .. info.width
                .. "x"
                .. info.height
                .. "\n"
                .. (accepted and addon.L["Verify pixels"] or addon.L["Missing texture"])
        )
        tile.label:SetTextColor(1, accepted and 1 or 0.2, accepted and 1 or 0.2)
    end
    self.visualPanel:Show()
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
    "UNIT_FACTION",
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
    -- Blizzard may reset portrait/bar alpha in its own OnUpdate, after the last unit event.
    -- Touch only visual alpha; never unregister native events or replace secure handlers.
    for _, entry in pairs(UF.entries) do
        if entry.suppressed then
            for region in pairs(entry.alphas) do
                if region:GetAlpha() ~= 0 then
                    region:SetAlpha(0)
                end
            end
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
