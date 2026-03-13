-- =========================================================
-- CTManagementDialog.lua — FS25_CustomTriggerCreator
-- Lists all player-created triggers.
-- Edit / Delete / Toggle per row. Create New opens CTCategoryDialog.
-- =========================================================

CTManagementDialog = {}
local CTManagementDialog_mt = Class(CTManagementDialog, MessageDialog)

CTManagementDialog.MAX_ROWS = 10

function CTManagementDialog.new(target, custom_mt)
    local self = MessageDialog.new(target, custom_mt or CTManagementDialog_mt)
    self._rowIds = {}   -- rowNum (1-10) -> trigger id or nil
    self._page   = 1    -- current page (1-based)
    return self
end

function CTManagementDialog:onCreate()
    local ok, err = pcall(function()
        CTManagementDialog:superClass().onCreate(self)
    end)
    if not ok then
        Logger.error("CTManagementDialog:onCreate(): " .. tostring(err))
    end
end

function CTManagementDialog:onDialogOpen()
    local ok, err = pcall(function()
        CTManagementDialog:superClass().onOpen(self)
    end)
    if not ok then
        Logger.error("CTManagementDialog:onDialogOpen(): " .. tostring(err))
        return
    end
    self:refresh()
end

function CTManagementDialog:onDialogClose()
    local ok, err = pcall(function()
        CTManagementDialog:superClass().onClose(self)
    end)
    if not ok then
        Logger.debug("CTManagementDialog:onDialogClose(): " .. tostring(err))
    end
end

-- ---------------------------------------------------------------------------
-- Display refresh
-- ---------------------------------------------------------------------------

function CTManagementDialog:refresh()
    self._rowIds = {}

    local ctc = g_CTCSystem
    local reg = ctc and ctc.triggerRegistry
    local triggers = reg and reg:getAll() or {}
    local count = #triggers

    -- Clamp page to valid range
    local maxPage = math.max(1, math.ceil(count / self.MAX_ROWS))
    if self._page > maxPage then self._page = maxPage end
    if self._page < 1 then self._page = 1 end

    local pageStart = (self._page - 1) * self.MAX_ROWS + 1
    local pageEnd   = math.min(count, self._page * self.MAX_ROWS)

    -- Title / subtitle
    if self.titleText then
        self.titleText:setText("Custom Trigger Creator")
    end
    if self.subtitleText then
        self.subtitleText:setText(string.format("%d / %d triggers",
            count,
            (ctc and ctc.settings.maxTriggersPerSave) or 100))
    end

    -- Clear all rows first
    for i = 1, self.MAX_ROWS do
        self:_clearRow(i)
    end

    -- Fill rows for current page
    local row = 1
    for i = pageStart, pageEnd do
        local t = triggers[i]
        self._rowIds[row] = t.id
        self:_fillRow(row, t)
        row = row + 1
    end

    -- Footer text
    if self.footerText then
        if count == 0 then
            self.footerText:setText("No triggers yet — press 'Create New' to get started.")
        else
            self.footerText:setText("")
        end
    end

    -- Pagination UI
    if self.mgPageInfo then
        self.mgPageInfo:setText(self._page .. " / " .. maxPage)
    end
    if self.mgPrevBtn then
        self.mgPrevBtn:setVisible(self._page > 1)
    end
    if self.mgPrevBg then
        self.mgPrevBg:setVisible(self._page > 1)
    end
    if self.mgPrevText then
        self.mgPrevText:setVisible(self._page > 1)
    end
    if self.mgNextBtn then
        self.mgNextBtn:setVisible(self._page < maxPage)
    end
    if self.mgNextBg then
        self.mgNextBg:setVisible(self._page < maxPage)
    end
    if self.mgNextText then
        self.mgNextText:setVisible(self._page < maxPage)
    end
end

function CTManagementDialog:_clearRow(n)
    local s = "mg_r" .. n
    local function setT(id, v) local el = self[id]; if el then el:setText(v or "") end end
    setT(s .. "num",    "")
    setT(s .. "name",   "")
    setT(s .. "cat",    "")
    setT(s .. "type",   "")
    setT(s .. "status", "")
    -- Hide action buttons when empty
    local run = self[s .. "run"];    if run    then run:setVisible(false)    end
    local runbg = self[s .. "runbg"]; if runbg then runbg:setVisible(false)  end
    local runtxt = self[s .. "runtxt"]; if runtxt then runtxt:setVisible(false) end
    local tog = self[s .. "tog"];    if tog    then tog:setVisible(false)    end
    local togbg = self[s .. "togbg"]; if togbg then togbg:setVisible(false)  end
    local togtxt = self[s .. "togtxt"]; if togtxt then togtxt:setVisible(false) end
    local del = self[s .. "del"];    if del    then del:setVisible(false)    end
    local delbg = self[s .. "delbg"]; if delbg then delbg:setVisible(false)  end
    local deltxt = self[s .. "deltxt"]; if deltxt then deltxt:setVisible(false) end
end

