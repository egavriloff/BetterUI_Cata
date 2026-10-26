-- BetterUI contributors, MIT. DragonUI normal skin contracts at 82a6c52; see THIRD_PARTY_NOTICES.md.
local _, addon = ...
local V = { assets = {}, failures = {} }
addon.UnitFrameVisuals = V
local ROOT = "Interface\\AddOns\\BetterUI\\Textures\\UnitFrames\\"
local function asset(key, file, width, height)
    V.assets[#V.assets + 1] = { key = key, path = ROOT .. file, width = width, height = height }
    V.assets[key] = V.assets[#V.assets]
end
for _, unit in ipairs({ "Player", "Target" }) do
    for _, part in ipairs({ "BACKGROUND", "BORDER" }) do
        asset(unit .. part, "HD\\" .. unit .. "-" .. part .. ".tga", 512, 256)
    end
    for _, power in ipairs({ "Health", "Mana", "Rage", "Focus", "Energy", "RunicPower" }) do
        asset(
            unit .. power,
            "Bars\\UI-HUD-UnitFrame-" .. unit .. "-PortraitOn-Bar-" .. power .. ".tga",
            128,
            power == "Health" and 32 or 16
        )
    end
end
asset("Dragons", "uiunitframeboss2x.blp", 512, 512)
asset("NameStrip", "HD\\Target-NameStrip.tga", 512, 256)
asset("Corner", "Player\\ui-hud-unitframe-player-portraiton-cornerembellishment-2x.blp", 64, 64)
asset("PlayerCombat", "Forever\\Player-InCombat.tga", 512, 256)
asset("DecoratedCombat", "Forever\\Target-InCombat.tga", 512, 256)
asset("TargetCombat", "Target\\ui-hud-unitframe-target-portraiton-incombat-2x.blp", 512, 256)
V.dragons = {
    elite = { tc = { 0.001953125, 0.314453125, 0.322265625, 0.630859375 }, w = 80, h = 79, x = 4.75 },
    rare = { tc = { 0.00390625, 0.31640625, 0.64453125, 0.953125 }, w = 80, h = 79, x = 4.75 },
    rareelite = { tc = { 0.001953125, 0.388671875, 0.001953125, 0.31835937 }, w = 99, h = 81, x = 13.75 },
}
function V:Bind(region, key)
    local info = assert(self.assets[key], "Unknown unit-frame asset")
    local accepted = region:SetTexture(info.path)
    -- A retained path is not proof of decoded pixels. The gallery provides that check.
    local missing = accepted == false or not region:GetTexture()
    region.visualAsset, region.visualAccepted = key, accepted
    if missing and not self.failures[key] then
        addon:Error("Unit frame texture missing/rejected: " .. info.path)
    end
    self.failures[key] = missing or nil
    return not missing
end
function V:Size(entry, key, object, width, height)
    object:SetSize(width, height)
    entry.visualChecks[key] = { object = object, width = width, height = height }
end
local function anchor(object, point, relative, relativePoint, x, y)
    object:ClearAllPoints()
    object:SetPoint(point, relative, relativePoint, x, y)
end
local function font(parent, style)
    local label = parent:CreateFontString(nil, "OVERLAY", style or "GameFontNormalSmall")
    label:SetJustifyH("CENTER")
    return label
end
local function layer(parent, level)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    frame:SetFrameLevel(level)
    frame:EnableMouse(false)
    return frame
end
function V:BarTexture(frame, key)
    if frame.visualKey ~= key or not frame:GetStatusBarTexture() then
        frame:SetStatusBarTexture(self.assets[key].path)
        local fill = frame:GetStatusBarTexture()
        if fill then
            self:Bind(fill, key)
        elseif not self.failures[key] then
            self.failures[key] = true
            addon:Error("Unit frame status texture missing: " .. self.assets[key].path)
        end
        frame.visualKey = key
    end
    local fill = frame:GetStatusBarTexture()
    if fill then
        fill:SetDrawLayer("ARTWORK", 1)
    end
    -- The imported fills contain their own color and shading. Never multiply them green/blue.
    frame:SetStatusBarColor(1, 1, 1)
end
function V:Crop(frame, current, maximum)
    local fill = frame:GetStatusBarTexture()
    if fill then
        fill:SetTexCoord(0, maximum > 0 and math.max(0, math.min(1, current / maximum)) or 0, 0, 1)
    end
end
function V:Create(entry)
    local skin = CreateFrame("Frame", nil, entry.frame)
    entry.skin, entry.visualChecks = skin, {}
    skin:SetSize(232, 100)
    skin:SetPoint("TOPLEFT", entry.frame, "TOPLEFT", 0, 0)
    skin:SetFrameLevel(entry.frame:GetFrameLevel())
    skin:EnableMouse(false)
    local base = skin:GetFrameLevel()
    entry.background = skin:CreateTexture(nil, "BACKGROUND", nil, -7)
    local portraitLayer = layer(skin, base + 1)
    entry.portrait = portraitLayer:CreateTexture(nil, "ARTWORK", nil, 2)
    for _, kind in ipairs({ "health", "power" }) do
        entry[kind] = CreateFrame("StatusBar", nil, skin)
        entry[kind]:SetFrameLevel(base)
        entry[kind]:EnableMouse(false)
    end
    local foreground = layer(skin, base + 1)
    entry.foreground = foreground
    entry.border = foreground:CreateTexture(nil, "OVERLAY", nil, 5)
    entry.corner = foreground:CreateTexture(nil, "ARTWORK")
    self:Bind(entry.corner, "Corner")
    entry.corner:SetTexCoord(0, 44 / 64, 0, 44 / 64)
    entry.corner:SetSize(23, 23)
    anchor(entry.corner, "CENTER", entry.portrait, "CENTER", 16.5, -16.5)
    -- Own noninteractive contour above the border, below dragon and text layers.
    local combatLayer = layer(skin, base + 1)
    entry.combat = combatLayer:CreateTexture(nil, "OVERLAY", nil, 6)
    entry.combat:SetVertexColor(1, 0, 0)
    entry.combat:Hide()
    local dragonLayer = layer(skin, base + 2)
    entry.dragon = dragonLayer:CreateTexture(nil, "ARTWORK", nil, 1)
    self:Bind(entry.dragon, "Dragons")
    local labels = layer(skin, base + 3)
    entry.name, entry.level = font(labels), font(labels)
    for _, kind in ipairs({ "health", "power" }) do
        local bar = entry[kind]
        bar.label = font(labels, "TextStatusBarText")
        local path, size, flags = bar.label:GetFont()
        if path and size then
            bar.label:SetFont(path, size + 1, flags)
        end
        anchor(bar.label, "CENTER", bar, "CENTER", 0, 0)
    end
    entry.nameStrip = skin:CreateTexture(nil, "BORDER", nil, 1)
    self:Bind(entry.nameStrip, "NameStrip")
    entry.nameStrip:SetBlendMode("ADD")
end
function V:Layout(entry, player, decorated)
    assert(not InCombatLockdown(), "Unit frame layout cannot change in combat")
    entry.visualChecks = {}
    local portrait, health, power = entry.portrait, entry.health, entry.power
    self:Size(entry, "portrait", portrait, player and 56 or 54, player and 56 or 54)
    portrait:SetTexCoord(0, 1, 0, 1)
    anchor(
        portrait,
        player and "TOPLEFT" or "TOPRIGHT",
        entry.skin,
        player and "TOPLEFT" or "TOPRIGHT",
        player and 42 or -48.75,
        player and -15 or -14.75
    )
    if player then
        local mirror = decorated
        self:Size(entry, "health", health, mirror and 127 or 125, 20)
        self:Size(entry, "power", power, mirror and 131 or 125, 9)
        anchor(health, "LEFT", portrait, "RIGHT", mirror and -1 or 2, mirror and -1.5 or -1)
        anchor(power, mirror and "RIGHT" or "LEFT", portrait, "RIGHT", mirror and 126 or 2, mirror and -17.5 or -17)
        self:Bind(entry.background, mirror and "TargetBACKGROUND" or "PlayerBACKGROUND")
        self:Bind(entry.border, mirror and "TargetBORDER" or "PlayerBORDER")
        for _, region in ipairs({ entry.background, entry.border }) do
            self:Size(entry, region == entry.border and "border" or "background", region, 256, 128)
            region:SetTexCoord(mirror and 1 or 0, mirror and 0 or 1, 0, 1)
            anchor(region, "LEFT", health, "LEFT", mirror and -126.5 or -67, mirror and -30.5 or -28)
        end
        entry.corner:SetAlpha(mirror and 0 or 1)
        anchor(
            entry.name,
            mirror and "BOTTOM" or "BOTTOMLEFT",
            health,
            mirror and "TOP" or "TOPLEFT",
            mirror and 1.5 or 12,
            2
        )
        entry.name:SetJustifyH(mirror and "CENTER" or "LEFT")
        entry.name:SetWidth(90)
        anchor(entry.level, "BOTTOMRIGHT", health, "TOPRIGHT", mirror and -4 or -5, 3)
        entry.nameStrip:SetAlpha(0)
    else
        self:Size(entry, "health", health, 126, 20)
        self:Size(entry, "power", power, 133, 9.5)
        anchor(health, "RIGHT", portrait, "LEFT", -1.25, -2.25)
        anchor(power, "RIGHT", portrait, "LEFT", 6.25, -18.75)
        self:Bind(entry.background, "TargetBACKGROUND")
        self:Bind(entry.border, "TargetBORDER")
        self:Size(entry, "background", entry.background, 256, 128)
        self:Size(entry, "border", entry.border, 256, 128)
        anchor(entry.background, "TOPLEFT", entry.skin, "TOPLEFT", -0.5, -10.5)
        anchor(entry.border, "TOPLEFT", entry.background, "TOPLEFT", 0, 0)
        entry.background:SetTexCoord(0, 1, 0, 1)
        entry.border:SetTexCoord(0, 1, 0, 1)
        entry.corner:SetAlpha(0)
        anchor(entry.name, "BOTTOM", health, "TOP", 10, 3)
        entry.name:SetJustifyH("CENTER")
        entry.name:SetWidth(100)
        anchor(entry.level, "BOTTOMRIGHT", health, "TOPLEFT", 18, 3)
        self:Size(entry, "nameStrip", entry.nameStrip, 134, 15.5)
        anchor(entry.nameStrip, "BOTTOMLEFT", health, "TOPLEFT", -0.5, -0.5)
        entry.nameStrip:SetAlpha(1)
        anchor(power.label, "CENTER", power, "CENTER", -2, 0)
    end
    entry.level:SetWidth(24)
    self:Size(entry, "corner", entry.corner, 23, 23)
    entry.health.label:SetWidth(health:GetWidth() - 12)
    entry.power.label:SetWidth(power:GetWidth() - (player and 12 or 26))
    self:Bind(entry.combat, player and (decorated and "DecoratedCombat" or "PlayerCombat") or "TargetCombat")
    if player then
        self:Size(entry, "combat", entry.combat, decorated and 188 or 192, decorated and 67 or 71)
        entry.combat:SetTexCoord(
            decorated and 376 / 512 or 0,
            decorated and 0 or 384 / 512,
            0,
            decorated and 134 / 256 or 142 / 256
        )
        anchor(entry.combat, "TOPLEFT", entry.background, "TOPLEFT", decorated and 66.5 or 1.5, decorated and 1.5 or 1)
    else
        self:Size(entry, "combat", entry.combat, 188, 67)
        entry.combat:SetTexCoord(0, 376 / 512, 0, 134 / 256)
        anchor(entry.combat, "BOTTOMLEFT", entry.skin, "BOTTOMLEFT", 1, 24)
    end
end
function V:Combat(entry, id, cfg, active, elapsed)
    local unit = entry.frame.unit or id
    local fighting = InCombatLockdown()
        and (id == "player" or (entry.frame.threatIndicator and entry.frame.threatIndicator:IsShown()))
    local alive = UnitExists(unit)
        and UnitIsConnected(unit)
        and not UnitIsDead(unit)
        and not UnitIsGhost(unit)
        and UnitHealth(unit) > 0
        and not UnitIsDead("player")
        and not UnitIsGhost("player")
    if
        not active
        or not cfg.enabled
        or not cfg.visible
        or cfg.combatHighlight == false
        or not fighting
        or not alive
        or (id == "player" and entry.frame.state == "vehicle")
    then
        entry.combat:Hide()
        entry.combatTimer = 0
        return
    end
    if id == "player" then
        -- DragonUI normal/decoration pulse: radians per second, independent of FPS.
        entry.combatTimer = ((entry.combatTimer or 0) + (elapsed or 0) * 9) % (2 * math.pi)
        local low, high = cfg.dragon and 0.2 or 0.3, cfg.dragon and 0.9 or 1
        entry.combat:SetAlpha(low + (high - low) * (math.sin(entry.combatTimer) * 0.5 + 0.5))
    else
        -- Donor target uses native threat visibility without the player's pulse.
        entry.combat:SetAlpha(1)
    end
    entry.combat:Show()
end
function V:Dragon(entry, player, classification)
    if classification == "worldboss" then
        classification = "rareelite"
    end
    local dragon = self.dragons[classification]
    if not dragon then
        entry.dragon:SetAlpha(0)
        return false
    end
    -- This is called only from out-of-combat Refresh or for texture-only classification changes.
    -- The independent cosmetic texture never anchors/moves a protected unit button.
    entry.dragon:SetSize(dragon.w, dragon.h)
    entry.visualChecks.dragon = { object = entry.dragon, width = dragon.w, height = dragon.h }
    local tc = dragon.tc
    if player then
        entry.dragon:SetTexCoord(tc[2], tc[1], tc[3], tc[4])
        anchor(entry.dragon, "TOPLEFT", entry.skin, "TOPLEFT", 25.5, -4)
    else
        entry.dragon:SetTexCoord(unpack(tc))
        anchor(entry.dragon, "CENTER", entry.portrait, "CENTER", dragon.x, -0.25)
    end
    return true
end
function V:NameColor(entry, r, g, b, tapDenied)
    local palette = { { 0, 0.44, 1 }, { 0, 1, 0 }, { 1, 0.5, 0 }, { 1, 0, 0 }, { 1, 1, 0 } }
    local row, distance = 5, 10
    for i, color in ipairs(palette) do
        local delta = (r - color[1]) ^ 2 + (g - color[2]) ^ 2 + (b - color[3]) ^ 2
        if delta < distance then
            row, distance = i, delta
        end
    end
    if tapDenied then
        row = 2
    end
    entry.nameStrip:SetTexCoord(0, 268 / 512, (row - 1) * 32 / 256, ((row - 1) * 32 + 31) / 256)
    entry.nameStrip:SetBlendMode(tapDenied and "BLEND" or "ADD")
    entry.nameStrip:SetDesaturated(tapDenied and true or false)
    local tint = tapDenied and 0.08 or 1
    entry.nameStrip:SetVertexColor(tint, tint, tint)
end
function V:Issues(entry)
    local issues = {}
    if
        not entry.background
        or not entry.border
        or not entry.dragon
        or not entry.corner
        or not entry.combat
        or not entry.health
        or not entry.power
    then
        return { "VISUAL INITIALIZATION INCOMPLETE" }
    end
    for key, check in pairs(entry.visualChecks or {}) do
        if
            math.abs(check.object:GetWidth() - check.width) > 0.01
            or math.abs(check.object:GetHeight() - check.height) > 0.01
        then
            issues[#issues + 1] = key .. " SIZE MISMATCH"
        end
    end
    for _, region in ipairs({
        entry.background,
        entry.border,
        entry.dragon,
        entry.corner,
        entry.combat,
    }) do
        if region and (region.visualAccepted == false or not region:GetTexture()) then
            issues[#issues + 1] = tostring(region.visualAsset) .. " TEXTURE MISSING/REJECTED"
        end
    end
    for _, key in ipairs({ "health", "power" }) do
        local region = entry[key]:GetStatusBarTexture()
        if not region or region.visualAccepted == false or not region:GetTexture() then
            issues[#issues + 1] = key .. " TEXTURE MISSING/REJECTED"
        end
    end
    return issues
end
