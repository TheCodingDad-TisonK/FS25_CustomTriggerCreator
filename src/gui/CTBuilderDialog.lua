-- =========================================================
-- CTBuilderDialog.lua — FS25_CustomTriggerCreator
-- Wizard steps 2-3 (Phase 2).
--   Step 2: Select trigger type within the chosen category.
--   Step 3: Name the trigger and confirm.
-- Data flows in via startWizard(categoryKey).
-- =========================================================

CTBuilderDialog = {}
local CTBuilderDialog_mt = Class(CTBuilderDialog, MessageDialog)

-- Types available per category in Phase 2.
-- Each entry: { key, title, description }
CTBuilderDialog.TYPES = {
    ECONOMY = {
        { key = "BUY_SELL",  title = "Buy / Sell",    desc = "Exchange goods at a price" },
        { key = "PAY_FEE",   title = "Pay Fee",        desc = "Charge a flat fee on entry" },
        { key = "EARN",      title = "Earn Reward",    desc = "Pay the player a sum" },
        { key = "BARTER",    title = "Barter",         desc = "Trade items for items" },
    },
    INTERACTION = {
        { key = "TALK_NPC",  title = "Talk to NPC",   desc = "Open an NPC dialog" },
        { key = "GIVE_ITEM", title = "Receive Item",  desc = "Hand an item to the player" },
        { key = "FIRE_EVENT",title = "Fire Event",    desc = "Trigger a registered event" },
        { key = "ANIMATION", title = "Play Animation",desc = "Play a world animation" },
    },
    CONDITIONAL = {
        { key = "TIME_CHECK",  title = "Time Check",   desc = "Gate on game time of day" },
        { key = "MONEY_CHECK", title = "Money Check",  desc = "Gate on player balance" },
        { key = "ITEM_CHECK",  title = "Item Check",   desc = "Gate on inventory content" },
        { key = "RANDOM",      title = "Random Chance",desc = "Probability-based gate" },
    },
    CHAINED = {
        { key = "TWO_STEP",    title = "2-Step",       desc = "Action → confirm → reward" },
        { key = "THREE_STEP",  title = "3-Step",       desc = "Triple confirmation flow" },
        { key = "BRANCHING",   title = "Branching",    desc = "Yes/No split path" },
        { key = "TIMED",       title = "Timed Steps",  desc = "Countdown between steps" },
    },
    NOTIFICATION = {
        { key = "INFO",    title = "Info Alert",    desc = "Blue informational toast" },
        { key = "SUCCESS", title = "Success Alert", desc = "Green success toast" },
        { key = "WARNING", title = "Warning Alert", desc = "Yellow warning toast" },
        { key = "ERROR",   title = "Error Alert",   desc = "Red error toast" },
    },
    CUSTOM_SCRIPT = {
        { key = "CALLBACK",   title = "Lua Callback",   desc = "Call a registered Lua fn" },
        { key = "EVENT_HOOK", title = "Event Hook",     desc = "Subscribe to a game event" },
        { key = "SCHEDULED",  title = "Scheduled Call", desc = "Run on a time interval" },
        { key = "CONDITIONAL_CB", title = "Conditional Callback", desc = "Callback with gate logic" },
    },
}

function CTBuilderDialog.new(target, custom_mt)
    local self = MessageDialog.new(target, custom_mt or CTBuilderDialog_mt)
    self._category    = nil
    self._step        = 2
    self._selectedKey = nil
    self._triggerName = ""
    self._types       = {}
    return self
end

function CTBuilderDialog:onCreate()
    local ok, err = pcall(function()
        CTBuilderDialog:superClass().onCreate(self)
    end)
    if not ok then
        Logger.error("CTBuilderDialog:onCreate(): " .. tostring(err))
    end
end

function CTBuilderDialog:onDialogOpen()
    local ok, err = pcall(function()
        CTBuilderDialog:superClass().onOpen(self)
    end)
    if not ok then
        Logger.error("CTBuilderDialog:onDialogOpen(): " .. tostring(err))
    end
end

function CTBuilderDialog:onDialogClose()
    local ok, err = pcall(function()
        CTBuilderDialog:superClass().onClose(self)
    end)
    if not ok then
        Logger.debug("CTBuilderDialog:onDialogClose(): " .. tostring(err))
    end
end

-- ---------------------------------------------------------------------------
-- Wizard entry point (called by DialogLoader.show)
-- ---------------------------------------------------------------------------

---Start the wizard from step 2 with a given category.
---@param categoryKey string  Key from CTCategoryDialog.CATEGORIES
function CTBuilderDialog:startWizard(categoryKey)
    self._category    = categoryKey or "ECONOMY"
    self._step        = 2
    self._selectedKey = nil
    self._types       = CTBuilderDialog.TYPES[self._category] or {}

    -- Auto-generate a default name
    local count = (g_CTCSystem and g_CTCSystem.triggerRegistry and
                   g_CTCSystem.triggerRegistry:count()) or 0
    self._triggerName = "Trigger " .. (count + 1)

    self:_renderStep()
end

-- ---------------------------------------------------------------------------
-- Rendering
-- ---------------------------------------------------------------------------