function CTManagementDialog:_fillRow(n, trigger)
    local s = "mg_r" .. n
    local function setT(id, v) local el = self[id]; if el then el:setText(v or "") end end

    setT(s .. "num",    tostring(n))
    setT(s .. "name",   trigger.name)
    setT(s .. "cat",    trigger.category)
    setT(s .. "type",   trigger.type)

    local statusStr = trigger.enabled and "Active" or "Off"
    setT(s .. "status", statusStr)

    -- Color-code status cell
    local statusEl = self[s .. "status"]
    if statusEl then
        if trigger.enabled then
            statusEl:setTextColor(0.5, 1, 0.5, 1)
        else
            statusEl:setTextColor(0.5, 0.5, 0.5, 1)
        end
    end

    -- Toggle button label
    local togtxt = self[s .. "togtxt"]
    if togtxt then
        togtxt:setText(trigger.enabled and "ON" or "OFF")
    end

    -- Show action buttons
    local runbg  = self[s .. "runbg"];  if runbg  then runbg:setVisible(true)  end
    local runtxt = self[s .. "runtxt"]; if runtxt then runtxt:setVisible(true) end
    local run    = self[s .. "run"];    if run    then run:setVisible(true)    end
    local togbg  = self[s .. "togbg"];  if togbg  then togbg:setVisible(true)  end
    local togtxt2 = self[s .. "togtxt"]; if togtxt2 then togtxt2:setVisible(true) end
    local tog    = self[s .. "tog"];    if tog    then tog:setVisible(true)    end
    local delbg  = self[s .. "delbg"];  if delbg  then delbg:setVisible(true)  end
    local deltxt = self[s .. "deltxt"]; if deltxt then deltxt:setVisible(true) end
    local del    = self[s .. "del"];    if del    then del:setVisible(true)    end
end

-- ---------------------------------------------------------------------------
-- Button handlers
-- ---------------------------------------------------------------------------

function CTManagementDialog:_handleToggle(rowNum)
    local id = self._rowIds[rowNum]
    if not id or not g_CTCSystem then return end
    g_CTCSystem.triggerRegistry:toggle(id)
    -- Refresh world zone (activatable reads record.enabled live, but zone
    -- record reference is already the same table — no extra refresh needed)
    self:refresh()
end

function CTManagementDialog:_handleDelete(rowNum)
    local id = self._rowIds[rowNum]
    if not id or not g_CTCSystem then return end
    g_CTCSystem.triggerRegistry:remove(id)
    -- Remove map icon and proximity zone for the deleted trigger
    if g_CTCSystem.hotspotManager then
        g_CTCSystem.hotspotManager:removeHotspot(id)
    end
    if g_CTCSystem.worldManager then
        g_CTCSystem.worldManager:refresh(g_CTCSystem.triggerRegistry)
    end
    if g_CTCSystem.markerManager then
        g_CTCSystem.markerManager:refreshFromRegistry(g_CTCSystem.triggerRegistry)
    end
    self:refresh()
end

function CTManagementDialog:_handleRun(rowNum)
    local id = self._rowIds[rowNum]
    if not id or not g_CTCSystem or not g_CTCSystem.triggerExecutor then return end
    Logger.module("CTManagementDialog", "Running trigger: " .. id)
    g_CTCSystem.triggerExecutor:executeById(id)
end

-- Generate per-row button callbacks
for i = 1, CTManagementDialog.MAX_ROWS do
    local rowNum = i
    CTManagementDialog["onToggle"  .. i] = function(self) self:_handleToggle(rowNum)  end
    CTManagementDialog["onDelete"  .. i] = function(self) self:_handleDelete(rowNum)  end
    CTManagementDialog["onRun"     .. i] = function(self) self:_handleRun(rowNum)     end
end

function CTManagementDialog:onClickPrev()
    if self._page > 1 then
        self._page = self._page - 1
        self:refresh()
    end
end

function CTManagementDialog:onClickNext()
    local ctc = g_CTCSystem
    local count = ctc and ctc.triggerRegistry and ctc.triggerRegistry:count() or 0
    local maxPage = math.max(1, math.ceil(count / self.MAX_ROWS))
    if self._page < maxPage then
        self._page = self._page + 1
        self:refresh()
    end
end

function CTManagementDialog:onClickSettings()
    DialogLoader.show("CTSettingsDialog")
end

function CTManagementDialog:onClickHelp()
    DialogLoader.show("CTConfirmDialog", "setup", {
        title    = "Quick Help — Trigger Types",
        message  = "ECONOMY: charge/pay money.  INTERACTION: NPC dialog, items, events.  CONDITIONAL: gate on time/money/chance.  CHAINED: multi-step flows.  NOTIFICATION: HUD toast.  CUSTOM SCRIPT: Lua callbacks.",
        detail   = "Walk near a trigger and press [E] to activate. Press F8 to open this panel.",
        yesLabel = "Got it",
        noLabel  = "Close",
    })
end

function CTManagementDialog:onClickCreate()
    DialogLoader.show("CTCategoryDialog")
end

function CTManagementDialog:onClickExport()
    if not g_CTCSystem or not g_CTCSystem.triggerExporter then return end
    local ok, msg = g_CTCSystem.triggerExporter:export()
    if g_CTCSystem.notificationHUD then
        g_CTCSystem.notificationHUD:push("Export", msg, ok and "SUCCESS" or "WARNING")
    end
end

function CTManagementDialog:onClickImport()
    if not g_CTCSystem or not g_CTCSystem.triggerExporter then return end
    local ok, msg = g_CTCSystem.triggerExporter:import()
    if ok then self:refresh() end
    if g_CTCSystem.notificationHUD then
        g_CTCSystem.notificationHUD:push("Import", msg, ok and "SUCCESS" or "WARNING")
    end
end

function CTManagementDialog:onClickClose()
    self:close()
end
