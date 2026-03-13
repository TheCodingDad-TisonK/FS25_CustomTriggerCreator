-- =========================================================
-- CTBuilderDialog.lua — FS25_CustomTriggerCreator
-- Wizard steps 2–8.
--   Step 2: Select trigger type within the chosen category
--   Step 3: Configure type-specific settings
--   Step 4: Set conditions (stub — Phase 4 full impl)
--   Step 5: Set actions (stub — Phase 4 full impl)
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

-- Step labels shown in the wizard header
CTBuilderDialog.STEP_LABELS = {
    [2] = "Step 2 of 8 — Choose Type",
    [3] = "Step 3 of 8 — Configure",
    [4] = "Step 4 of 8 — Conditions",
    [5] = "Step 5 of 8 — Actions",
    [6] = "Step 6 of 8 — Advanced Options",
    [7] = "Step 7 of 8 — Name Your Trigger",
    [8] = "Step 8 of 8 — Review & Confirm",
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
    -- Show type-appropriate fields. All other fields hidden.
    local t = self._selectedKey or ""
    local cat = self._category or ""

    -- Amount field (Economy types)
    local showAmount = (cat == "ECONOMY")
    local amtLabel = self.bdAmountLabel
    local amtVal   = self.bdAmountValue
    if amtLabel then amtLabel:setVisible(showAmount) end
    if amtVal   then
        amtVal:setVisible(showAmount)
        if showAmount then amtVal:setText(tostring(self._config.amount)) end
    end
    if self.bdAmtDecBtn  then self.bdAmtDecBtn:setVisible(showAmount)  end
    if self.bdAmtIncBtn  then self.bdAmtIncBtn:setVisible(showAmount)  end
    if self.bdAmtDecBg   then self.bdAmtDecBg:setVisible(showAmount)   end
    if self.bdAmtIncBg   then self.bdAmtIncBg:setVisible(showAmount)   end
    if self.bdAmtDecTxt  then self.bdAmtDecTxt:setVisible(showAmount)  end
    if self.bdAmtIncTxt  then self.bdAmtIncTxt:setVisible(showAmount)  end

    -- Message field (Interaction: TALK_NPC / Notification)
    local showMsg = (cat == "NOTIFICATION" or t == "TALK_NPC")
    local msgLabel = self.bdMessageLabel
    if msgLabel then msgLabel:setVisible(showMsg) end
    if self.bdMessageInput then self.bdMessageInput:setVisible(showMsg) end

    -- Body field (Notification only)
    local showBody = (cat == "NOTIFICATION")
    if self.bdBodyLabel then self.bdBodyLabel:setVisible(showBody) end
    if self.bdBodyInput  then self.bdBodyInput:setVisible(showBody)  end

    -- Step 3 hint
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
        -- Show stub info for Phase 5
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
    -- Actions stub
    if self.bdStep5Hint then
        self.bdStep5Hint:setText("Actions (optional)")
    end
    if self.bdStep5Info then
        self.bdStep5Info:setText("Full action builder coming in the next update.\nSkip to continue without custom actions.")
    end
end

function CTBuilderDialog:_renderStep6()
    -- Cooldown display
    if self.bdCooldownValue then
        local cd = self._config.cooldownSec
        self.bdCooldownValue:setText(cd == 0 and "None" or (cd .. "s"))
    end
    -- Repeat limit
    if self.bdRepeatValue then
        local rl = self._config.repeatLimit
        self.bdRepeatValue:setText(rl == 0 and "Unlimited" or tostring(rl))
    end
    -- Confirm toggle
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
        self:_render()
    end
end

function CTBuilderDialog:onClickNext()
    if self._step == 7 then
        -- Read name from TextInput if it loaded correctly
        if self.bdNameInput and self.bdNameInput.getText then
            local txt = self.bdNameInput:getText()
            if txt and txt ~= "" then self._triggerName = txt end
        end
    end
    if self._step < 8 then
        self._step = self._step + 1
        self:_render()
    end
end

function CTBuilderDialog:onClickCancel()
    self:close()
end

function CTBuilderDialog:onClickConfirm()
    self:_createTrigger()
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

    -- Final name read from input
    if self.bdNameInput and self.bdNameInput.getText then
        local txt = self.bdNameInput:getText()
        if txt and txt ~= "" then self._triggerName = txt end
    end

    local trigger = g_CTCSystem.triggerRegistry:add({
        name     = self._triggerName,
        category = self._category,
        type     = self._selectedKey,
        config   = self._config,
    })

    if trigger then
        Logger.module("CTBuilderDialog", "Created: " .. trigger.id)
        -- Fire a success notification
        if g_CTCSystem.notificationHUD then
            g_CTCSystem.notificationHUD:push(
                "Trigger Created",
                trigger.name,
                "SUCCESS"
            )
        end
    end

    self:close()

    -- Refresh management dialog
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