function CTBuilderDialog:_renderStep()
    local catLabel = self._category or ""
    if self.bdTitleText then
        self.bdTitleText:setText("New " .. catLabel .. " Trigger")
    end
    if self.bdStepText then
        if self._step == 2 then
            self.bdStepText:setText("Step 2 of 8 — Choose Type")
        else
            self.bdStepText:setText("Step 3 of 8 — Name & Confirm")
        end
    end

    -- Show/hide panels
    local showStep2 = (self._step == 2)
    if self.bdStep2Panel then self.bdStep2Panel:setVisible(showStep2)  end
    if self.bdStep3Panel then self.bdStep3Panel:setVisible(not showStep2) end

    -- Back button: disabled on step 2 (user came from CTCategoryDialog)
    if self.bdBackBtn then
        self.bdBackBtn:setVisible(self._step == 3)
    end

    -- Next button label
    if self.bdNextBtn then
        if self._step == 2 then
            self.bdNextBtn:setVisible(false)  -- advance via type selection
        else
            self.bdNextBtn:setVisible(true)
            -- setText via internal elements: use Text child of button
            -- buttonOK profile uses the game's built-in label
        end
    end

    if self._step == 2 then
        self:_renderTypeButtons()
    else
        self:_renderConfirmStep()
    end
end

function CTBuilderDialog:_renderTypeButtons()
    local types = self._types
    local ids = { "bdType1", "bdType2", "bdType3", "bdType4" }

    for i, prefix in ipairs(ids) do
        local entry = types[i]
        local titleEl = self[prefix .. "Title"]
        local descEl  = self[prefix .. "Desc"]
        local bgEl    = self[prefix .. "Bg"]
        local btnEl   = self[prefix .. "Btn"]

        if entry then
            if titleEl then titleEl:setText(entry.title) end
            if descEl  then descEl:setText(entry.desc)   end
            if bgEl    then bgEl:setVisible(true)         end
            if btnEl   then btnEl:setVisible(true)        end
            if titleEl then titleEl:setVisible(true)      end
            if descEl  then descEl:setVisible(true)       end
        else
            -- No type for this slot — hide
            if bgEl    then bgEl:setVisible(false)    end
            if btnEl   then btnEl:setVisible(false)   end
            if titleEl then titleEl:setVisible(false) end
            if descEl  then descEl:setVisible(false)  end
        end
    end
end

function CTBuilderDialog:_renderConfirmStep()
    local entry = self:_findTypeEntry(self._selectedKey)
    local typeLabel = entry and entry.title or (self._selectedKey or "?")

    if self.bdSummaryLine1 then
        self.bdSummaryLine1:setText("Category:  " .. (self._category or ""))
    end
    if self.bdSummaryLine2 then
        self.bdSummaryLine2:setText("Type:  " .. typeLabel)
    end
    if self.bdNameInput then
        self.bdNameInput:setText(self._triggerName)
    end
    if self.bdPreviewLabel then
        self.bdPreviewLabel:setText("Press Next to create this trigger.")
    end
end

-- ---------------------------------------------------------------------------
-- Type selection
-- ---------------------------------------------------------------------------

function CTBuilderDialog:_selectType(slotIndex)
    local entry = self._types[slotIndex]
    if not entry then return end
    self._selectedKey = entry.key
    Logger.module("CTBuilderDialog", "Type selected: " .. entry.key)
    -- Advance to step 3
    self._step = 3
    self:_renderStep()
end

function CTBuilderDialog:onSelectType1() self:_selectType(1) end
function CTBuilderDialog:onSelectType2() self:_selectType(2) end
function CTBuilderDialog:onSelectType3() self:_selectType(3) end
function CTBuilderDialog:onSelectType4() self:_selectType(4) end

-- ---------------------------------------------------------------------------
-- Navigation
-- ---------------------------------------------------------------------------

function CTBuilderDialog:onClickBack()
    if self._step == 3 then
        self._step = 2
        self:_renderStep()
    end
end

function CTBuilderDialog:onClickNext()
    if self._step == 3 then
        self:_createTrigger()
    end
end

function CTBuilderDialog:onClickCancel()
    self:close()
end

-- ---------------------------------------------------------------------------
-- Trigger creation
-- ---------------------------------------------------------------------------

function CTBuilderDialog:_createTrigger()
    if not g_CTCSystem or not g_CTCSystem.triggerRegistry then
        Logger.error("CTBuilderDialog: g_CTCSystem or registry not available")
        self:close()
        return
    end

    -- Read name from TextInput if available
    local name = self._triggerName
    if self.bdNameInput and self.bdNameInput.getText then
        local inputText = self.bdNameInput:getText()
        if inputText and inputText ~= "" then
            name = inputText
        end
    end

    local trigger = g_CTCSystem.triggerRegistry:add({
        name     = name,
        category = self._category,
        type     = self._selectedKey,
    })

    if trigger then
        Logger.module("CTBuilderDialog", "Created: " .. trigger.id .. " (" .. trigger.name .. ")")
    end

    self:close()

    -- Refresh management dialog
    local mgr = DialogLoader.getDialog("CTManagementDialog")
    if mgr and mgr.refresh then
        mgr:refresh()
    end
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
