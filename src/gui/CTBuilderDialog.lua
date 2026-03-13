-- =========================================================
-- CTBuilderDialog.lua — FS25_CustomTriggerCreator
-- Wizard steps 2–8.
--   Step 2: Select trigger type within the chosen category
--   Step 3: Configure type-specific settings
--   Step 4: Set conditions (Conditional-specific controls)
--   Step 5: Actions (stub — Phase 4)
--   Step 6: Advanced options (cooldown, repeat limit, confirmation)
--   Step 7: Name the trigger
--   Step 8: Review & confirm
-- =========================================================

CTBuilderDialog = {}
local CTBuilderDialog_mt = Class(CTBuilderDialog, MessageDialog)

-- Types per category (key, title, description)
CTBuilderDialog.TYPES = {
    ECONOMY = {
        { key = "BUY_SELL",  title = "Buy / Sell",     desc = "Exchange goods at a price" },
        { key = "PAY_FEE",   title = "Pay Fee",         desc = "Charge a flat fee on entry" },
        { key = "EARN",      title = "Earn Reward",     desc = "Pay the player a sum" },
        { key = "BARTER",    title = "Barter",          desc = "Trade items for items" },
    },
    INTERACTION = {
        { key = "TALK_NPC",   title = "Talk to NPC",    desc = "Display a dialog message" },
        { key = "GIVE_ITEM",  title = "Receive Item",   desc = "Hand an item to the player" },
        { key = "FIRE_EVENT", title = "Fire Event",     desc = "Trigger a registered event" },
        { key = "ANIMATION",  title = "Play Animation", desc = "Play a world animation" },
    },
    CONDITIONAL = {
        { key = "TIME_CHECK",   title = "Time Check",    desc = "Gate on game time of day" },
        { key = "MONEY_CHECK",  title = "Money Check",   desc = "Gate on player balance" },
        { key = "ITEM_CHECK",   title = "Item Check",    desc = "Gate on inventory content" },
        { key = "RANDOM",       title = "Random Chance", desc = "Probability-based gate" },
    },
    CHAINED = {
        { key = "TWO_STEP",   title = "2-Step",          desc = "Action → confirm → reward" },
        { key = "THREE_STEP", title = "3-Step",          desc = "Triple confirmation flow" },
        { key = "BRANCHING",  title = "Branching",       desc = "Yes / No split path" },
        { key = "TIMED",      title = "Timed Steps",     desc = "Countdown between steps" },
    },
    NOTIFICATION = {
        { key = "INFO",    title = "Info Alert",    desc = "Blue informational toast" },
        { key = "SUCCESS", title = "Success Alert", desc = "Green success toast" },
        { key = "WARNING", title = "Warning Alert", desc = "Yellow warning toast" },
        { key = "ERROR",   title = "Error Alert",   desc = "Red error toast" },
    },
    CUSTOM_SCRIPT = {
        { key = "CALLBACK",      title = "Lua Callback",        desc = "Call a registered Lua fn" },
        { key = "EVENT_HOOK",    title = "Event Hook",          desc = "Subscribe to a game event" },
        { key = "SCHEDULED",     title = "Scheduled Call",      desc = "Run on a time interval" },
        { key = "CONDITIONAL_CB",title = "Conditional Callback",desc = "Callback with gate logic" },
    },
}

-- Step labels shown in the wizard header.
-- Step 5 (Actions) is skipped in navigation; labels reflect visible steps only.
CTBuilderDialog.STEP_LABELS = {
    [2] = "Step 2 of 7 — Choose Type",
    [3] = "Step 3 of 7 — Configure",
    [4] = "Step 4 of 7 — Conditions",
    [6] = "Step 5 of 7 — Advanced Options",
    [7] = "Step 6 of 7 — Name Your Trigger",
    [8] = "Step 7 of 7 — Review & Confirm",
}

-- =========================================================
function CTBuilderDialog.new(target, custom_mt)
    local self = MessageDialog.new(target, custom_mt or CTBuilderDialog_mt)
    self:_resetState()
    return self
end

