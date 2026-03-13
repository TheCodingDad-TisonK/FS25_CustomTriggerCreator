-- =========================================================
-- NotificationTrigger.lua — FS25_CustomTriggerCreator
-- Handles: INFO, SUCCESS, WARNING, ERROR
-- Pushes a toast notification to CTNotificationHUD on activation.
--
-- Config fields:
--   title    string  Toast title (defaults to trigger name)
--   body     string  Toast body text
--   duration number  Display duration in seconds (overrides setting default)
-- =========================================================

NotificationTrigger = {}
NotificationTrigger._mt = { __index = NotificationTrigger }
setmetatable(NotificationTrigger, { __index = BaseTrigger })

function NotificationTrigger.new(record)
    local self = BaseTrigger.new(record)
    setmetatable(self, NotificationTrigger._mt)
    return self
end

function NotificationTrigger:onActivate()
    local hud = g_CTCSystem and g_CTCSystem.notificationHUD
    if not hud then
        Logger.warn("NotificationTrigger: notificationHUD not available")
        return BaseTrigger.RESULT.ERROR
    end

    local title    = self:cfg("title",    self.name)
    local body     = self:cfg("body",     "")
    local level    = self.type   -- INFO / SUCCESS / WARNING / ERROR
    local duration = self:cfg("duration", nil)  -- nil = use HUD default

    hud:push(title, body, level, duration)
    Logger.module("NotificationTrigger", self.id .. ": pushed " .. level .. " toast")
    return BaseTrigger.RESULT.OK
end
