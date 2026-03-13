-- =========================================================
-- ChainedTrigger.lua — FS25_CustomTriggerCreator
-- Multi-step activation flow.
-- Types: TWO_STEP, THREE_STEP, BRANCHING, TIMED
--
-- Chain execution is asynchronous (spans multiple frames).
-- TriggerExecutor holds a reference and calls updateChain(dt).
--
-- Config fields:
--   stepMessage    string   Step 1 notification body
--   confirmMessage string   Text shown in the confirm dialog
--   step2Message   string   Step 2 notification body
--   step2Amount    number   Optional economy reward at step 2
--   step3Message   string   THREE_STEP only
--   -- BRANCHING
--   branchPrompt   string   Yes/No question
--   yesMessage     string
--   yesAmount      number
--   noMessage      string
--   noAmount       number
--   -- TIMED
--   timerSec       number   Countdown seconds between steps
-- =========================================================

ChainedTrigger = {}
ChainedTrigger._mt = { __index = ChainedTrigger }
setmetatable(ChainedTrigger, { __index = BaseTrigger })

function ChainedTrigger.new(record)
    local self = BaseTrigger.new(record)
    setmetatable(self, ChainedTrigger._mt)
    self._activeChain = nil
    return self
end

-- ---------------------------------------------------------------------------
-- Activation entry point
-- ---------------------------------------------------------------------------

function ChainedTrigger:onActivate()
    local t = self.type

    if t == "TWO_STEP"   then self:_startTwoStep()
    elseif t == "THREE_STEP" then self:_startThreeStep()
    elseif t == "BRANCHING"  then self:_startBranching()
    elseif t == "TIMED"      then self:_startTimed()
    else
        Logger.warn("ChainedTrigger: unknown type " .. tostring(t))
        return BaseTrigger.RESULT.ERROR
    end

    return BaseTrigger.RESULT.OK
end

-- ---------------------------------------------------------------------------
-- Per-frame update (called by TriggerExecutor)
-- ---------------------------------------------------------------------------

function ChainedTrigger:updateChain(dt)
    if not self._activeChain then return end
    local chain = self._activeChain

    -- Only tick during TIMED countdown
    if chain.timerRemaining and chain.timerRemaining > 0 then
        chain.timerRemaining = chain.timerRemaining - dt * 0.001

        -- Update countdown display each whole second
        local secsLeft = math.ceil(chain.timerRemaining)
        if secsLeft ~= chain._lastSecsDisplayed then
            chain._lastSecsDisplayed = secsLeft
            self:_pushCountdown(secsLeft, chain.countdownLabel or "Processing...")
        end

        if chain.timerRemaining <= 0 then
            chain.timerRemaining = 0
            self:_onTimerExpired()
        end
    end
end

-- ---------------------------------------------------------------------------
-- TWO_STEP
-- ---------------------------------------------------------------------------

function ChainedTrigger:_startTwoStep()
    local msg1 = self:cfg("stepMessage",    "Starting...")
    local msg2 = self:cfg("confirmMessage", "Continue?")
    local msg3 = self:cfg("step2Message",   "Done!")
    local amt  = self:cfg("step2Amount",    0)

    -- Step 1: notify
    self:_notify(self.name, msg1, "INFO")

    -- Step 2: confirm then reward
    self._activeChain = { type = "TWO_STEP" }

    DialogLoader.show("CTConfirmDialog", "setup", {
        title   = self.name,
        message = msg2,
        onYes   = function()
            self:_notify(self.name, msg3, "SUCCESS")
            if amt ~= 0 then self:_applyMoney(amt) end
            self._activeChain = nil
        end,
        onNo = function()
            self:_notify(self.name, "Cancelled.", "INFO")
            self._activeChain = nil
        end,
    })
end

-- ---------------------------------------------------------------------------
-- THREE_STEP
-- ---------------------------------------------------------------------------