function CTBuilderDialog:_resetState()
    self._category    = nil
    self._step        = 2
    self._selectedKey = nil
    self._triggerName = ""
    self._types       = {}
    self._config = {
        -- Step 3 (type-specific — set via _buildConfigForType)
        amount        = 100,
        message       = "",
        itemName      = "",
        eventName     = "",
        body          = "",
        -- Step 4 (conditions)
        conditionType = "NONE",
        timeFrom      = 6,
        timeTo        = 20,
        minMoney      = 500,
        probability   = 0.5,
        -- Step 5 (actions — Phase 4 stub)
        actionType    = "NONE",
        -- Step 6 (advanced)
        cooldownSec   = 0,
        repeatLimit   = 0,
        requireConfirm = false,
        -- World position (captured at confirm time)
        worldX        = nil,
        worldY        = nil,
        worldZ        = nil,
    }
end

function CTBuilderDialog:onCreate()
    local ok, err = pcall(function() CTBuilderDialog:superClass().onCreate(self) end)
    if not ok then Logger.error("CTBuilderDialog:onCreate(): " .. tostring(err)) end
end

function CTBuilderDialog:onDialogOpen()
    local ok, err = pcall(function() CTBuilderDialog:superClass().onOpen(self) end)
    if not ok then Logger.error("CTBuilderDialog:onDialogOpen(): " .. tostring(err)) end
end

function CTBuilderDialog:onDialogClose()
    local ok, err = pcall(function() CTBuilderDialog:superClass().onClose(self) end)
    if not ok then Logger.debug("CTBuilderDialog:onDialogClose(): " .. tostring(err)) end
end

-- ---------------------------------------------------------------------------
-- Entry point
-- ---------------------------------------------------------------------------

function CTBuilderDialog:startWizard(categoryKey)
    self:_resetState()
    self._category = categoryKey or "ECONOMY"
    self._types    = CTBuilderDialog.TYPES[self._category] or {}
    local count = g_CTCSystem and g_CTCSystem.triggerRegistry and
                  g_CTCSystem.triggerRegistry:count() or 0
    self._triggerName = "Trigger " .. (count + 1)
    self._step = 2
    self:_render()
end

-- ---------------------------------------------------------------------------
-- Rendering dispatcher
-- ---------------------------------------------------------------------------

function CTBuilderDialog:_render()
    -- Title
    if self.bdTitleText then
        self.bdTitleText:setText("New " .. (self._category or "") .. " Trigger")
    end
    if self.bdStepText then
        self.bdStepText:setText(CTBuilderDialog.STEP_LABELS[self._step] or "")
    end

    -- Show/hide panels
    local panels = {
        bdStep2Panel = (self._step == 2),
        bdStep3Panel = (self._step == 3),
        bdStep4Panel = (self._step == 4),
        bdStep5Panel = (self._step == 5),
        bdStep6Panel = (self._step == 6),
        bdStep7Panel = (self._step == 7),
        bdStep8Panel = (self._step == 8),
    }
    for id, vis in pairs(panels) do
        local el = self[id]
        if el then el:setVisible(vis) end
    end

    -- Back button: hidden on step 2
    if self.bdBackBtn then self.bdBackBtn:setVisible(self._step > 2) end

    -- Next button: hidden on step 2 (advance via type buttons), visible step 3+
    if self.bdNextBtn then
        self.bdNextBtn:setVisible(self._step >= 3 and self._step < 8)
    end

    -- Confirm button only on step 8
    if self.bdConfirmBtn then self.bdConfirmBtn:setVisible(self._step == 8) end

    -- Render step content
    if     self._step == 2 then self:_renderStep2()
    elseif self._step == 3 then self:_renderStep3()
    elseif self._step == 4 then self:_renderStep4()
    elseif self._step == 5 then self:_renderStep5()
    elseif self._step == 6 then self:_renderStep6()
    elseif self._step == 7 then self:_renderStep7()
    elseif self._step == 8 then self:_renderStep8()
    end
end

-- ---------------------------------------------------------------------------
-- Step renderers
-- ---------------------------------------------------------------------------

