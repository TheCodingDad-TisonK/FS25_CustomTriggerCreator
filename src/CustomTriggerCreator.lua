-- =========================================================
-- CustomTriggerCreator.lua — FS25_CustomTriggerCreator
-- Central coordinator. Owns all subsystems.
-- Global reference: g_CTCSystem
-- =========================================================

CustomTriggerCreator = {}
CustomTriggerCreator._mt = { __index = CustomTriggerCreator }

---Create the CustomTriggerCreator system.
---@param mission      table   Current mission object
---@param modDirectory string  Path to mod folder (with trailing slash)
---@param modName      string
---@return CustomTriggerCreator
function CustomTriggerCreator.new(mission, modDirectory, modName)
    local self = setmetatable({}, CustomTriggerCreator._mt)

    self.mission      = mission
    self.modDirectory = modDirectory
    self.modName      = modName
    self.initialized  = false

    -- Subsystems
    self.settings            = CTSettings.new()
    self.settingsIntegration = CTSettingsIntegration.new(self.settings)
    self.markerDetector      = MarkerDetector.new(self.settings)

    -- HUD proximity hint state
    self._lastHintVisible = false

    Logger.info("CustomTriggerCreator created (v" .. (modName or "?") .. ")")
    return self
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

---Called after mission load finishes (dialogs, map, etc. are ready).
function CustomTriggerCreator:onMissionLoaded()
    if self.initialized then return end

    -- Register settings integration
    self.settingsIntegration:register()

    -- Sync debug flag from settings
    Logger.setDebug(self.settings.debugMode)

    -- Init marker detector
    self.markerDetector:initialize()

    self.initialized = true
    Logger.info("Initialized — ready (Phase 1)")
end

---Per-frame update. Called from FSBaseMission.update hook.
---@param dt number  Delta time in ms
function CustomTriggerCreator:update(dt)
    if not self.initialized then return end
    if not self.settings.enabled then return end

    -- Tick marker detector
    self.markerDetector:update(dt)

    -- Phase 1: plain-text HUD proximity hint (no custom UI yet)
    self:_updateProximityHint()
end

---Per-frame draw. Called from FSBaseMission.draw hook.
function CustomTriggerCreator:draw()
    -- Phase 1: nothing to draw yet
end

---Handle a live setting change.
---@param key   string
---@param value any
function CustomTriggerCreator:onSettingChanged(key, value)
    Logger.module("CTC", "Setting changed: " .. tostring(key))

    if key == CTSettings.KEYS.DETECTION_RADIUS then
        -- Radius changed — marker cache radiusSq auto-recomputes via getter
        Logger.debug("Detection radius updated to " .. tostring(value) .. "m")
    end
end

---Clean up all subsystems. Called from FSBaseMission.delete hook.
function CustomTriggerCreator:delete()
    if self.settingsIntegration then
        self.settingsIntegration:delete()
    end
    if self.markerDetector then
        self.markerDetector:delete()
    end
    self.initialized = false
    Logger.info("Deleted — cleanup complete")
end

-- ---------------------------------------------------------------------------
-- Save / Load
-- ---------------------------------------------------------------------------

---Save state to the mod's XML file.
---@param xmlFile  table  XMLFile handle
function CustomTriggerCreator:saveToXML(xmlFile)
    if not xmlFile then return end
    self.settings:saveToXML(xmlFile)
    Logger.module("CTC", "Saved to XML")
end

---Load state from the mod's XML file.
---@param xmlFile  table  XMLFile handle
function CustomTriggerCreator:loadFromXML(xmlFile)
    if not xmlFile then return end
    self.settings:loadFromXML(xmlFile)
    Logger.setDebug(self.settings.debugMode)
    Logger.module("CTC", "Loaded from XML")
end

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

---Show or hide the proximity hint in the base-game HUD input help.
function CustomTriggerCreator:_updateProximityHint()
    local near = self.markerDetector:isNearMarker()

    if near == self._lastHintVisible then return end
    self._lastHintVisible = near

    if near then
        local label = self.markerDetector:getNearbyLabel() or "marker"
        Logger.debug("Near " .. label .. " — [F8] to open trigger creator")
        -- Phase 2 will wire this into the proper RVB action-event system
        -- so the game renders the keybind hint automatically.
    else
        Logger.debug("Left marker proximity")
    end
end
