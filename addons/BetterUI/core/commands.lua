-- BetterUI contributors, MIT. See THIRD_PARTY_NOTICES.md.
local _, addon = ...
function addon:Diagnostics()
    local version, build, date, interface = GetBuildInfo()
    self:Print(
        "version="
            .. tostring(version)
            .. " build="
            .. tostring(build)
            .. " interface="
            .. tostring(interface)
            .. " date="
            .. tostring(date)
    )
    self:Print(
        "addon="
            .. self.version
            .. " initialized="
            .. tostring(self.state.initialized)
            .. " login="
            .. tostring(self.state.login)
            .. " enabled="
            .. tostring(self.state.enabled)
            .. " options="
            .. tostring(self.state.options)
            .. " locale="
            .. self.locale
            .. " pendingReload="
            .. tostring(self.state.pendingReload or false)
    )
    if self.db then
        self:Print(
            "profile="
                .. self.db:GetCurrentProfile()
                .. " schema="
                .. tostring(self.db.sv.schema)
                .. " char.logins="
                .. tostring(self.db.char.logins)
                .. " queued="
                .. #self.CombatQueue.order
        )
    end
    for _, id in ipairs(self.ModuleRegistry.order) do
        self:Print(id .. "=" .. self.ModuleRegistry.entries[id].state)
    end
    if self.UnitFrames then
        self.UnitFrames:PrintVisualDiagnostics()
    end
    self:Print(
        "client test: UNTESTED; combat="
            .. tostring(InCombatLockdown())
            .. " error="
            .. tostring(self.lastError or self.disabledReason or "none")
    )
end
function addon:Slash(input)
    local command = (input or ""):match("^%s*(%S*)"):lower()
    if command == "diag" or command == "status" then
        self:Diagnostics()
    elseif command == "" or command == "config" then
        self:ToggleOptionsUI()
    elseif command == "edit" then
        if self.Editor.active then
            self.Editor:Finish(true)
        else
            if self:ToggleOptionsUI(true) then
                self.Editor:Start()
            end
        end
    elseif command == "reset" then
        self:ResetPositions()
    elseif command == "ufdiag" then
        self.UnitFrames:ShowVisualDiagnostics()
    else
        self:Print("/betterui [config | edit | reset | diag | ufdiag]")
    end
end
