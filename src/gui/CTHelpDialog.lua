-- =========================================================
-- CTHelpDialog.lua — FS25_CustomTriggerCreator
-- Quick-reference help panel for trigger types and usage.
-- Opened from the Help button in CTManagementDialog.
-- =========================================================

CTHelpDialog = {}
local CTHelpDialog_mt = Class(CTHelpDialog, MessageDialog)

function CTHelpDialog.new(target, custom_mt)
    local self = MessageDialog.new(target, custom_mt or CTHelpDialog_mt)
    return self
end

function CTHelpDialog:onCreate()
    local ok, err = pcall(function()
        CTHelpDialog:superClass().onCreate(self)
    end)
    if not ok then
        Logger.error("CTHelpDialog:onCreate(): " .. tostring(err))
    end
end

function CTHelpDialog:onDialogOpen()
    local ok, err = pcall(function()
        CTHelpDialog:superClass().onOpen(self)
    end)
    if not ok then
        Logger.error("CTHelpDialog:onDialogOpen(): " .. tostring(err))
    end
end

function CTHelpDialog:onDialogClose()
    local ok, err = pcall(function()
        CTHelpDialog:superClass().onClose(self)
    end)
    if not ok then
        Logger.debug("CTHelpDialog:onDialogClose(): " .. tostring(err))
    end
end

function CTHelpDialog:onClickClose()
    self:close()
end
