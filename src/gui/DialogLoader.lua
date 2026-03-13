-- =========================================================
-- DialogLoader.lua — FS25_CustomTriggerCreator
-- Centralized dialog registration and management.
-- Adapted from FS25_NPCFavor — prefix changed to [CTC].
--
-- Usage:
--   DialogLoader.register("CTManagementDialog", CTManagementDialog, "gui/CTManagementDialog.xml")
--   DialogLoader.show("CTManagementDialog")
--   DialogLoader.close("CTManagementDialog")
-- =========================================================

DialogLoader = {}

-- Registry: name -> { class, xmlPath, instance, loaded }
DialogLoader.dialogs = {}

-- Mod directory (set once during init)
DialogLoader.modDirectory = nil

---Initialize with the mod's base directory path.
---@param modDir string  Mod directory (with trailing slash)
function DialogLoader.init(modDir)
    DialogLoader.modDirectory = modDir
end

---Register a dialog class and XML path for lazy loading.
---@param name        string  Unique dialog name
---@param dialogClass table   The Lua class table (must have .new())
---@param xmlPath     string  Relative path from mod root to the XML layout file
function DialogLoader.register(name, dialogClass, xmlPath)
    if not name or not dialogClass or not xmlPath then
        Logger.error("[DialogLoader] register() requires name, class, xmlPath")
        return
    end
    DialogLoader.dialogs[name] = {
        class   = dialogClass,
        xmlPath = xmlPath,
        instance = nil,
        loaded  = false,
    }
end

---Ensure a dialog is loaded into g_gui (lazy load on first use).
---@param name string
---@return boolean  true if dialog is loaded and ready
function DialogLoader.ensureLoaded(name)
    local entry = DialogLoader.dialogs[name]
    if not entry then
        Logger.error("[DialogLoader] Dialog '" .. tostring(name) .. "' not registered")
        return false
    end

    if entry.loaded then return true end

    if not g_gui then
        Logger.error("[DialogLoader] g_gui not available")
        return false
    end

    local modDir = DialogLoader.modDirectory
    if not modDir then
        Logger.error("[DialogLoader] modDirectory not set — call DialogLoader.init() first")
        return false
    end

    local ok, err = pcall(function()
        local instance = entry.class.new()
        g_gui:loadGui(modDir .. entry.xmlPath, name, instance)
        entry.instance = instance
        entry.loaded = true
    end)

    if not ok then
        Logger.error("[DialogLoader] Error loading '" .. name .. "': " .. tostring(err))
        return false
    end

    if g_gui.guis and g_gui.guis[name] then
        Logger.module("DialogLoader", "'" .. name .. "' loaded OK")
        return true
    else
        Logger.warn("[DialogLoader] '" .. name .. "' loadGui completed but not found in g_gui.guis")
        entry.loaded = false
        return false
    end
end

---Show a dialog, optionally calling a data-setter method first.
---@param name       string  Dialog name
---@param dataMethod string|nil  Name of method to call before show
---@param ...        any     Arguments passed to the data-setter
---@return boolean  true if dialog was shown
function DialogLoader.show(name, dataMethod, ...)
    if not DialogLoader.ensureLoaded(name) then return false end

    local entry = DialogLoader.dialogs[name]
    if not entry or not entry.instance then return false end

    if dataMethod and entry.instance[dataMethod] then
        local ok, err = pcall(entry.instance[dataMethod], entry.instance, ...)
        if not ok then
            Logger.error("[DialogLoader] Error calling " .. name .. ":" .. dataMethod .. "(): " .. tostring(err))
        end
    end

    local ok, err = pcall(function() g_gui:showDialog(name) end)
    if not ok then
        Logger.error("[DialogLoader] Error showing '" .. name .. "': " .. tostring(err))
        return false
    end

    return true
end

---Get the dialog instance for direct method calls.
---@param name string
---@return table|nil
function DialogLoader.getDialog(name)
    local entry = DialogLoader.dialogs[name]
    return entry and entry.instance or nil
end

---Close a dialog if visible.
---@param name string
function DialogLoader.close(name)
    local entry = DialogLoader.dialogs[name]
    if entry and entry.instance then
        pcall(function() entry.instance:close() end)
    end
end

---Unload all dialogs (call on mod unload).
function DialogLoader.cleanup()
    for name, entry in pairs(DialogLoader.dialogs) do
        if entry.instance then
            pcall(function() entry.instance:close() end)
        end
        entry.instance = nil
        entry.loaded = false
    end
end

Logger.module("DialogLoader", "Loaded")
