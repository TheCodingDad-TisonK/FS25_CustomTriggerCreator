-- =========================================================
-- CTSettingsIntegration.lua — FS25_CustomTriggerCreator
-- Hooks into the FS25 in-game settings UI.
-- Phase 1: skeleton only — full settings frame comes in Phase 2.
-- =========================================================

CTSettingsIntegration = {}
CTSettingsIntegration._mt = { __index = CTSettingsIntegration }

---Create a new CTSettingsIntegration instance.
---@param settings CTSettings
---@return CTSettingsIntegration
function CTSettingsIntegration.new(settings)
    local self = setmetatable({}, CTSettingsIntegration._mt)
    self.settings = settings
    self.registered = false
    return self
end

---Register the settings frame with the game settings UI.
---Called after mission load when g_gui is available.
function CTSettingsIntegration:register()
    if self.registered then return end

    -- Phase 1: placeholder — full CTSettingsFrame integration in Phase 2
    Logger.module("CTSettingsIntegration", "Settings integration registered (Phase 1 skeleton)")
    self.registered = true
end

---Apply a setting change and propagate to live systems.
---@param key   string  Setting key from CTSettings.KEYS
---@param value any
function CTSettingsIntegration:applySetting(key, value)
    if not self.settings then return end

    self.settings[key] = value
    Logger.module("CTSettingsIntegration", "Setting applied: " .. tostring(key) .. " = " .. tostring(value))

    -- Propagate debug flag to Logger immediately
    if key == CTSettings.KEYS.DEBUG_MODE then
        Logger.setDebug(value)
    end

    -- Notify coordinator if available
    if g_CTCSystem and g_CTCSystem.onSettingChanged then
        g_CTCSystem:onSettingChanged(key, value)
    end
end

---Clean up.
function CTSettingsIntegration:delete()
    self.registered = false
    Logger.module("CTSettingsIntegration", "Cleaned up")
end
