-- =========================================================
-- CustomTriggerCreator.lua — FS25_CustomTriggerCreator
-- Central coordinator. Owns all subsystems.
-- Global reference: g_CTCSystem
-- =========================================================

CustomTriggerCreator = {}
CustomTriggerCreator._mt = { __index = CustomTriggerCreator }

---Create the CustomTriggerCreator system.
---@param mission      table
---@param modDirectory string
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
    self.triggerRegistry     = TriggerRegistry.new(self.settings)
    self.triggerSerializer   = TriggerSerializer.new(self.triggerRegistry)

    self._lastHintVisible = false

    Logger.info("CustomTriggerCreator created")
    return self
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

function CustomTriggerCreator:onMissionLoaded()
    if self.initialized then return end

    self.settingsIntegration:register()
    Logger.setDebug(self.settings.debugMode)
    self.markerDetector:initialize()

    self.initialized = true
    Logger.info("Initialized — ready (Phase 2)")
end

function CustomTriggerCreator:update(dt)
    if not self.initialized or not self.settings.enabled then return end
    self.markerDetector:update(dt)
    self:_updateProximityHint()
end

function CustomTriggerCreator:draw()
    -- Phase 2: nothing additional to draw
end

function CustomTriggerCreator:onSettingChanged(key, value)
    Logger.module("CTC", "Setting changed: " .. tostring(key))
    if key == CTSettings.KEYS.DEBUG_MODE then
        Logger.setDebug(value)
    end
end

function CustomTriggerCreator:delete()
    if self.settingsIntegration then self.settingsIntegration:delete() end
    if self.markerDetector       then self.markerDetector:delete()      end
    self.initialized = false
    Logger.info("Deleted — cleanup complete")
end

-- ---------------------------------------------------------------------------
-- Creator UI
-- ---------------------------------------------------------------------------

---Open the trigger creator (F8 handler).
function CustomTriggerCreator:openCreator()
    Logger.module("CTC", "Opening creator")
    DialogLoader.show("CTManagementDialog")
end

-- ---------------------------------------------------------------------------
-- Save / Load
-- ---------------------------------------------------------------------------

function CustomTriggerCreator:saveToXML(xmlFile)
    if not xmlFile then return end
    self.settings:saveToXML(xmlFile)
    self.triggerSerializer:save(xmlFile)
    Logger.module("CTC", "Saved to XML")
end

function CustomTriggerCreator:loadFromXML(xmlFile)
    if not xmlFile then return end
    self.settings:loadFromXML(xmlFile)
    Logger.setDebug(self.settings.debugMode)
    self.triggerSerializer:load(xmlFile)
    Logger.module("CTC", "Loaded from XML — " .. self.triggerRegistry:count() .. " trigger(s)")
end

-- ---------------------------------------------------------------------------
-- Internal
-- ---------------------------------------------------------------------------

function CustomTriggerCreator:_updateProximityHint()
    local near = self.markerDetector:isNearMarker()
    if near == self._lastHintVisible then return end
    self._lastHintVisible = near

    if near then
        local label = self.markerDetector:getNearbyLabel() or "marker"
        Logger.debug("Near " .. label .. " — [F8] Open Trigger Creator")
    else
        Logger.debug("Left marker proximity")
    end
end
