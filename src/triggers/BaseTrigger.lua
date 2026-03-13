-- =========================================================
-- BaseTrigger.lua — FS25_CustomTriggerCreator
-- Base class all trigger types extend.
-- Handles: cooldown, repeat limit, enabled state, activation
-- =========================================================

BaseTrigger = {}
BaseTrigger._mt = { __index = BaseTrigger }

-- Activation result codes
BaseTrigger.RESULT = {
    OK          = "OK",
    COOLDOWN    = "COOLDOWN",
    DISABLED    = "DISABLED",
    CONDITION   = "CONDITION",   -- condition not met (Phase 4)
    LIMIT       = "LIMIT",       -- repeat limit reached
    ERROR       = "ERROR",
}

---Create a BaseTrigger from a registry trigger record.
---@param record table  Trigger record from TriggerRegistry
---@return BaseTrigger
function BaseTrigger.new(record)
    local self = setmetatable({}, BaseTrigger._mt)
    self.id          = record.id
    self.name        = record.name
    self.category    = record.category
    self.type        = record.type
    self.enabled     = record.enabled
    self.config      = record.config or {}

    -- Runtime state (not persisted — resets on load)
    self._lastActivation = 0    -- g_currentMission.time of last fire
    self._activationCount = 0   -- total activations this session

    return self
end

-- ---------------------------------------------------------------------------
-- Core activation flow
-- ---------------------------------------------------------------------------

---Attempt to activate this trigger. Returns a result code.
---@return string  BaseTrigger.RESULT value
function BaseTrigger:activate()
    if not self.enabled then
        return BaseTrigger.RESULT.DISABLED
    end

    local now = g_currentMission and g_currentMission.time or 0

    -- Cooldown check (cooldown stored in ms in config)
    local cooldownMs = (self.config.cooldownSec or 0) * 1000
    if cooldownMs > 0 and (now - self._lastActivation) < cooldownMs then
        Logger.debug("BaseTrigger [" .. self.id .. "] on cooldown")
        return BaseTrigger.RESULT.COOLDOWN
    end

    -- Repeat limit
    local limit = self.config.repeatLimit or 0   -- 0 = unlimited
    if limit > 0 and self._activationCount >= limit then
        Logger.debug("BaseTrigger [" .. self.id .. "] repeat limit reached")
        return BaseTrigger.RESULT.LIMIT
    end

    -- Run type-specific action
    local result = self:onActivate()
    if result == BaseTrigger.RESULT.OK then
        self._lastActivation  = now
        self._activationCount = self._activationCount + 1
    end

    return result
end

---Override in subclasses to perform the actual trigger action.
---@return string  BaseTrigger.RESULT value
function BaseTrigger:onActivate()
    Logger.warn("BaseTrigger:onActivate() called on base — override in subclass")
    return BaseTrigger.RESULT.OK
end

-- ---------------------------------------------------------------------------
-- Config helpers
-- ---------------------------------------------------------------------------

---Get a config value with a default fallback.
---@param key     string
---@param default any
---@return any
function BaseTrigger:cfg(key, default)
    local v = self.config[key]
    if v == nil then return default end
    return v
end

---Sync enabled state from the registry record.
---@param enabled boolean
function BaseTrigger:setEnabled(enabled)
    self.enabled = enabled
end

---Reset runtime state (called on savegame load).
function BaseTrigger:resetRuntime()
    self._lastActivation  = 0
    self._activationCount = 0
end

---Describe this trigger for log/debug output.
---@return string
function BaseTrigger:describe()
    return string.format("[%s] %s (%s / %s) enabled=%s",
        self.id, self.name, self.category, self.type, tostring(self.enabled))
end