function CTBuilderDialog:_renderStep2()
    local types = self._types
    local slots = { "bdType1", "bdType2", "bdType3", "bdType4" }
    for i, prefix in ipairs(slots) do
        local entry = types[i]
        local bg    = self[prefix .. "Bg"]
        local title = self[prefix .. "Title"]
        local desc  = self[prefix .. "Desc"]
        local btn   = self[prefix .. "Btn"]
        local vis   = entry ~= nil
        if bg    then bg:setVisible(vis)    end
        if btn   then btn:setVisible(vis)   end
        if title then
            title:setVisible(vis)
            if vis then title:setText(entry.title) end
        end
        if desc then
            desc:setVisible(vis)
            if vis then desc:setText(entry.desc) end
        end
    end
end

function CTBuilderDialog:_renderStep3()
    local t   = self._selectedKey or ""
    local cat = self._category    or ""

    -- ---------------------------------------------------------------
    -- Amount field
    -- Economy: always shown. Chained: shown for step2Amount (except BRANCHING).
    -- ---------------------------------------------------------------
    local showAmount = (cat == "ECONOMY") or
                       (cat == "CHAINED" and t ~= "BRANCHING")

    if self.bdAmountLabel then
        self.bdAmountLabel:setVisible(showAmount)
        if showAmount then
            if cat == "CHAINED" then
                self.bdAmountLabel:setText("Step 2 Reward ($):")
            else
                self.bdAmountLabel:setText("Amount ($):")
            end
        end
    end
    if self.bdAmountValue then
        self.bdAmountValue:setVisible(showAmount)
        if showAmount then self.bdAmountValue:setText(tostring(self._config.amount)) end
    end
    for _, suffix in ipairs({ "bdAmtDecBg", "bdAmtDecTxt", "bdAmtDecBtn",
                               "bdAmtIncBg", "bdAmtIncTxt", "bdAmtIncBtn" }) do
        if self[suffix] then self[suffix]:setVisible(showAmount) end
    end

    -- ---------------------------------------------------------------
    -- Message field
    -- TALK_NPC, Notifications, all Chained, FIRE_EVENT (event name)
    -- ---------------------------------------------------------------
    local showMsg = (cat == "NOTIFICATION") or (t == "TALK_NPC") or
                    (cat == "CHAINED") or (t == "FIRE_EVENT") or (t == "GIVE_ITEM")

    if self.bdMessageLabel then
        self.bdMessageLabel:setVisible(showMsg)
        if showMsg then
            if cat == "CHAINED" then
                self.bdMessageLabel:setText("Step 1 Message:")
            elseif t == "FIRE_EVENT" then
                self.bdMessageLabel:setText("Event Name (key):")
            elseif t == "GIVE_ITEM" then
                self.bdMessageLabel:setText("Item Name:")
            else
                self.bdMessageLabel:setText("Message:")
            end
        end
    end
    if self.bdMessageInput then self.bdMessageInput:setVisible(showMsg) end

    -- ---------------------------------------------------------------
    -- Body field
    -- Notifications: body/subtitle. Chained: step 2 message.
    -- ---------------------------------------------------------------
    local showBody = (cat == "NOTIFICATION") or (cat == "CHAINED")

    if self.bdBodyLabel then
        self.bdBodyLabel:setVisible(showBody)
        if showBody then
            if cat == "CHAINED" then
                self.bdBodyLabel:setText("Step 2 Message:")
            else
                self.bdBodyLabel:setText("Body (optional):")
            end
        end
    end
    if self.bdBodyInput then self.bdBodyInput:setVisible(showBody) end

    -- ---------------------------------------------------------------
    -- Step 3 hint
    -- ---------------------------------------------------------------
    if self.bdStep3Hint then
        self.bdStep3Hint:setText("Configure: " .. (self._selectedKey or ""))
    end
end

