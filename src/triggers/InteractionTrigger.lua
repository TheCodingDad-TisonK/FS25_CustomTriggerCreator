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
    -- Phase 3: notification only. Item delivery via inventory API in Phase 4.
    local itemName = self:cfg("itemName", "item")
    self:_notify("Received: " .. itemName, "SUCCESS")
    Logger.module("InteractionTrigger", self.id .. ": GIVE_ITEM — " .. itemName)
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
    -- Phase 3: placeholder — i3D animation in Phase 4
    Logger.module("InteractionTrigger", self.id .. ": ANIMATION — Phase 4 impl")
    self:_notify("Animation triggered.", "INFO")
    return BaseTrigger.RESULT.OK
end

function InteractionTrigger:_notify(msg, level)
    if g_CTCSystem and g_CTCSystem.notificationHUD then
        g_CTCSystem.notificationHUD:push(self.name, msg, level)
    end
end
