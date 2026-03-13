-- =========================================================
-- CTTriggerActivatable.lua — FS25_CustomTriggerCreator
-- Implements the FS25 Activatable interface for CTC trigger
-- zones. Registered with ActivatableObjectsSystem when the
-- player enters a trigger's interaction radius; pressing E
-- calls run() which executes the trigger.
-- =========================================================

CTTriggerActivatable = {}
CTTriggerActivatable._mt = { __index = CTTriggerActivatable }

---Create a CTTriggerActivatable from a trigger registry record.
---@param record table  Trigger record from TriggerRegistry
---@return CTTriggerActivatable
function CTTriggerActivatable.new(record)
    local self = setmetatable({}, CTTriggerActivatable._mt)
    self.record       = record
    self.activateText = "Activate: " .. (record.name or "Trigger")
    return self
end

-- ---------------------------------------------------------------------------
-- Activatable interface (required by FS25 ActivatableObjectsSystem)
-- ---------------------------------------------------------------------------

---Whether the trigger can be activated right now.
---Called every frame; controls "Press E" prompt visibility.
---@return boolean
function CTTriggerActivatable:getIsActivatable()
    if not self.record or not self.record.enabled then return false end
    -- Don't allow activation while any GUI is open
    if g_gui and g_gui.currentGui ~= nil then return false end
    -- Require a running career mission
    if not g_currentMission or not g_currentMission.isMissionStarted then return false end
    -- Block while another trigger is mid-execution (prevents log spam + double-fire)
    if g_CTCSystem and g_CTCSystem.triggerExecutor and g_CTCSystem.triggerExecutor._activeTrigger then
        return false
    end
    return true
end

---Distance from this trigger's world position to a given point.
---Used by the system to sort and prioritise nearby activatables.
---@param x number
---@param y number
---@param z number
---@return number
function CTTriggerActivatable:getDistance(x, y, z)
    local cfg = self.record and self.record.config
    if not cfg or not cfg.worldX or not cfg.worldZ then return math.huge end
    local dx = x - cfg.worldX
    local dy = y - (cfg.worldY or 0)
    local dz = z - cfg.worldZ
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

---Called when the player presses E while this activatable is active.
function CTTriggerActivatable:run()
    if not g_CTCSystem or not g_CTCSystem.triggerExecutor then return end
    g_CTCSystem.triggerExecutor:executeById(self.record.id)
end