function CTBuilderDialog:_renderStep4()
    local isCond = (self._category == "CONDITIONAL")
    local t = self._selectedKey or ""

    -- Toggle stub vs condition-specific display
    if self.bdStep4Info then self.bdStep4Info:setVisible(not isCond) end
    if self.bdStep4Sub  then self.bdStep4Sub:setVisible(not isCond)  end

    if self.bdStep4Hint then
        self.bdStep4Hint:setText(isCond and ("Configure condition: " .. t) or "Conditions (optional)")
    end

    local showCond1 = isCond and (t == "TIME_CHECK" or t == "MONEY_CHECK" or t == "RANDOM")
    local showCond2 = isCond and (t == "TIME_CHECK")

    local cond1Ids = { "bdCond1Label","bdCond1Value","bdCond1DecBg","bdCond1DecTxt","bdCond1DecBtn","bdCond1IncBg","bdCond1IncTxt","bdCond1IncBtn" }
    for _, id in ipairs(cond1Ids) do
        if self[id] then self[id]:setVisible(showCond1) end
    end
    local cond2Ids = { "bdCond2Label","bdCond2Value","bdCond2DecBg","bdCond2DecTxt","bdCond2DecBtn","bdCond2IncBg","bdCond2IncTxt","bdCond2IncBtn" }
    for _, id in ipairs(cond2Ids) do
        if self[id] then self[id]:setVisible(showCond2) end
    end

    if not isCond then return end

    if t == "TIME_CHECK" then
        if self.bdCond1Label then self.bdCond1Label:setText("From hour (0-23):") end
        if self.bdCond1Value then self.bdCond1Value:setText(tostring(self._config.timeFrom)) end
        if self.bdCond1DecTxt then self.bdCond1DecTxt:setText("-1h") end
        if self.bdCond1IncTxt then self.bdCond1IncTxt:setText("+1h") end
        if self.bdCond2Label then self.bdCond2Label:setText("To hour (0-23):") end
        if self.bdCond2Value then self.bdCond2Value:setText(tostring(self._config.timeTo)) end
        if self.bdCond2DecTxt then self.bdCond2DecTxt:setText("-1h") end
        if self.bdCond2IncTxt then self.bdCond2IncTxt:setText("+1h") end
    elseif t == "MONEY_CHECK" then
        if self.bdCond1Label then self.bdCond1Label:setText("Minimum balance ($):") end
        if self.bdCond1Value then self.bdCond1Value:setText(tostring(self._config.minMoney)) end
        if self.bdCond1DecTxt then self.bdCond1DecTxt:setText("-100") end
        if self.bdCond1IncTxt then self.bdCond1IncTxt:setText("+100") end
    elseif t == "RANDOM" then
        if self.bdCond1Label then self.bdCond1Label:setText("Probability (%):") end
        local pct = math.floor(self._config.probability * 100 + 0.5)
        if self.bdCond1Value then self.bdCond1Value:setText(tostring(pct)) end
        if self.bdCond1DecTxt then self.bdCond1DecTxt:setText("-10%") end
        if self.bdCond1IncTxt then self.bdCond1IncTxt:setText("+10%") end
    elseif t == "ITEM_CHECK" then
        if self.bdStep4Info then
            self.bdStep4Info:setText("Item Check — inventory integration in Phase 5.")
            self.bdStep4Info:setVisible(true)
        end
        if self.bdStep4Sub then
            self.bdStep4Sub:setText("Trigger will pass through unconditionally for now.")
            self.bdStep4Sub:setVisible(true)
        end
    end
end

function CTBuilderDialog:_renderStep5()
    if self.bdStep5Hint then
        self.bdStep5Hint:setText("Actions (optional)")
    end
    if self.bdStep5Info then
        self.bdStep5Info:setText("Full action builder coming in the next update.\nSkip to continue without custom actions.")
    end
end

function CTBuilderDialog:_renderStep6()
    if self.bdCooldownValue then
        local cd = self._config.cooldownSec
        self.bdCooldownValue:setText(cd == 0 and "None" or (cd .. "s"))
    end
    if self.bdRepeatValue then
        local rl = self._config.repeatLimit
        self.bdRepeatValue:setText(rl == 0 and "Unlimited" or tostring(rl))
    end
    if self.bdConfirmTogText then
        self.bdConfirmTogText:setText(self._config.requireConfirm and "ON" or "OFF")
    end
end

function CTBuilderDialog:_renderStep7()
    if self.bdNameInput then
        self.bdNameInput:setText(self._triggerName)
    end
    if self.bdStep7Hint then
        self.bdStep7Hint:setText("Give your trigger a name:")
    end
