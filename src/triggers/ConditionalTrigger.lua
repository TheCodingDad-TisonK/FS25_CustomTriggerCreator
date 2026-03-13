-- =========================================================
-- ConditionalTrigger.lua — FS25_CustomTriggerCreator
-- Gates an inner action behind a condition check.
-- Types: TIME_CHECK, MONEY_CHECK, ITEM_CHECK (stub), RANDOM
--
-- Config fields:
--   -- TIME_CHECK
--   timeFrom     number  Hour 0-23 (start of allowed window)
--   timeTo       number  Hour 0-23 (end of allowed window)
--   -- MONEY_CHECK
--   minMoney     number  Player must have at least this much
--   -- ITEM_CHECK (Phase 5 full impl)
--   itemName     string
--   itemQty      number
--   -- RANDOM
--   probability  number  0.0 - 1.0
--   -- Inner action (what fires when condition passes)
--   innerCategory  string
--   innerType      string
--   innerConfig    table
--   -- Feedback messages
--   failMessage  string  Shown when condition is not met
-- =========================================================

ConditionalTrigger = {}
ConditionalTrigger._mt = { __index = ConditionalTrigger }
setmetatable(ConditionalTrigger, { __index = BaseTrigger })

function ConditionalTrigger.new(record)
    local self = BaseTrigger.new(record)
    setmetatable(self, ConditionalTrigger._mt)
    return self
end

function ConditionalTrigger:onActivate()
    local passed, failReason = self:_checkCondition()

    if not passed then
        local msg = self:cfg("failMessage", failReason or "Condition not met.")
        self:_notify(self.name, msg, "WARNING")
        Logger.module("ConditionalTrigger", self.id .. " condition failed: " .. msg)
        return BaseTrigger.RESULT.CONDITION
    end

    -- Condition passed — fire inner action
    return self:_fireInner()
end

-- ---------------------------------------------------------------------------
-- Condition evaluators
-- ---------------------------------------------------------------------------

function ConditionalTrigger:_checkCondition()
    local t = self.type

    if t == "TIME_CHECK" then
        return self:_checkTime()
    elseif t == "MONEY_CHECK" then
        return self:_checkMoney()
    elseif t == "ITEM_CHECK" then
        return self:_checkItem()
    elseif t == "RANDOM" then
        return self:_checkRandom()
    end

    return false, "Unknown condition type: " .. tostring(t)
end

function ConditionalTrigger:_checkTime()
    local env = g_currentMission and g_currentMission.environment
    if not env then return false, "Game time unavailable" end

    -- FS25: currentHour is 0-23
    local hour = env.currentHour or 0
    local from = self:cfg("timeFrom", 0)
    local to   = self:cfg("timeTo",   23)

    local pass
    if from <= to then
        pass = hour >= from and hour <= to
    else
        -- Wraps midnight (e.g. 22:00 – 06:00)
        pass = hour >= from or hour <= to
    end

    if not pass then
        return false, string.format("Only active %02d:00 – %02d:00 (now %02d:00)", from, to, hour)
    end
    return true
end

function ConditionalTrigger:_checkMoney()
    local farmId = g_localPlayer and g_localPlayer.farmId
    local farm   = farmId and g_farmManager and g_farmManager:getFarmById(farmId)
    local balance = farm and farm.money or 0
    local required = self:cfg("minMoney", 0)

    if balance < required then
        return false, string.format("Need $%d (you have $%d)", required, math.floor(balance))
    end
    return true
end

function ConditionalTrigger:_checkItem()
    -- Phase 5: inventory API integration
    Logger.module("ConditionalTrigger", "ITEM_CHECK — Phase 5 impl, passing through")
    return true
end

function ConditionalTrigger:_checkRandom()
    local prob = self:cfg("probability", 0.5)
    prob = math.max(0, math.min(1, prob))
    local roll = math.random()
    if roll > prob then
        return false, string.format("No luck this time (%.0f%% chance)", prob * 100)
    end
    return true
end

-- ---------------------------------------------------------------------------
-- Inner action dispatch
-- ---------------------------------------------------------------------------

function ConditionalTrigger:_fireInner()
    local innerCat    = self:cfg("innerCategory", nil)
    local innerType   = self:cfg("innerType",     nil)
    local innerConfig = self:cfg("innerConfig",   {})

    if not innerCat or not innerType then
        -- No inner action configured — just show a success notification
        self:_notify(self.name, "Condition passed.", "SUCCESS")
        return BaseTrigger.RESULT.OK
    end

    -- Build a synthetic record and execute via TriggerExecutor
    local innerRecord = {
        id       = self.id .. "_inner",
        name     = self.name,
        category = innerCat,
        type     = innerType,
        enabled  = true,
        config   = innerConfig,
    }

    local cls = TriggerExecutor.CLASS_MAP and TriggerExecutor.CLASS_MAP[innerCat]
    if cls then
        local inner = cls.new(innerRecord)
        return inner:activate()
    end

    Logger.warn("ConditionalTrigger: no class for innerCategory " .. tostring(innerCat))
    return BaseTrigger.RESULT.ERROR
end

function ConditionalTrigger:_notify(title, msg, level)
    if g_CTCSystem and g_CTCSystem.notificationHUD then
        g_CTCSystem.notificationHUD:push(title, msg, level)
    end
end
