-- =========================================================
-- CTNotificationHUD.lua — FS25_CustomTriggerCreator
-- Top-right toast notification renderer.
-- Matches style of FS25_WorkplaceTrigger / FS25_NPCFavor.
--
-- Supports up to 5 stacked toasts. Each toast slides in,
-- holds for duration, then fades out.
-- Rendered via Overlay.new() in FSBaseMission.draw.
-- =========================================================

CTNotificationHUD = {}
CTNotificationHUD._mt = { __index = CTNotificationHUD }

-- Layout constants (normalised 0-1 screen coords)
local TOAST_W       = 0.28     -- width
local TOAST_H       = 0.065    -- height per toast
local TOAST_GAP     = 0.008    -- vertical gap between toasts
local TOAST_RIGHT   = 0.995    -- right edge X
local TOAST_TOP     = 0.92     -- top of stack Y (bottom-left origin — high Y = top)
local PADDING_X     = 0.010    -- inner horizontal padding
local PADDING_Y     = 0.012    -- inner vertical padding

local SLIDE_TIME    = 0.25     -- seconds for slide-in
local FADE_TIME     = 0.35     -- seconds for fade-out

local MAX_TOASTS    = 5

-- Level → RGBA background colour
local LEVEL_COLOR = {
    INFO    = { 0.10, 0.14, 0.22, 0.92 },
    SUCCESS = { 0.08, 0.22, 0.10, 0.92 },
    WARNING = { 0.26, 0.20, 0.04, 0.92 },
    ERROR   = { 0.28, 0.06, 0.06, 0.92 },
}
local LEVEL_TEXT_COLOR = {
    INFO    = { 0.70, 0.85, 1.00, 1 },
    SUCCESS = { 0.60, 1.00, 0.65, 1 },
    WARNING = { 1.00, 0.85, 0.30, 1 },
    ERROR   = { 1.00, 0.55, 0.55, 1 },
}
local DEFAULT_COLOR      = LEVEL_COLOR.INFO
local DEFAULT_TEXT_COLOR = LEVEL_TEXT_COLOR.INFO

---Create a new CTNotificationHUD.
---@param settings CTSettings
---@return CTNotificationHUD
function CTNotificationHUD.new(settings)
    local self = setmetatable({}, CTNotificationHUD._mt)
    self.settings  = settings
    self._queue    = {}   -- active toasts (newest first for rendering)
    self._overlay  = nil  -- background Overlay
    self._font     = nil  -- rendered font handle
    return self
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

---Initialise overlays. Call after mission load.
function CTNotificationHUD:initialize()
    -- Create a plain white 1x1 overlay for background rectangles
    self._overlay = Overlay.new(nil, 0, 0, 1, 1)
    if self._overlay then
        self._overlay:setUVs(0, 0, 0, 1, 1, 1, 1, 0)
    end
    Logger.module("CTNotificationHUD", "Initialized")
end

---Push a new toast onto the stack.
---@param title    string
---@param body     string
---@param level    string   "INFO" | "SUCCESS" | "WARNING" | "ERROR"
---@param duration number|nil  seconds (nil = use settings default)
function CTNotificationHUD:push(title, body, level, duration)
    if not self.settings.notificationsEnabled then return end

    level = level or "INFO"
    local dur = duration or self.settings.notificationDuration or 4.0

    -- Evict oldest if at cap
    if #self._queue >= MAX_TOASTS then
        table.remove(self._queue, #self._queue)
    end

    local toast = {
        title     = tostring(title or ""),
        body      = tostring(body  or ""),
        level     = level,
        timeLeft  = dur,
        slideT    = 0,     -- 0..SLIDE_TIME (slide-in progress)
        fadeT     = -1,    -- -1 = not fading yet; 0..FADE_TIME when fading
        alpha     = 0,
    }

    table.insert(self._queue, 1, toast)
    Logger.debug("CTNotificationHUD: pushed [" .. level .. "] " .. title)
end

---Per-frame update. Call from FSBaseMission.update.
---@param dt number  Delta time in milliseconds
function CTNotificationHUD:update(dt)
    if not self.settings.notificationsEnabled then return end

    local dtSec = dt * 0.001
    local i = #self._queue
    while i >= 1 do
        local t = self._queue[i]

        if t.fadeT >= 0 then
            -- Fading out
            t.fadeT = t.fadeT + dtSec
            t.alpha = 1 - (t.fadeT / FADE_TIME)
            if t.fadeT >= FADE_TIME then
                table.remove(self._queue, i)
            end
        else
            -- Slide in
            if t.slideT < SLIDE_TIME then
                t.slideT = math.min(t.slideT + dtSec, SLIDE_TIME)
            end
            t.alpha = t.slideT / SLIDE_TIME

            -- Count down display time
            t.timeLeft = t.timeLeft - dtSec
            if t.timeLeft <= 0 then
                t.fadeT = 0
            end
        end

        i = i - 1
    end
end

---Per-frame draw. Call from FSBaseMission.draw.
function CTNotificationHUD:draw()
    if not self.settings.notificationsEnabled then return end
    if #self._queue == 0 then return end
    if not self._overlay then return end

    for i, toast in ipairs(self._queue) do
        self:_drawToast(toast, i)
    end
end

-- ---------------------------------------------------------------------------
-- Internal rendering
-- ---------------------------------------------------------------------------

function CTNotificationHUD:_drawToast(toast, stackIndex)
    local alpha = math.max(0, math.min(1, toast.alpha))
    if alpha <= 0 then return end

    -- Slide-in offset: starts off right edge, slides to final position
    local slideProgress = math.min(toast.slideT / SLIDE_TIME, 1)
    local slideOffset   = (1 - slideProgress) * TOAST_W

    -- Stack position (bottom-left origin: high Y = higher on screen)
    local slotY = TOAST_TOP - (stackIndex - 1) * (TOAST_H + TOAST_GAP)
    local x     = TOAST_RIGHT - TOAST_W + slideOffset
    local y     = slotY

    local bgColor = LEVEL_COLOR[toast.level] or DEFAULT_COLOR
    local txColor = LEVEL_TEXT_COLOR[toast.level] or DEFAULT_TEXT_COLOR

    -- Background
    self._overlay:setColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] * alpha)
    self._overlay:setPosition(x, y)
    self._overlay:setDimension(TOAST_W, TOAST_H)
    self._overlay:render()

    -- Title text
    local textX = x + PADDING_X
    local textY = y + TOAST_H - PADDING_Y - 0.022
    setTextColor(txColor[1], txColor[2], txColor[3], alpha)
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)
    renderText(textX, textY, 0.018, toast.title)

    -- Body text (smaller)
    if toast.body ~= "" then
        local bodyY = textY - 0.024
        setTextColor(0.85, 0.85, 0.85, alpha * 0.9)
        setTextBold(false)
        renderText(textX, bodyY, 0.014, toast.body)
    end

    -- Reset text state
    setTextColor(1, 1, 1, 1)
    setTextBold(false)
end

---Clean up overlays on mod unload.
function CTNotificationHUD:delete()
    if self._overlay then
        self._overlay:delete()
        self._overlay = nil
    end
    self._queue = {}
    Logger.module("CTNotificationHUD", "Cleaned up")
end
