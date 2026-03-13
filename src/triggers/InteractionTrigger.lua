-- =========================================================
-- InteractionTrigger.lua — FS25_CustomTriggerCreator
-- Handles: TALK_NPC, GIVE_ITEM, FIRE_EVENT, ANIMATION
--
-- Config fields:
--   message     string   Dialog text for TALK_NPC
--   eventName   string   Registered event key for FIRE_EVENT
--   animNodeId  number   i3D node ID for ANIMATION
-- =========================================================

InteractionTrigger = {}
InteractionTrigger._mt = { __index = InteractionTrigger }
setmetatable(InteractionTrigger, { __index = BaseTrigger })

function InteractionTrigger.new(record)
    local self = BaseTrigger.new(record)
    setmetatable(self, InteractionTrigger._mt)
    return self
end

function InteractionTrigger:onActivate()
    local t = self.type

    if t == "TALK_NPC" then
        return self:_showMessage()
    elseif t == "GIVE_ITEM" then
        return self:_giveItem()
    elseif t == "FIRE_EVENT" then
        return self:_fireEvent()
    elseif t == "ANIMATION" then
        return self:_playAnimation()
    end

    Logger.warn("InteractionTrigger: unknown type " .. tostring(t))
    return BaseTrigger.RESULT.ERROR
end

function InteractionTrigger:_showMessage()
    local msg = self:cfg("message", self.name)
    self:_notify(msg, "INFO")
    Logger.module("InteractionTrigger", self.id .. ": TALK_NPC — " .. msg)
    return BaseTrigger.RESULT.OK
end

function InteractionTrigger:_giveItem()
    local itemName  = self:cfg("itemName",  "item")
    local itemValue = self:cfg("itemValue", 0)

    -- If an item value is configured, award it as money
    if itemValue > 0 then
        local farmId = g_localPlayer and g_localPlayer.farmId
        if farmId and g_currentMission then
            g_currentMission:addMoney(itemValue, farmId, MoneyType.OTHER, true)
        end
        self:_notify(string.format("Received: %s (+$%d)", itemName, itemValue), "SUCCESS")
    else
        self:_notify("Received: " .. itemName, "SUCCESS")
    end

    Logger.module("InteractionTrigger", string.format("%s: GIVE_ITEM — %s value=%d", self.id, itemName, itemValue))
    return BaseTrigger.RESULT.OK
end

function InteractionTrigger:_fireEvent()
    local evName = self:cfg("eventName", "")
    if evName == "" then
        Logger.warn("InteractionTrigger: FIRE_EVENT — no eventName configured")
        return BaseTrigger.RESULT.ERROR
    end

    -- If another mod registered a callback under this name, call it
    local registry = g_CTCSystem and g_CTCSystem.scriptRegistry
    if registry and registry[evName] then
        local ok, err = pcall(registry[evName])
        if not ok then
            Logger.error("InteractionTrigger: FIRE_EVENT callback error: " .. tostring(err))
            return BaseTrigger.RESULT.ERROR
        end
    else
        Logger.module("InteractionTrigger", "FIRE_EVENT '" .. evName .. "' — no callback registered (yet)")
    end

    self:_notify("Event fired: " .. evName, "INFO")
    return BaseTrigger.RESULT.OK
end

function InteractionTrigger:_playAnimation()
    local animKey = self:cfg("animName", self:cfg("message", ""))

    -- 1. Check scriptRegistry for a mod-registered animation callback ("anim_<key>")
    local registry = g_CTCSystem and g_CTCSystem.scriptRegistry
    local cbKey    = "anim_" .. tostring(animKey)
    if animKey ~= "" and registry and registry[cbKey] then
        local ok, err = pcall(registry[cbKey])
        if ok then
            self:_notify("Animation played: " .. animKey, "INFO")
            Logger.module("InteractionTrigger", self.id .. ": ANIMATION callback '" .. cbKey .. "' OK")
            return BaseTrigger.RESULT.OK
        else
            Logger.error("InteractionTrigger: ANIMATION callback error: " .. tostring(err))
        end
    end

    -- 2. Try direct node animation if animNodeId is configured in config
    local nodeId = self:cfg("animNodeId", nil)
    if nodeId and nodeId ~= 0 then
        local animated = false
        local ok = pcall(function()
            local charsetId = getAnimCharacterSet(nodeId)
            if charsetId and charsetId ~= 0 then
                local speed = self:cfg("animSpeed", 1.0)
                enableAnimTrack(charsetId, 0)
                setAnimTrackSpeedScale(charsetId, 0, speed)
                setAnimTrackTime(charsetId, 0, 0, true)
                animated = true
            end
        end)
        if ok and animated then
            self:_notify("Animation played.", "INFO")
            Logger.module("InteractionTrigger", self.id .. ": ANIMATION node=" .. nodeId .. " OK")
            return BaseTrigger.RESULT.OK
        end
    end

    -- 3. Fallback: notify only (no node or callback registered yet)
    local label = animKey ~= "" and animKey or "trigger"
    self:_notify("Animation: " .. label, "INFO")
    Logger.module("InteractionTrigger", self.id .. ": ANIMATION — key=" .. tostring(animKey) .. " (no node/callback)")
    return BaseTrigger.RESULT.OK
end

function InteractionTrigger:_notify(msg, level)
    if g_CTCSystem and g_CTCSystem.notificationHUD then
        g_CTCSystem.notificationHUD:push(self.name, msg, level)
    end
end