function ChainedTrigger:_startThreeStep()
    local msg1   = self:cfg("stepMessage",    "Step 1 starting...")
    local conf1  = self:cfg("confirmMessage", "Proceed to step 2?")
    local msg2   = self:cfg("step2Message",   "Step 2 in progress...")
    local conf2  = self:cfg("step3Confirm",   "Proceed to final step?")
    local msg3   = self:cfg("step3Message",   "Complete!")
    local amt    = self:cfg("step2Amount",    0)

    self:_notify(self.name, msg1, "INFO")
    self._activeChain = { type = "THREE_STEP" }

    DialogLoader.show("CTConfirmDialog", "setup", {
        title   = self.name,
        message = conf1,
        onYes   = function()
            self:_notify(self.name, msg2, "INFO")
            DialogLoader.show("CTConfirmDialog", "setup", {
                title   = self.name,
                message = conf2,
                onYes   = function()
                    self:_notify(self.name, msg3, "SUCCESS")
                    if amt ~= 0 then self:_applyMoney(amt) end
                    self._activeChain = nil
                end,
                onNo = function()
                    self:_notify(self.name, "Cancelled at step 3.", "INFO")
                    self._activeChain = nil
                end,
            })
        end,
        onNo = function()
            self:_notify(self.name, "Cancelled at step 2.", "INFO")
            self._activeChain = nil
        end,
    })
end

-- ---------------------------------------------------------------------------
-- BRANCHING
-- ---------------------------------------------------------------------------

function ChainedTrigger:_startBranching()
    local prompt   = self:cfg("branchPrompt", "Choose a path?")
    local yesMsg   = self:cfg("yesMessage",   "You chose yes.")
    local yesAmt   = self:cfg("yesAmount",    0)
    local noMsg    = self:cfg("noMessage",    "You chose no.")
    local noAmt    = self:cfg("noAmount",     0)

    self._activeChain = { type = "BRANCHING" }

    DialogLoader.show("CTConfirmDialog", "setup", {
        title    = self.name,
        message  = prompt,
        yesLabel = "Yes",
        noLabel  = "No",
        onYes = function()
            self:_notify(self.name, yesMsg, "SUCCESS")
            if yesAmt ~= 0 then self:_applyMoney(yesAmt) end
            self._activeChain = nil
        end,
        onNo = function()
            self:_notify(self.name, noMsg, "INFO")
            if noAmt ~= 0 then self:_applyMoney(noAmt) end
            self._activeChain = nil
        end,
    })
end

-- ---------------------------------------------------------------------------
-- TIMED
-- ---------------------------------------------------------------------------

function ChainedTrigger:_startTimed()
    local timerSec = self:cfg("timerSec",      10)
    local msg1     = self:cfg("stepMessage",   "Processing...")
    local msg2     = self:cfg("step2Message",  "Complete!")
    local amt      = self:cfg("step2Amount",   0)

    self:_notify(self.name, msg1, "INFO")

    self._activeChain = {
        type              = "TIMED",
        timerRemaining    = timerSec,
        countdownLabel    = self.name,
        _lastSecsDisplayed = timerSec + 1,  -- force first display
        _finalMessage     = msg2,
        _finalAmount      = amt,
    }
end

function ChainedTrigger:_onTimerExpired()
    if not self._activeChain then return end
    local chain = self._activeChain
    self:_notify(self.name, chain._finalMessage or "Done!", "SUCCESS")
    if chain._finalAmount and chain._finalAmount ~= 0 then
        self:_applyMoney(chain._finalAmount)
    end
    self._activeChain = nil
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

function ChainedTrigger:_notify(title, msg, level)
    if g_CTCSystem and g_CTCSystem.notificationHUD then
        g_CTCSystem.notificationHUD:push(title, msg, level)
    end
end

function ChainedTrigger:_pushCountdown(secsLeft, label)
    if g_CTCSystem and g_CTCSystem.notificationHUD then
        g_CTCSystem.notificationHUD:setCountdown(label, secsLeft)
    end
end

function ChainedTrigger:_applyMoney(delta)
    local farmId = g_localPlayer and g_localPlayer.farmId
    if not farmId then
        if g_farmManager then
            local farms = g_farmManager:getFarms()
            if farms and farms[1] then farmId = farms[1].farmId end
        end
    end
    if not farmId then return end
    g_currentMission:addMoney(delta, farmId, MoneyType.OTHER, true)
end
