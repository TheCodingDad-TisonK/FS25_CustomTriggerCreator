-- =========================================================
-- CTConfirmDialog.lua — FS25_CustomTriggerCreator
-- Generic Yes / No confirmation dialog.
-- Caller provides a callback; dialog invokes it with true/false.
--
-- Usage:
--   DialogLoader.show("CTConfirmDialog", "setup", {
--       title   = "Purchase Bulk Order",
--       message = "Buy 500 units of wheat for $2,500?",
--       detail  = "This cannot be undone.",
--       onYes   = function() ... end,
--       onNo    = function() ... end,    -- optional
--   })
-- =========================================================

CTConfirmDialog = {}
local CTConfirmDialog_mt = Class(CTConfirmDialog, MessageDialog)

function CTConfirmDialog.new(target, custom_mt)
    local self = MessageDialog.new(target, custom_mt or CTConfirmDialog_mt)
    self._onYes = nil
    self._onNo  = nil
    return self
end

function CTConfirmDialog:onCreate()
    local ok, err = pcall(function()
        CTConfirmDialog:superClass().onCreate(self)
    end)
    if not ok then
        Logger.error("CTConfirmDialog:onCreate(): " .. tostring(err))
    end
end

function CTConfirmDialog:onDialogOpen()
    local ok, err = pcall(function()
        CTConfirmDialog:superClass().onOpen(self)
    end)
    if not ok then
        Logger.error("CTConfirmDialog:onDialogOpen(): " .. tostring(err))
    end
end

function CTConfirmDialog:onDialogClose()
    local ok, err = pcall(function()
        CTConfirmDialog:superClass().onClose(self)
    end)
    if not ok then
        Logger.debug("CTConfirmDialog:onDialogClose(): " .. tostring(err))
    end
    -- Clear callbacks on close to avoid stale references
    self._onYes = nil
    self._onNo  = nil
end

---Configure the dialog before showing.
---@param opts table  { title, message, detail, onYes, onNo }
function CTConfirmDialog:setup(opts)
    opts = opts or {}

    self._onYes = opts.onYes
    self._onNo  = opts.onNo

    if self.cfTitleText    then self.cfTitleText:setText(opts.title   or "Confirm?")  end
    if self.cfMessageLine1 then self.cfMessageLine1:setText(opts.message or "")        end
    if self.cfMessageLine2 then self.cfMessageLine2:setText(opts.message2 or "")       end
    if self.cfDetailText   then self.cfDetailText:setText(opts.detail  or "")          end

    -- Custom button labels
    if self.cfYesText then self.cfYesText:setText(opts.yesLabel or "Yes") end
    if self.cfNoText  then self.cfNoText:setText(opts.noLabel  or "No")  end
end

function CTConfirmDialog:onClickYes()
    self:close()
    if self._onYes then
        local ok, err = pcall(self._onYes)
        if not ok then
            Logger.error("CTConfirmDialog onYes callback error: " .. tostring(err))
        end
    end
end

function CTConfirmDialog:onClickNo()
    self:close()
    if self._onNo then
        local ok, err = pcall(self._onNo)
        if not ok then
            Logger.error("CTConfirmDialog onNo callback error: " .. tostring(err))
        end
    end
end