end

function CTBuilderDialog:_renderStep8()
    local typeEntry = self:_findTypeEntry(self._selectedKey)
    local typeLabel = typeEntry and typeEntry.title or (self._selectedKey or "?")

    local function setLine(id, text)
        local el = self[id]
        if el then el:setText(text or "") end
    end

    setLine("bdReviewName",     "Name:      " .. self._triggerName)
    setLine("bdReviewCategory", "Category:  " .. (self._category or ""))
    setLine("bdReviewType",     "Type:      " .. typeLabel)

    local cd = self._config.cooldownSec
    setLine("bdReviewCooldown", "Cooldown:  " .. (cd == 0 and "None" or cd .. "s"))

    local rl = self._config.repeatLimit
    setLine("bdReviewRepeat",   "Repeat:    " .. (rl == 0 and "Unlimited" or tostring(rl)))

    setLine("bdReviewConfirm",  "Confirm:   " .. (self._config.requireConfirm and "Yes" or "No"))
end

-- ---------------------------------------------------------------------------
-- Step 2: type selection
-- ---------------------------------------------------------------------------

function CTBuilderDialog:_selectType(slotIndex)
    local entry = self._types[slotIndex]
    if not entry then return end
    self._selectedKey = entry.key
    self:_buildConfigForType()
    self._step = 3
    self:_render()
end

function CTBuilderDialog:_buildConfigForType()
    local cat = self._category
    local t   = self._selectedKey
    -- Pre-fill sensible defaults per type
    if cat == "ECONOMY" then
        self._config.amount = (t == "PAY_FEE") and 50 or
                              (t == "EARN")     and 100 or 200
    elseif t == "TALK_NPC" then
        self._config.message = "Hello, farmer!"
    elseif t == "FIRE_EVENT" then
        self._config.message = ""  -- player types the event key name
    elseif t == "GIVE_ITEM" then
        self._config.message = "item"
    elseif cat == "NOTIFICATION" then
        self._config.message = self._triggerName
        self._config.body    = ""
    elseif cat == "CONDITIONAL" then
        if t == "TIME_CHECK" then
            self._config.timeFrom = 6
            self._config.timeTo   = 20
        elseif t == "MONEY_CHECK" then
            self._config.minMoney = 500
        elseif t == "RANDOM" then
            self._config.probability = 0.5
        end
    elseif cat == "CHAINED" then
        self._config.message      = "Starting..."
        self._config.body         = "Complete!"
        self._config.amount       = 0
    end
end

function CTBuilderDialog:onSelectType1() self:_selectType(1) end
function CTBuilderDialog:onSelectType2() self:_selectType(2) end
function CTBuilderDialog:onSelectType3() self:_selectType(3) end
function CTBuilderDialog:onSelectType4() self:_selectType(4) end

-- ---------------------------------------------------------------------------
-- Step 3: amount +/- buttons
-- ---------------------------------------------------------------------------

function CTBuilderDialog:onAmtDec10()
    self._config.amount = math.max(0, self._config.amount - 10)
    if self.bdAmountValue then self.bdAmountValue:setText(tostring(self._config.amount)) end
end
function CTBuilderDialog:onAmtDec100()
    self._config.amount = math.max(0, self._config.amount - 100)
    if self.bdAmountValue then self.bdAmountValue:setText(tostring(self._config.amount)) end
end
function CTBuilderDialog:onAmtInc10()
    self._config.amount = self._config.amount + 10
    if self.bdAmountValue then self.bdAmountValue:setText(tostring(self._config.amount)) end
end
function CTBuilderDialog:onAmtInc100()
    self._config.amount = self._config.amount + 100
    if self.bdAmountValue then self.bdAmountValue:setText(tostring(self._config.amount)) end
end

-- ---------------------------------------------------------------------------
-- Step 6: advanced option controls
-- ---------------------------------------------------------------------------

function CTBuilderDialog:onCooldownDec()
    self._config.cooldownSec = math.max(0, self._config.cooldownSec - 30)
    self:_renderStep6()
end
function CTBuilderDialog:onCooldownInc()
    self._config.cooldownSec = self._config.cooldownSec + 30
    self:_renderStep6()
