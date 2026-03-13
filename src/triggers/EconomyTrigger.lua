-- =========================================================
-- EconomyTrigger.lua — FS25_CustomTriggerCreator
-- Handles: BUY_SELL, PAY_FEE, EARN, BARTER
--
-- Config fields (set via wizard steps 3-5):
--   amount      number   Money amount (positive = player receives)
--   fillType    string   Fill type name for BUY_SELL / BARTER
--   quantity    number   Units to exchange
--   confirmMsg  string   Shown in CTConfirmDialog before execution
-- =========================================================

EconomyTrigger = {}
EconomyTrigger._mt = { __index = EconomyTrigger }
setmetatable(EconomyTrigger, { __index = BaseTrigger })

---Create an EconomyTrigger from a registry record.
---@param record table
---@return EconomyTrigger
function EconomyTrigger.new(record)
    local self = BaseTrigger.new(record)
    setmetatable(self, EconomyTrigger._mt)
    return self
end

function EconomyTrigger:onActivate()
    local t = self.type

    if t == "PAY_FEE" then
        return self:_applyMoney(-math.abs(self:cfg("amount", 100)))
    elseif t == "EARN" then
        return self:_applyMoney(math.abs(self:cfg("amount", 100)))
    elseif t == "BUY_SELL" then
        return self:_buySell()
    elseif t == "BARTER" then
        return self:_barter()
    end

    Logger.warn("EconomyTrigger: unknown type " .. tostring(t))
    return BaseTrigger.RESULT.ERROR
end

-- ---------------------------------------------------------------------------
-- Type implementations
-- ---------------------------------------------------------------------------

function EconomyTrigger:_applyMoney(delta)
    local farmId = self:_getPlayerFarmId()
    if not farmId then return BaseTrigger.RESULT.ERROR end

    -- Check balance for fees
    if delta < 0 then
        local farm = g_farmManager and g_farmManager:getFarmById(farmId)
        local balance = farm and farm.money or 0
        if balance < math.abs(delta) then
            self:_notify("Not enough money.", "WARNING")
            return BaseTrigger.RESULT.CONDITION
        end
    end

    g_currentMission:addMoney(delta, farmId, MoneyType.OTHER, true)

    local label = delta >= 0 and ("+" .. delta .. "$") or (delta .. "$")
    self:_notify(label, delta >= 0 and "SUCCESS" or "INFO")
    Logger.module("EconomyTrigger", self.id .. ": applied " .. delta)
    return BaseTrigger.RESULT.OK
end

function EconomyTrigger:_buySell()
    local amount = self:cfg("amount", 0)
    local qty    = self:cfg("quantity", 1)
    local fill   = self:cfg("fillType", "goods")
    Logger.module("EconomyTrigger", string.format("BUY_SELL: %s x%d @ %d$", fill, qty, amount))
    local delta = self:cfg("playerReceivesMoney", true) and amount or -amount
    return self:_applyMoney(delta * qty)
end

function EconomyTrigger:_barter()
    local amount = self:cfg("amount", 0)
    Logger.module("EconomyTrigger", "BARTER — Phase 4 full impl")
    return self:_applyMoney(amount)
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

function EconomyTrigger:_getPlayerFarmId()
    if g_localPlayer and g_localPlayer.farmId then
        return g_localPlayer.farmId
    end
    -- Fallback: first farm the local player belongs to
    if g_farmManager then
        local farms = g_farmManager:getFarms()
        if farms and farms[1] then return farms[1].farmId end
    end
    Logger.warn("EconomyTrigger: cannot resolve player farmId")
    return nil
end

function EconomyTrigger:_notify(msg, level)
    if g_CTCSystem and g_CTCSystem.notificationHUD then
        g_CTCSystem.notificationHUD:push(self.name, msg, level)
    end
end
