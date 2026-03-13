-- =========================================================
-- CTTriggerExporter.lua — FS25_CustomTriggerCreator
-- Exports the trigger registry to a standalone XML file
-- and imports from that file into the registry.
--
-- Export/import path: {savegameDirectory}/ctc_export.xml
-- =========================================================

CTTriggerExporter = {}
CTTriggerExporter._mt = { __index = CTTriggerExporter }

-- Config keys written/read during export/import
local CONFIG_KEYS = {
    "amount", "message", "body", "itemName", "eventName",
    "cooldownSec", "repeatLimit", "requireConfirm", "playerReceivesMoney",
    "quantity", "fillType",
    "stepMessage", "confirmMessage", "step2Message", "step3Message",
    "step2Amount", "step3Confirm",
    "branchPrompt", "yesMessage", "yesAmount", "noMessage", "noAmount",
    "timerSec",
    "timeFrom", "timeTo", "minMoney", "probability",
    "innerCategory", "innerType", "failMessage",
    "worldX", "worldZ",
}

---Create a CTTriggerExporter.
---@param registry TriggerRegistry
---@return CTTriggerExporter
function CTTriggerExporter.new(registry)
    local self = setmetatable({}, CTTriggerExporter._mt)
    self._registry = registry
    return self
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

function CTTriggerExporter:_getPath()
    local missionInfo = g_currentMission and g_currentMission.missionInfo
    local saveDir = missionInfo and missionInfo.savegameDirectory
    if not saveDir then return nil end
    return saveDir .. "/ctc_export.xml"
end

-- ---------------------------------------------------------------------------
-- Export
-- ---------------------------------------------------------------------------

---Write all triggers to ctc_export.xml.
---@return boolean ok
---@return string  message
function CTTriggerExporter:export()
    local path = self:_getPath()
    if not path then
        return false, "No active savegame."
    end

    local triggers = self._registry:getAll()
    local xmlFile = XMLFile.create("CTCExport", path, "CTCExport")
    if not xmlFile then
        Logger.warn("CTTriggerExporter: could not create " .. path)
        return false, "Could not write export file."
    end

    xmlFile:setInt("CTCExport#count", #triggers)

    for i, t in ipairs(triggers) do
        local base = "CTCExport.trigger(" .. (i - 1) .. ")"
        xmlFile:setString(base .. "#id",       t.id)
        xmlFile:setString(base .. "#name",     t.name)
        xmlFile:setString(base .. "#category", t.category)
        xmlFile:setString(base .. "#type",     t.type)
        xmlFile:setBool  (base .. "#enabled",  t.enabled)

        if t.config then
            for _, k in ipairs(CONFIG_KEYS) do
                local v = t.config[k]
                if v ~= nil then
                    local vt = type(v)
                    if vt == "number" then
                        xmlFile:setFloat(base .. ".config#" .. k, v)
                    elseif vt == "boolean" then
                        xmlFile:setBool(base .. ".config#" .. k, v)
                    elseif vt == "string" then
                        xmlFile:setString(base .. ".config#" .. k, v)
                    end
                end
            end
        end
    end

    xmlFile:save()
    xmlFile:delete()
    Logger.module("CTTriggerExporter", "Exported " .. #triggers .. " trigger(s) to " .. path)
    return true, #triggers .. " trigger(s) exported."
end

-- ---------------------------------------------------------------------------
-- Import
-- ---------------------------------------------------------------------------

---Read ctc_export.xml and add its triggers to the registry.
---Duplicates (same name+category+type) are skipped.
---@return boolean ok
---@return string  message
function CTTriggerExporter:import()
    local path = self:_getPath()
    if not path then
        return false, "No active savegame."
    end

    local xmlFile = XMLFile.loadIfExists("CTCExport", path)
    if not xmlFile then
        return false, "No export file found in savegame folder."
    end

    local count   = xmlFile:getInt("CTCExport#count", 0)
    local added   = 0
    local skipped = 0

    for i = 0, count - 1 do
        local base     = "CTCExport.trigger(" .. i .. ")"
        local name     = xmlFile:getString(base .. "#name",     "Imported Trigger")
        local category = xmlFile:getString(base .. "#category", "NOTIFICATION")
        local ttype    = xmlFile:getString(base .. "#type",     "INFO")
        local enabled  = xmlFile:getBool  (base .. "#enabled",  true)

        local config = {}
        for _, k in ipairs(CONFIG_KEYS) do
            -- Try float first; getString returns the raw string so we can coerce
            local strVal = xmlFile:getString(base .. ".config#" .. k, nil)
            if strVal ~= nil then
                local n = tonumber(strVal)
                if n then
                    config[k] = n
                elseif strVal == "true" then
                    config[k] = true
                elseif strVal == "false" then
                    config[k] = false
                else
                    config[k] = strVal
                end
            end
        end

        local result = self._registry:add({
            name     = name,
            category = category,
            type     = ttype,
            enabled  = enabled,
            config   = config,
        })

        if result then
            added = added + 1
        else
            skipped = skipped + 1  -- registry full or add() failed
        end
    end

    xmlFile:delete()
    Logger.module("CTTriggerExporter", "Import: " .. added .. " added, " .. skipped .. " skipped")
    return true, added .. " imported, " .. skipped .. " skipped."
end
