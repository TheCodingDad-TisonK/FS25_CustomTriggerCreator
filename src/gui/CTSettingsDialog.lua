-- =========================================================
-- CTSettingsDialog.lua — FS25_CustomTriggerCreator
-- In-game settings panel: toggle enabled/notifications/debug,
-- adjust detection radius and notification duration.
-- Opened via Settings button in CTManagementDialog.
-- =========================================================

CTSettingsDialog = {}
local CTSettingsDialog_mt = Class(CTSettingsDialog, MessageDialog)

function CTSettingsDialog.new(target, custom_mt)
    local self = MessageDialog.new(target, custom_mt or CTSettingsDialog_mt)
    return self
end

function CTSettingsDialog:onCreate()
    local ok, err = pcall(function() CTSettingsDialog:superClass().onCreate(self) end)
    if not ok then Logger.error("CTSettingsDialog:onCreate(): " .. tostring(err)) end
end

function CTSettingsDialog:onDialogOpen()
    local ok, err = pcall(function() CTSettingsDialog:superClass().onOpen(self) end)
    if not ok then Logger.error("CTSettingsDialog:onDialogOpen(): " .. tostring(err)) end
    self:_refresh()
end

function CTSettingsDialog:onDialogClose()
    local ok, err = pcall(function() CTSettingsDialog:superClass().onClose(self) end)
    if not ok then Logger.debug("CTSettingsDialog:onDialogClose(): " .. tostring(err)) end
end

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

function CTSettingsDialog:_getSettings()
    return g_CTCSystem and g_CTCSystem.settings
end

function CTSettingsDialog:_apply(key, value)
    if g_CTCSystem and g_CTCSystem.settingsIntegration then
        g_CTCSystem.settingsIntegration:applySetting(key, value)
    end
end

function CTSettingsDialog:_refresh()
    local s = self:_getSettings()
    if not s then return end

    local function setTog(id, val)
        local el = self[id]
        if el then el:setText(val and "ON" or "OFF") end
    end

    setTog("stEnabledTxt", s.enabled)
    setTog("stNotifTxt",   s.notificationsEnabled)
    setTog("stDebugTxt",   s.debugMode)

    if self.stRadiusValue   then self.stRadiusValue:setText(string.format("%.0f m", s.detectionRadius))   end
    if self.stDurationValue then self.stDurationValue:setText(string.format("%.0f s", s.notificationDuration)) end
end

-- ---------------------------------------------------------------------------
-- Toggle handlers
-- ---------------------------------------------------------------------------

function CTSettingsDialog:onToggleEnabled()
    local s = self:_getSettings()
    if not s then return end
    self:_apply(CTSettings.KEYS.ENABLED, not s.enabled)
    self:_refresh()
end

function CTSettingsDialog:onToggleNotif()
    local s = self:_getSettings()
    if not s then return end
    self:_apply(CTSettings.KEYS.NOTIFICATIONS, not s.notificationsEnabled)
    self:_refresh()
end

function CTSettingsDialog:onToggleDebug()
    local s = self:_getSettings()
    if not s then return end
    self:_apply(CTSettings.KEYS.DEBUG_MODE, not s.debugMode)
    self:_refresh()
end

-- ---------------------------------------------------------------------------
-- Stepper handlers
-- ---------------------------------------------------------------------------

function CTSettingsDialog:onRadiusDec()
    local s = self:_getSettings()
    if not s then return end
    self:_apply(CTSettings.KEYS.DETECTION_RADIUS, math.max(1, s.detectionRadius - 1))
    self:_refresh()
end

function CTSettingsDialog:onRadiusInc()
    local s = self:_getSettings()
    if not s then return end
    self:_apply(CTSettings.KEYS.DETECTION_RADIUS, math.min(20, s.detectionRadius + 1))
    self:_refresh()
end

function CTSettingsDialog:onDurationDec()
    local s = self:_getSettings()
    if not s then return end
    self:_apply(CTSettings.KEYS.NOTIF_DURATION, math.max(2, s.notificationDuration - 1))
    self:_refresh()
end

function CTSettingsDialog:onDurationInc()
    local s = self:_getSettings()
    if not s then return end
    self:_apply(CTSettings.KEYS.NOTIF_DURATION, math.min(15, s.notificationDuration + 1))
    self:_refresh()
end

-- ---------------------------------------------------------------------------
-- Button handlers
-- ---------------------------------------------------------------------------

function CTSettingsDialog:onClickSave()
    if g_CTCSystem and g_CTCSystem.notificationHUD then
        g_CTCSystem.notificationHUD:push("Settings", "Settings saved.", "SUCCESS")
    end
    self:close()
end

function CTSettingsDialog:onClickClose()
    self:close()
end
