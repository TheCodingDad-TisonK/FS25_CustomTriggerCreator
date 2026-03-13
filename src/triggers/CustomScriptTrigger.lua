-- =========================================================
-- CustomScriptTrigger.lua — FS25_CustomTriggerCreator
-- Handles: CALLBACK, EVENT_HOOK, SCHEDULED, CONDITIONAL_CB
--
-- Config fields:
--   CALLBACK:
--     callbackKey  string  Key in g_CTCSystem.scriptRegistry
--   EVENT_HOOK:
--     eventKey     string  MessageType name to subscribe to (e.g. "CURRENT_MISSION_START")
--     callbackKey  string  Callback in scriptRegistry fired on event
--   SCHEDULED:
--     callbackKey  string  Callback in scriptRegistry to fire
--     delaySec     number  Seconds to wait before firing
--   CONDITIONAL_CB:
--     conditionKey string  Condition fn in scriptRegistry (must return bool)
--     callbackKey  string  Action fn in scriptRegistry fired when condition passes
-- =========================================================

CustomScriptTrigger = {}
CustomScriptTrigger._mt = { __index = CustomScriptTrigger }
setmetatable(CustomScriptTrigger, { __index = BaseTrigger })

function CustomScriptTrigger.new(record)
    local self = BaseTrigger.new(record)
    setmetatable(self, CustomScriptTrigger._mt)
    self._activeSchedule = nil  -- { elapsed, delaySec, callbackKey } while pending
    return self
end

function CustomScriptTrigger:onActivate()
    local t = self.type
    if t == "CALLBACK" then
        return self:_fireCallback()
    elseif t == "EVENT_HOOK" then
        return self:_hookEvent()
    elseif t == "SCHEDULED" then
        return self:_startSchedule()
    elseif t == "CONDITIONAL_CB" then
        return self:_conditionalCallback()
    end
    Logger.warn("CustomScriptTrigger: unknown type " .. tostring(t))
    return BaseTrigger.RESULT.ERROR
end

-- ---------------------------------------------------------------------------
-- Type implementations
-- ---------------------------------------------------------------------------

function CustomScriptTrigger:_fireCallback()
    local key = self:cfg("callbackKey", "")
    if key == "" then
        Logger.warn("CustomScriptTrigger: CALLBACK — no callbackKey configured")
        self:_notify("No callback key configured.", "WARNING")
        return BaseTrigger.RESULT.ERROR
    end

    local registry = g_CTCSystem and g_CTCSystem.scriptRegistry
    if registry and registry[key] then
        local ok, err = pcall(registry[key])
        if not ok then
            Logger.error("CustomScriptTrigger: CALLBACK '" .. key .. "' error: " .. tostring(err))
            self:_notify("Callback error: " .. key, "ERROR")
            return BaseTrigger.RESULT.ERROR
        end
        Logger.module("CustomScriptTrigger", self.id .. ": CALLBACK '" .. key .. "' OK")
    else
        -- Not registered yet — this is intentional for mod inter-op
        Logger.module("CustomScriptTrigger", "CALLBACK '" .. key .. "' — not in scriptRegistry (yet)")
    end

    self:_notify("Script: " .. key, "INFO")
    return BaseTrigger.RESULT.OK
end

function CustomScriptTrigger:_hookEvent()
    local eventKey    = self:cfg("eventKey",    "")
    local callbackKey = self:cfg("callbackKey", "")

    if eventKey == "" then
        self:_notify("No event key configured.", "WARNING")
        return BaseTrigger.RESULT.ERROR
    end

    -- Resolve MessageType enum
    local msgType = MessageType and MessageType[eventKey]
    if not msgType then
        Logger.warn("CustomScriptTrigger: EVENT_HOOK — unknown MessageType: " .. eventKey)
        self:_notify("Unknown event: " .. eventKey, "WARNING")
        return BaseTrigger.RESULT.ERROR
    end

    local registry = g_CTCSystem and g_CTCSystem.scriptRegistry
    local cbKey    = callbackKey  -- captured for closure

    g_messageCenter:subscribeOneshot(msgType, function(...)
        if cbKey ~= "" and registry and registry[cbKey] then
            pcall(registry[cbKey], ...)
        end
        self:_notify("Event received: " .. eventKey, "INFO")
        Logger.module("CustomScriptTrigger", self.id .. ": EVENT_HOOK fired — " .. eventKey)
    end, self)

    self:_notify("Listening: " .. eventKey, "INFO")
    Logger.module("CustomScriptTrigger", self.id .. ": EVENT_HOOK subscribed to " .. eventKey)
    return BaseTrigger.RESULT.OK