end
function CTBuilderDialog:onRepeatDec()
    self._config.repeatLimit = math.max(0, self._config.repeatLimit - 1)
    self:_renderStep6()
end
function CTBuilderDialog:onRepeatInc()
    self._config.repeatLimit = self._config.repeatLimit + 1
    self:_renderStep6()
end
function CTBuilderDialog:onToggleConfirm()
    self._config.requireConfirm = not self._config.requireConfirm
    self:_renderStep6()
end

-- ---------------------------------------------------------------------------
-- Step 4: condition value adjusters
-- ---------------------------------------------------------------------------

function CTBuilderDialog:onCond1Dec()
    local t = self._selectedKey or ""
    if t == "TIME_CHECK" then
        self._config.timeFrom = (self._config.timeFrom - 1 + 24) % 24
    elseif t == "MONEY_CHECK" then
        self._config.minMoney = math.max(0, self._config.minMoney - 100)
    elseif t == "RANDOM" then
        local p = math.floor(self._config.probability * 10 + 0.5) - 1
        self._config.probability = math.max(0, p) / 10
    end
    self:_renderStep4()
end

function CTBuilderDialog:onCond1Inc()
    local t = self._selectedKey or ""
    if t == "TIME_CHECK" then
        self._config.timeFrom = (self._config.timeFrom + 1) % 24
    elseif t == "MONEY_CHECK" then
        self._config.minMoney = self._config.minMoney + 100
    elseif t == "RANDOM" then
        local p = math.floor(self._config.probability * 10 + 0.5) + 1
        self._config.probability = math.min(10, p) / 10
    end
    self:_renderStep4()
end

function CTBuilderDialog:onCond2Dec()
    if self._selectedKey == "TIME_CHECK" then
        self._config.timeTo = (self._config.timeTo - 1 + 24) % 24
        self:_renderStep4()
    end
end

function CTBuilderDialog:onCond2Inc()
    if self._selectedKey == "TIME_CHECK" then
        self._config.timeTo = (self._config.timeTo + 1) % 24
        self:_renderStep4()
    end
end

-- ---------------------------------------------------------------------------
-- Navigation
-- ---------------------------------------------------------------------------

function CTBuilderDialog:onClickBack()
    if self._step > 2 then
        self._step = self._step - 1
        -- Step 5 (Actions) is skipped — jump over it both ways
        if self._step == 5 then self._step = 4 end
        self:_render()
    end
end

function CTBuilderDialog:onClickNext()
    -- Read live text inputs before advancing
    self:_readTextInputs()
    if self._step < 8 then
        self._step = self._step + 1
        -- Step 5 (Actions) is skipped — jump over it both ways
        if self._step == 5 then self._step = 6 end
        self:_render()
    end
end

function CTBuilderDialog:onClickCancel()
    self:close()
end

function CTBuilderDialog:onClickConfirm()
    self:_readTextInputs()
    self:_createTrigger()
end

-- ---------------------------------------------------------------------------
-- Read text input fields into config
-- ---------------------------------------------------------------------------

function CTBuilderDialog:_readTextInputs()
    -- Name field (step 7)
    if self.bdNameInput and self.bdNameInput.getText then
        local txt = self.bdNameInput:getText()
        if txt and txt ~= "" then self._triggerName = txt end
    end

    -- Message field (step 3)
    if self.bdMessageInput and self.bdMessageInput.getText then
        local txt = self.bdMessageInput:getText()
        if txt ~= nil then self._config.message = txt end
    end

    -- Body field (step 3)
    if self.bdBodyInput and self.bdBodyInput.getText then
        local txt = self.bdBodyInput:getText()
        if txt ~= nil then self._config.body = txt end
    end
end

-- ---------------------------------------------------------------------------
-- Trigger creation
-- ---------------------------------------------------------------------------

