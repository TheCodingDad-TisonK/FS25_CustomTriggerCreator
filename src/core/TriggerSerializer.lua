-- =========================================================
-- TriggerSerializer.lua — FS25_CustomTriggerCreator
-- Persists TriggerRegistry to / from the mod's XML save file.
--
-- XML format (inside ctc_data.xml):
--   <CustomTriggerCreator>
--     <settings ... />
--     <triggers nextSeq="5">
--       <trigger id="ctc_0001" name="My Trigger" category="ECONOMY"
--                type="BUY_SELL" enabled="true" createdAt="12345" />
--       ...
--     </triggers>
--   </CustomTriggerCreator>
-- =========================================================

TriggerSerializer = {}
TriggerSerializer._mt = { __index = TriggerSerializer }

local TRIGGERS_PATH = "CustomTriggerCreator.triggers"
local TRIGGER_KEY   = "CustomTriggerCreator.triggers.trigger"

---Create a new TriggerSerializer.
---@param registry TriggerRegistry
---@return TriggerSerializer
function TriggerSerializer.new(registry)
    local self = setmetatable({}, TriggerSerializer._mt)
    self.registry = registry
    return self
end

---Save all triggers to an open XMLFile handle.
---Called by CustomTriggerCreator:saveToXML().
---@param xmlFile table  FS25 XMLFile handle
function TriggerSerializer:save(xmlFile)
    if not xmlFile or not self.registry then return end

    xmlFile:setInt(TRIGGERS_PATH .. "#nextSeq", self.registry._nextSeq)
    xmlFile:setInt(TRIGGERS_PATH .. "#count",   self.registry:count())

    local triggers = self.registry:getAll()
    for i, t in ipairs(triggers) do
        local path = TRIGGER_KEY .. "(" .. (i - 1) .. ")"
        xmlFile:setString(path .. "#id",        t.id)
        xmlFile:setString(path .. "#name",      t.name)
        xmlFile:setString(path .. "#category",  t.category)
        xmlFile:setString(path .. "#type",      t.type)
        xmlFile:setBool(path .. "#enabled",     t.enabled)
        xmlFile:setFloat(path .. "#createdAt",  t.createdAt)
    end

    Logger.module("TriggerSerializer", "Saved " .. #triggers .. " trigger(s)")
end

---Load all triggers from an open XMLFile handle.
---Called by CustomTriggerCreator:loadFromXML().
---@param xmlFile table  FS25 XMLFile handle
function TriggerSerializer:load(xmlFile)
    if not xmlFile or not self.registry then return end

    self.registry:clear()

    local nextSeq = xmlFile:getInt(TRIGGERS_PATH .. "#nextSeq")
    if nextSeq and nextSeq > 1 then
        self.registry._nextSeq = nextSeq
    end

    local count = xmlFile:getInt(TRIGGERS_PATH .. "#count") or 0

    for i = 0, count - 1 do
        local path = TRIGGER_KEY .. "(" .. i .. ")"
        local id = xmlFile:getString(path .. "#id")
        if id then
            local trigger = {
                id        = id,
                name      = xmlFile:getString(path .. "#name")     or "Trigger",
                category  = xmlFile:getString(path .. "#category") or "UNKNOWN",
                type      = xmlFile:getString(path .. "#type")     or "UNKNOWN",
                enabled   = xmlFile:getBool(path .. "#enabled")    ~= false,
                config    = {},
                createdAt = xmlFile:getFloat(path .. "#createdAt") or 0,
            }
            table.insert(self.registry._triggers, trigger)
            self.registry._byId[trigger.id] = trigger
        end
    end

    Logger.module("TriggerSerializer", "Loaded " .. self.registry:count() .. " trigger(s)")
end
