-- BetterUI contributors, MIT. DragonUI profile/editor UX adaptation; see THIRD_PARTY_NOTICES.md.
local addon = BetterUI
local Panel, C, L = addon.OptionsPanel, addon.PanelControls, addon.L
local frame = CreateFrame("Frame", "BetterUI_OptionsFrame", UIParent)
Panel.frame = frame
frame:SetSize(740,640); frame:SetFrameStrata("DIALOG"); addon.StyleWindow(frame)
addon:RegisterEditableFrame("window", frame)
frame:Hide()
C.Label(frame, "BetterUI " .. addon.version .. " — " .. L["Settings"], 24,-20)
C.Button(frame,"Close", 590,-14,120,function()
    if addon.Editor.active then addon.Editor:Finish(true) end
    frame:Hide()
end)
frame:SetScript("OnShow", function() Panel:Refresh() end)
frame:SetScript("OnHide", function()
    if addon.Editor.active and not InCombatLockdown() then addon.Editor:Finish(false) end
end)
tinsert(UISpecialFrames, "BetterUI_OptionsFrame")
Panel.updaters = {}
local function track(control) Panel.updaters[#Panel.updaters+1] = control; return control end
Panel:RegisterTab("general", "Settings", function(page)
    C.Label(page, addon.LO.intro, 0,0)
    track(C.Check(page,"Show diagnostic widget",0,-60,
        function() return addon.db.profile.widget.enabled end,function(on) addon:SetWidgetEnabled(on) end))
    track(C.Check(page,"Show grid",0,-100,
        function() return addon.db.profile.editorShowGrid end,function(on)
            if addon:CanChange() then addon.db.profile.editorShowGrid=on; addon:RefreshConfig() end
        end))
    track(C.Slider(page,"Scale",0,-135,function() return addon.db.profile.widget.scale end,function(value)
        if addon:CanChange() then addon.db.profile.widget.scale=value; addon:RefreshConfig() end
    end))
    track(C.Slider(page,"Window scale",0,-205,function() return addon.db.profile.window.scale end,function(value)
        if addon:CanChange() then addon.db.profile.window.scale=value; addon:RefreshConfig() end
    end))
    C.Label(page,L["Edit the widget or settings window; Save commits, Cancel restores."],0,-275)
    C.Button(page,"Edit Mode",0,-310,170,function() addon.Editor:Start() end)
    C.Button(page,"Save",185,-310,130,function() addon.Editor:Finish(true) end)
    C.Button(page,"Cancel",330,-310,130,function() addon.Editor:Finish(false) end)
    C.Button(page,"Reset",475,-310,130,function() addon:ResetPositions() end)
    C.Label(page,L["Language"],0,-355)
    for index, locale in ipairs({"auto","enUS","ruRU"}) do
        local choice = locale
        C.Button(page,locale,(index-1)*185,-385,170,function() C.Result(addon:SetLocale(choice)) end)
    end
    C.Button(page,"Diagnostics",0,-430,170,function() addon:Diagnostics() end)
end)
Panel:RegisterTab("profiles", "Profiles", function(page)
    C.Label(page,addon.LO.names,0,0)
    local input = C.Input(page,0,-40,360)
    C.Button(page,"Create / select",390,-40,220,function() C.Result(addon:ProfileAction("select",input:GetText())) end)
    C.Button(page,"Copy from",0,-85,190,function()
        local name=input:GetText(); C.Confirm(function() C.Result(addon:ProfileAction("copy",name)) end)
    end)
    C.Button(page,"Delete profile",205,-85,190,function()
        local name=input:GetText(); C.Confirm(function() C.Result(addon:ProfileAction("delete",name)) end)
    end)
    C.Button(page,"Reset profile",410,-85,200,function()
        C.Confirm(function() C.Result(addon:ProfileAction("reset")) end)
    end)
    Panel.profileList=C.Label(page,"",0,-140)
    C.Label(page,L["Default for new characters"],0,-260)
    C.Button(page,"Use current profile",0,-300,250,function() C.Result(addon:ProfileAction("default",true)) end)
    C.Button(page,"Per-character profiles",270,-300,270,function() C.Result(addon:ProfileAction("default",false)) end)
    Panel.defaultLabel=C.Label(page,"",0,-355)
end)
Panel:RegisterTab("layouts", "Layout", function(page)
    local input=C.Input(page,0,0,240)
    C.Button(page,"Save layout",250,0,130,function()
        local name=input:GetText(); C.Confirm(function() C.Result(addon:LayoutAction("save",name)) end)
    end)
    C.Button(page,"Load layout",390,0,130,function()
        local name=input:GetText(); C.Confirm(function() C.Result(addon:LayoutAction("load",name)) end)
    end)
    C.Button(page,"Delete layout",530,0,140,function()
        local name=input:GetText(); C.Confirm(function() C.Result(addon:LayoutAction("delete",name)) end)
    end)
    Panel.layoutList=C.Label(page,"",0,-40)
    C.Label(page,addon.LO.presets,0,-100)
    local sf=CreateFrame("ScrollFrame","BetterUI_PresetScroll",page,"UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",page,"TOPLEFT",0,-180); sf:SetSize(630,210)
    local box=CreateFrame("EditBox",nil,sf)
    box:SetMultiLine(true); box:SetAutoFocus(false); box:SetFontObject("GameFontHighlight")
    box:SetWidth(610); box:SetHeight(210); box:SetMaxLetters(16384)
    box:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    sf:SetScrollChild(box)
    C.Label(page,L["Paste a BetterUI preset, then Import."],0,-145)
    C.Button(page,"Export settings",0,-415,190,function()
        local text=addon:ExportPreset("settings"); box:SetText(text); box:HighlightText(); box:SetFocus()
    end)
    C.Button(page,"Export positions",200,-415,190,function()
        local text=addon:ExportPreset("positions"); box:SetText(text); box:HighlightText(); box:SetFocus()
    end)
    C.Button(page,"Import",400,-415,150,function()
        local text=box:GetText(); C.Confirm(function() C.Result(addon:ImportPreset(text)) end)
    end)
end)
for index,id in ipairs(Panel.order) do
    local key,tab=id,Panel.tabs[id]
    tab.page=CreateFrame("Frame",nil,frame)
    tab.page:SetPoint("TOPLEFT",frame,"TOPLEFT",30,-115); tab.page:SetSize(680,480)
    tab.build(tab.page); tab.page:Hide()
    C.Button(frame,tab.title,25+(index-1)*230,-65,220,function() Panel:Select(key) end)
end
Panel.currentProfile=C.Label(frame,"",30,-600)
function Panel:Select(id)
    self.selected=id
    for key,tab in pairs(self.tabs) do if key==id then tab.page:Show() else tab.page:Hide() end end
    self:Refresh()
end
function Panel:Refresh()
    if not addon.db then return end
    addon.Editor:Apply("window")
    for _,control in ipairs(self.updaters) do control:UpdateValue() end
    local names=addon.db:GetProfiles(); table.sort(names)
    if self.profileList then self.profileList:SetText(table.concat(names," | ")) end
    if self.defaultLabel then self.defaultLabel:SetText(L["Default for new characters"] .. ": " .. addon.db.global.defaultProfile) end
    local layouts={}; for name in pairs(addon.db.profile.layouts) do layouts[#layouts+1]=name end; table.sort(layouts)
    if self.layoutList then self.layoutList:SetText(table.concat(layouts," | ")) end
    if self.currentProfile then self.currentProfile:SetText(L["Profile"] .. ": " .. addon.db:GetCurrentProfile()
        .. (addon.Editor.active and " | " .. L["Edit Mode"] or "")) end
end
Panel:Select("general")
Panel.ready, addon.state.options = true, true
