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

    -- Fill rows
    for i = 1, math.min(count, self.MAX_ROWS) do
        local t = triggers[i]
        self._rowIds[i] = t.id
        self:_fillRow(i, t)
    end

    -- Footer
    if self.footerText then
        if count > self.MAX_ROWS then
            self.footerText:setText("Showing " .. self.MAX_ROWS .. " of " .. count)
        else
            self.footerText:setText("")
        end
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
    self:refresh()
end

function CTManagementDialog:_handleDelete(rowNum)
    local id = self._rowIds[rowNum]
    if not id or not g_CTCSystem then return end
    g_CTCSystem.triggerRegistry:remove(id)
    self:refresh()
end

-- Generate per-row button callbacks
for i = 1, CTManagementDialog.MAX_ROWS do
    local rowNum = i
    CTManagementDialog["onToggle"  .. i] = function(self) self:_handleToggle(rowNum)  end
    CTManagementDialog["onDelete"  .. i] = function(self) self:_handleDelete(rowNum)  end
end

function CTManagementDialog:onClickCreate()
    -- Open CTCategoryDialog; this dialog stays open behind it
    DialogLoader.show("CTCategoryDialog")
end

function CTManagementDialog:onClickClose()
    self:close()
end
