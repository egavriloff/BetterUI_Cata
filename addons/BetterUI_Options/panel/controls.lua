-- BetterUI contributors, MIT. Native 4.3.4 controls; no donor controls/NotPlater copied.
local addon, C = BetterUI, {}
addon.PanelControls = C
function C.Label(parent, text, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetWidth(width or 660); label:SetJustifyH("LEFT"); label:SetText(text)
    return label
end
function C.Button(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 150, 26); button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetText(addon.L[text]); button:SetScript("OnClick", function() callback() end)
    return button
end
function C.Input(parent, x, y, width)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetFontObject("GameFontHighlight"); box:SetSize(width or 260, 28)
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); box:SetAutoFocus(false); box:SetMaxLetters(48)
    box:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3} })
    box:SetBackdropColor(0,0,0,1); box:SetTextInsets(8,8,0,0)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end
function C.Check(parent, text, x, y, get, set)
    local button = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    button:SetSize(26,26); button:SetPoint("TOPLEFT", parent, "TOPLEFT", x,y)
    local label = C.Label(parent, addon.L[text], x+32, y-5, 570)
    button:SetScript("OnClick", function(self)
        set(self:GetChecked() and true or false); self:SetChecked(get())
    end)
    button.UpdateValue = function(self) self:SetChecked(get()) end
    return button, label
end
function C.Slider(parent, text, x, y, get, set)
    local label = C.Label(parent, addon.L[text], x,y,300)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetPoint("TOPLEFT", parent,"TOPLEFT",x,y-30); slider:SetSize(420,18)
    slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(0.5,1.5); slider:SetValueStep(0.05)
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:SetBackdrop({ bgFile="Interface\\Buttons\\UI-SliderBar-Background", edgeFile="Interface\\Buttons\\UI-SliderBar-Border",
        tile=true,tileSize=8,edgeSize=8,insets={left=3,right=3,top=3,bottom=3} })
    slider:SetScript("OnValueChanged", function(self, value)
        if self.updating then return end
        set(math.floor(value*20+0.5)/20)
        self:UpdateValue()
    end)
    slider.UpdateValue = function(self)
        self.updating = true; self:SetValue(get()); self.updating = false
        label:SetText(addon.L[text] .. ": " .. string.format("%.2f", get()))
    end
    return slider
end
function C.Result(ok, reason)
    if not ok and reason then addon:Error(addon.L[reason]) end
    if addon.OptionsPanel then addon.OptionsPanel:Refresh() end
end
StaticPopupDialogs["BETTERUI_CONFIRM"] = {
    text = addon.L["This action replaces or removes saved settings. Continue?"],
    button1 = addon.L["Confirm"], button2 = addon.L["Cancel"],
    OnAccept = function(self) if self.data then self.data() end end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
function C.Confirm(callback)
    if not addon:CanChange() then return end
    local popup = StaticPopup_Show("BETTERUI_CONFIRM")
    if popup then
        local profile = addon.db:GetCurrentProfile()
        popup.data = function()
            if not addon:CanChange() then return end
            if addon.db:GetCurrentProfile() ~= profile then addon:Error(addon.L["Profile changed; reopen the confirmation."]); return end
            callback()
        end
    end
end
