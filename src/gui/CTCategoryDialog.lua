-- =========================================================
-- CTCategoryDialog.lua — FS25_CustomTriggerCreator
-- Step 1: Player selects a trigger category.
-- On selection → opens CTBuilderDialog with chosen category.
-- =========================================================

CTCategoryDialog = {}
local CTCategoryDialog_mt = Class(CTCategoryDialog, MessageDialog)

-- Category keys — must match translation keys and builder type maps
CTCategoryDialog.CATEGORIES = {
    ECONOMY       = "Economy",
    INTERACTION   = "Interaction",
    CONDITIONAL   = "Conditional",
    CHAINED       = "Chained",
    NOTIFICATION  = "Notification",
    CUSTOM_SCRIPT = "Custom Script",
}

function CTCategoryDialog.new(target, custom_mt)
    local self = MessageDialog.new(target, custom_mt or CTCategoryDialog_mt)
    return self
end

function CTCategoryDialog:onCreate()
    local ok, err = pcall(function()
        CTCategoryDialog:superClass().onCreate(self)
    end)
    if not ok then
        Logger.error("CTCategoryDialog:onCreate(): " .. tostring(err))
    end
end

function CTCategoryDialog:onDialogOpen()
    local ok, err = pcall(function()
        CTCategoryDialog:superClass().onOpen(self)
    end)
    if not ok then
        Logger.error("CTCategoryDialog:onDialogOpen(): " .. tostring(err))
    end

    -- Custom Script category requires Admin Mode
    local adminMode = g_CTCSystem and g_CTCSystem.settings and g_CTCSystem.settings.adminMode or false
    local scriptElems = { "catScriptBg", "catScriptTitle", "catScriptDesc", "catScriptBtn" }
    for _, id in ipairs(scriptElems) do
        if self[id] then self[id]:setVisible(adminMode) end
    end
end

function CTCategoryDialog:onDialogClose()
    local ok, err = pcall(function()
        CTCategoryDialog:superClass().onClose(self)
    end)
    if not ok then
        Logger.debug("CTCategoryDialog:onDialogClose(): " .. tostring(err))
    end
end

-- ---------------------------------------------------------------------------
-- Category selection handlers
-- ---------------------------------------------------------------------------

function CTCategoryDialog:_selectCategory(categoryKey)
    Logger.module("CTCategoryDialog", "Selected: " .. categoryKey)
    self:close()
    -- Open builder with selected category
    DialogLoader.show("CTBuilderDialog", "startWizard", categoryKey)
end

function CTCategoryDialog:onSelectEconomy()       self:_selectCategory("ECONOMY")       end
function CTCategoryDialog:onSelectInteraction()   self:_selectCategory("INTERACTION")   end
function CTCategoryDialog:onSelectConditional()   self:_selectCategory("CONDITIONAL")   end
function CTCategoryDialog:onSelectChained()       self:_selectCategory("CHAINED")       end
function CTCategoryDialog:onSelectNotification()  self:_selectCategory("NOTIFICATION")  end
function CTCategoryDialog:onSelectCustomScript()  self:_selectCategory("CUSTOM_SCRIPT") end

function CTCategoryDialog:onClickCancel()
    self:close()
end