function CTBuilderDialog:_createTrigger()
    if not g_CTCSystem or not g_CTCSystem.triggerRegistry then
        Logger.error("CTBuilderDialog: registry not available")
        self:close()
        return
    end

    -- ---------------------------------------------------------------
    -- Sanitize trigger name
    -- ---------------------------------------------------------------
    self._triggerName = self:_sanitizeName(self._triggerName)

    -- ---------------------------------------------------------------
    -- Capture player world position at creation time
    -- ---------------------------------------------------------------
    local worldX, worldY, worldZ = 0, 0, 0
    if g_localPlayer and g_localPlayer.rootNode then
        worldX, worldY, worldZ = getWorldTranslation(g_localPlayer.rootNode)
    end
    self._config.worldX = worldX
    self._config.worldY = worldY
    self._config.worldZ = worldZ

    -- ---------------------------------------------------------------
    -- Map generic message/body/amount → category-specific config keys
    -- ---------------------------------------------------------------
    local cat = self._category
    local t   = self._selectedKey

    if cat == "NOTIFICATION" then
        -- Wizard stores the notification title in "message"; map it to "title"
        -- so NotificationTrigger can read it directly by the documented key.
        if self._config.message ~= "" then
            self._config.title = self._config.message
        end

    elseif cat == "CHAINED" then
        -- Map the wizard's message/body/amount to chained trigger fields
        if self._config.message ~= "" then
            self._config.stepMessage = self._config.message
        end
        if self._config.body ~= "" then
            self._config.step2Message = self._config.body
        end
        self._config.step2Amount = self._config.amount or 0
        -- Provide defaults for confirm message if not set
        if not self._config.confirmMessage or self._config.confirmMessage == "" then
            self._config.confirmMessage = "Continue?"
        end
        if not self._config.timerSec then
            self._config.timerSec = 10
        end

    elseif t == "FIRE_EVENT" then
        -- The message field holds the event key name
        self._config.eventName = self._config.message

    elseif t == "GIVE_ITEM" then
        -- The message field holds the item name
        self._config.itemName = self._config.message
    end

    local trigger = g_CTCSystem.triggerRegistry:add({
        name     = self._triggerName,
        category = cat,
        type     = t,
        config   = self._config,
    })

    if not trigger then
        -- Registry rejected the trigger (max limit hit) — tell the player
        if g_CTCSystem.notificationHUD then
            local max = (g_CTCSystem.settings and g_CTCSystem.settings.maxTriggersPerSave) or 100
            g_CTCSystem.notificationHUD:push(
                "Trigger Limit Reached",
                "Cannot create more than " .. max .. " triggers.",
                "WARNING"
            )
        end
        self:close()
        return
    end

    Logger.module("CTBuilderDialog", "Created: " .. trigger.id ..
        string.format(" @ %.1f,%.1f,%.1f", worldX, worldY, worldZ))

    -- Success notification
    if g_CTCSystem.notificationHUD then
        g_CTCSystem.notificationHUD:push("Trigger Created", trigger.name, "SUCCESS")
    end

    -- Refresh hotspot map icon
    if g_CTCSystem.hotspotManager then
        g_CTCSystem.hotspotManager:refreshFromRegistry(g_CTCSystem.triggerRegistry)
    end

    -- Refresh proximity world zones
    if g_CTCSystem.worldManager then
        g_CTCSystem.worldManager:refresh(g_CTCSystem.triggerRegistry)
    end

    self:close()

    -- Refresh management dialog if open
    local mgr = DialogLoader.getDialog("CTManagementDialog")
    if mgr and mgr.refresh then mgr:refresh() end
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

function CTBuilderDialog:_findTypeEntry(key)
    if not key then return nil end
    for _, entry in ipairs(self._types) do
        if entry.key == key then return entry end
    end
    return nil
end

---Sanitize a trigger name for safe display and XML storage.
---Strips XML-special characters, trims whitespace, enforces max length.
---@param name string
---@return string
function CTBuilderDialog:_sanitizeName(name)
    if not name then return "Trigger" end
    -- Strip XML special chars that would corrupt ctc_data.xml
    name = name:gsub("[<>&\"']", "")
    -- Trim leading/trailing whitespace
    name = name:match("^%s*(.-)%s*$") or name
    -- Enforce a sane display length
    if #name > 60 then name = name:sub(1, 60) end
    -- Final fallback
    if name == "" then name = "Trigger" end
    return name
end
