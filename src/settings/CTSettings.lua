-- =========================================================
-- CTSettings.lua — FS25_CustomTriggerCreator
-- Settings data model. All defaults live here.
-- =========================================================

CTSettings = {}
CTSettings._mt = { __index = CTSettings }

-- Setting keys (used for save/load and settings UI)
CTSettings.KEYS = {
    ENABLED            = "enabled",
    ACTIVATION_KEY     = "activationKey",
    DETECTION_RADIUS   = "detectionRadius",
    NOTIFICATIONS      = "notificationsEnabled",
    NOTIF_DURATION     = "notificationDuration",
    MAX_TRIGGERS       = "maxTriggersPerSave",
    SHOW_ZONES         = "showTriggerZones",
    ADMIN_MODE         = "adminMode",
    DEBUG_MODE         = "debugMode",
}

-- Defaults
CTSettings.DEFAULTS = {
    enabled            = true,
    detectionRadius    = 5.0,     -- metres
    notificationsEnabled = true,
    notificationDuration = 4.0,   -- seconds
    maxTriggersPerSave = 100,
    showTriggerZones   = true,
    adminMode          = false,
    debugMode          = false,
}

---Create a new CTSettings instance with default values.
---@return CTSettings
function CTSettings.new()
    local self = setmetatable({}, CTSettings._mt)
    self:reset()
    return self
end

---Reset all settings to defaults.
function CTSettings:reset()
    for k, v in pairs(CTSettings.DEFAULTS) do
        self[k] = v
    end
end

---Load settings from an XML file.
---@param xmlFile  table   XMLFile handle (FS25 XMLFile object)
function CTSettings:loadFromXML(xmlFile)
    if not xmlFile then return end
    local p = "CustomTriggerCreator.settings"

    self.enabled              = Utils.getNoNil(xmlFile:getBool(p .. "#enabled"),               self.enabled)
    self.detectionRadius      = Utils.getNoNil(xmlFile:getFloat(p .. "#detectionRadius"),      self.detectionRadius)
    self.notificationsEnabled = Utils.getNoNil(xmlFile:getBool(p .. "#notificationsEnabled"),  self.notificationsEnabled)
    self.notificationDuration = Utils.getNoNil(xmlFile:getFloat(p .. "#notificationDuration"), self.notificationDuration)
    self.maxTriggersPerSave   = Utils.getNoNil(xmlFile:getInt(p .. "#maxTriggersPerSave"),     self.maxTriggersPerSave)
    self.showTriggerZones     = Utils.getNoNil(xmlFile:getBool(p .. "#showTriggerZones"),      self.showTriggerZones)
    self.adminMode            = Utils.getNoNil(xmlFile:getBool(p .. "#adminMode"),             self.adminMode)
    self.debugMode            = Utils.getNoNil(xmlFile:getBool(p .. "#debugMode"),             self.debugMode)

    Logger.module("CTSettings", "Loaded from XML")
end

---Save settings to an XML file.
---@param xmlFile  table   XMLFile handle (FS25 XMLFile object)
function CTSettings:saveToXML(xmlFile)
    if not xmlFile then return end
    local p = "CustomTriggerCreator.settings"

    xmlFile:setBool(p .. "#enabled",               self.enabled)
    xmlFile:setFloat(p .. "#detectionRadius",      self.detectionRadius)
    xmlFile:setBool(p .. "#notificationsEnabled",  self.notificationsEnabled)
    xmlFile:setFloat(p .. "#notificationDuration", self.notificationDuration)
    xmlFile:setInt(p .. "#maxTriggersPerSave",     self.maxTriggersPerSave)
    xmlFile:setBool(p .. "#showTriggerZones",      self.showTriggerZones)
    xmlFile:setBool(p .. "#adminMode",             self.adminMode)
    xmlFile:setBool(p .. "#debugMode",             self.debugMode)

    Logger.module("CTSettings", "Saved to XML")
end

---Get the detection radius squared (for distance checks without sqrt).
---@return number
function CTSettings:getDetectionRadiusSq()
    return self.detectionRadius * self.detectionRadius
end