end

function CustomScriptTrigger:_startSchedule()
    local callbackKey = self:cfg("callbackKey", "")
    local delaySec    = self:cfg("delaySec",    5)

    if callbackKey == "" then
        self:_notify("No callback key configured.", "WARNING")
        return BaseTrigger.RESULT.ERROR
    end

    self._activeSchedule = {
        elapsed     = 0,
        delaySec    = delaySec,
        callbackKey = callbackKey,
    }

    self:_notify(string.format("Scheduled in %ds: %s", delaySec, callbackKey), "INFO")
    Logger.module("CustomScriptTrigger", self.id .. ": SCHEDULED '" .. callbackKey .. "' in " .. delaySec .. "s")
    return BaseTrigger.RESULT.OK
end

---Called by TriggerExecutor every frame while a schedule is pending.
---@param dt number  Delta time in ms (FS25 convention)
function CustomScriptTrigger:updateScheduled(dt)
    if not self._activeSchedule then return end

    self._activeSchedule.elapsed = self._activeSchedule.elapsed + dt * 0.001  -- ms → s

    if self._activeSchedule.elapsed >= self._activeSchedule.delaySec then
        local key = self._activeSchedule.callbackKey
        self._activeSchedule = nil  -- clear before callback (allows re-activation)

        local registry = g_CTCSystem and g_CTCSystem.scriptRegistry
        if registry and registry[key] then
            local ok, err = pcall(registry[key])
            if not ok then
                Logger.error("CustomScriptTrigger: SCHEDULED '" .. key .. "' error: " .. tostring(err))
            end
        end

        self:_notify("Fired: " .. key, "SUCCESS")
        Logger.module("CustomScriptTrigger", self.id .. ": SCHEDULED fired '" .. key .. "'")
    end
end

function CustomScriptTrigger:_conditionalCallback()
    local condKey     = self:cfg("conditionKey",  "")
    local callbackKey = self:cfg("callbackKey",   "")

    local registry = g_CTCSystem and g_CTCSystem.scriptRegistry

    -- Evaluate condition function if registered
    if condKey ~= "" then
        if not registry or not registry[condKey] then
            Logger.module("CustomScriptTrigger", "CONDITIONAL_CB condition '" .. condKey .. "' not registered — passing")
        else
            local ok, result = pcall(registry[condKey])
            if not ok or not result then
                self:_notify("Condition not met.", "WARNING")
                Logger.module("CustomScriptTrigger", self.id .. ": CONDITIONAL_CB condition '" .. condKey .. "' failed")
                return BaseTrigger.RESULT.CONDITION
            end
        end
    end

    -- Fire action callback
    if callbackKey ~= "" and registry and registry[callbackKey] then
        local ok, err = pcall(registry[callbackKey])
        if not ok then
            Logger.error("CustomScriptTrigger: CONDITIONAL_CB action '" .. callbackKey .. "' error: " .. tostring(err))
            return BaseTrigger.RESULT.ERROR
        end
    end

    self:_notify("Script executed.", "SUCCESS")
    return BaseTrigger.RESULT.OK
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

function CustomScriptTrigger:_notify(msg, level)
    if g_CTCSystem and g_CTCSystem.notificationHUD then
        g_CTCSystem.notificationHUD:push(self.name, msg, level)
    end
end
