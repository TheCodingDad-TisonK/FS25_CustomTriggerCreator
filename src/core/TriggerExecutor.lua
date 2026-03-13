-- =========================================================
-- TriggerExecutor.lua — FS25_CustomTriggerCreator
-- Dispatches trigger activation from registry records.
-- Instantiates the correct class, handles requireConfirm,
-- and manages the active chained trigger lifecycle.
-- =========================================================

TriggerExecutor = {}
TriggerExecutor._mt = { __index = TriggerExecutor }

-- Maps category key → trigger class (set after all classes are loaded)
TriggerExecutor.CLASS_MAP = nil  -- populated in :initialize()

---Create a TriggerExecutor.
---@return TriggerExecutor
function TriggerExecutor.new()
    local self = setmetatable({}, TriggerExecutor._mt)
    self._activeTrigger = nil   -- currently mid-chain trigger, or nil
    return self
end

---Populate CLASS_MAP after all trigger classes are sourced.
function TriggerExecutor:initialize()
    TriggerExecutor.CLASS_MAP = {
        ECONOMY       = EconomyTrigger,
        INTERACTION   = InteractionTrigger,
        NOTIFICATION  = NotificationTrigger,
        CONDITIONAL   = ConditionalTrigger,
        CHAINED       = ChainedTrigger,
        CUSTOM_SCRIPT = nil,   -- Phase 5
    }
    Logger.module("TriggerExecutor", "Initialized")
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---Execute a trigger by its registry record.
---Respects requireConfirm — shows CTConfirmDialog when set.
---@param record table  Trigger record from TriggerRegistry
function TriggerExecutor:execute(record)
    if not record or not record.enabled then return end

    -- Block re-entrancy while a chain is active
    if self._activeTrigger then
        Logger.debug("TriggerExecutor: chain already active, ignoring " .. record.id)
        return
    end

    local cls = TriggerExecutor.CLASS_MAP and TriggerExecutor.CLASS_MAP[record.category]
    if not cls then
        Logger.warn("TriggerExecutor: no class for category " .. tostring(record.category))
        return
    end

    local trigger = cls.new(record)

    if record.config and record.config.requireConfirm then
        -- Show confirmation dialog; activate only on Yes
        DialogLoader.show("CTConfirmDialog", "setup", {
            title   = record.name,
            message = "Activate this trigger?",
            detail  = record.category .. " / " .. record.type,
            onYes   = function()
                self:_fire(trigger, record)
            end,
        })
    else
        self:_fire(trigger, record)
    end
end

---Execute a trigger by ID (looks up registry).
---@param id string
function TriggerExecutor:executeById(id)
    if not g_CTCSystem or not g_CTCSystem.triggerRegistry then return end
    local record = g_CTCSystem.triggerRegistry:getById(id)
    if record then
        self:execute(record)
    else
        Logger.warn("TriggerExecutor: trigger not found: " .. tostring(id))
    end
end

---Per-frame update — ticks active chained trigger.
---@param dt number  Delta time in ms
function TriggerExecutor:update(dt)
    if not self._activeTrigger then return end
    -- Only ChainedTrigger has an update method
    if self._activeTrigger.updateChain then
        self._activeTrigger:updateChain(dt)
    end
    -- Clear when chain is complete (re-check nil: updateChain could invalidate)
    if not self._activeTrigger or self._activeTrigger._activeChain == nil then
        self._activeTrigger = nil
    end
end

-- ---------------------------------------------------------------------------
-- Internal
-- ---------------------------------------------------------------------------

function TriggerExecutor:_fire(trigger, record)
    local result = trigger:activate()
    Logger.module("TriggerExecutor", record.id .. " → " .. tostring(result))

    -- Track chained triggers that run across frames
    if record.category == "CHAINED" and trigger._activeChain then
        self._activeTrigger = trigger
    end
end
