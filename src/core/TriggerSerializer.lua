-- =========================================================
-- TriggerSerializer.lua — FS25_CustomTriggerCreator
-- Persists TriggerRegistry to / from the mod's XML save file.
--
-- XML format (inside ctc_data.xml):
--   <CustomTriggerCreator>
--     <settings ... />
--     <triggers nextSeq="5" count="2">
--       <trigger id="ctc_0001" name="..." category="ECONOMY" type="PAY_FEE" enabled="true" createdAt="0">
--         <config worldX="100.5" worldZ="200.3" amount="50" cooldownSec="30" .../>
--       </trigger>
--       ...
--     </triggers>
--   </CustomTriggerCreator>
-- =========================================================

TriggerSerializer = {}
TriggerSerializer._mt = { __index = TriggerSerializer }

local TRIGGERS_PATH = "CustomTriggerCreator.triggers"
local TRIGGER_KEY   = "CustomTriggerCreator.triggers.trigger"

-- ---------------------------------------------------------------------------
-- Config field schema — every storable config key with its XML type.
-- Add new fields here as trigger types grow.
-- ---------------------------------------------------------------------------
local CONFIG_SCHEMA = {
    -- World position (captured at creation time)
    { key = "worldX",             xtype = "float"  },
    { key = "worldY",             xtype = "float"  },
    { key = "worldZ",             xtype = "float"  },
    -- Economy
    { key = "amount",             xtype = "int"    },
    { key = "quantity",           xtype = "int"    },
    { key = "fillType",           xtype = "string" },
    { key = "playerReceivesMoney",xtype = "bool"   },
    -- Interaction / Notification
    { key = "message",            xtype = "string" },
    { key = "body",               xtype = "string" },
    { key = "itemName",           xtype = "string" },
    { key = "eventName",          xtype = "string" },
    { key = "duration",           xtype = "float"  },
    -- Conditional
    { key = "timeFrom",           xtype = "int"    },
    { key = "timeTo",             xtype = "int"    },
    { key = "minMoney",           xtype = "int"    },
    { key = "probability",        xtype = "float"  },
    { key = "failMessage",        xtype = "string" },
    -- Chained
    { key = "stepMessage",        xtype = "string" },
    { key = "confirmMessage",     xtype = "string" },
    { key = "step2Message",       xtype = "string" },
    { key = "step2Amount",        xtype = "int"    },
    { key = "step3Message",       xtype = "string" },
    { key = "step3Confirm",       xtype = "string" },
    { key = "branchPrompt",       xtype = "string" },
    { key = "yesMessage",         xtype = "string" },
    { key = "yesAmount",          xtype = "int"    },
    { key = "noMessage",          xtype = "string" },
    { key = "noAmount",           xtype = "int"    },
    { key = "timerSec",           xtype = "int"    },
    -- Notification title (explicit key)
    { key = "title",              xtype = "string" },
    -- GIVE_ITEM
    { key = "itemValue",          xtype = "int"    },
    -- ANIMATION
    { key = "animName",           xtype = "string" },
    { key = "animNodeId",         xtype = "int"    },
    { key = "animSpeed",          xtype = "float"  },
    -- BARTER
    { key = "barterCost",         xtype = "int"    },
    { key = "barterOffer",        xtype = "string" },
    { key = "barterReceive",      xtype = "string" },
    -- ITEM_CHECK
    { key = "itemQty",            xtype = "int"    },
    -- CUSTOM_SCRIPT
    { key = "callbackKey",        xtype = "string" },
    { key = "eventKey",           xtype = "string" },
    { key = "delaySec",           xtype = "int"    },
    { key = "conditionKey",       xtype = "string" },
    -- 3D marker
    { key = "markerType",         xtype = "string" },
    -- Advanced (all types)
    { key = "cooldownSec",        xtype = "int"    },
    { key = "repeatLimit",        xtype = "int"    },
    { key = "requireConfirm",     xtype = "bool"   },
    { key = "conditionType",      xtype = "string" },
    { key = "actionType",         xtype = "string" },
}

---Create a new TriggerSerializer.
---@param registry TriggerRegistry
---@return TriggerSerializer
function TriggerSerializer.new(registry)
    local self = setmetatable({}, TriggerSerializer._mt)
    self.registry = registry
    return self
end

-- ---------------------------------------------------------------------------
-- Save
-- ---------------------------------------------------------------------------

---Save all triggers to an open XMLFile handle.
---@param xmlFile table  FS25 XMLFile handle (from XMLFile.create)
function TriggerSerializer:save(xmlFile)
    if not xmlFile or not self.registry then return end

    xmlFile:setInt(TRIGGERS_PATH .. "#nextSeq", self.registry._nextSeq)
    xmlFile:setInt(TRIGGERS_PATH .. "#count",   self.registry:count())

    local triggers = self.registry:getAll()
    for i, t in ipairs(triggers) do
        local path = TRIGGER_KEY .. "(" .. (i - 1) .. ")"
        xmlFile:setString(path .. "#id",       t.id)
        xmlFile:setString(path .. "#name",     t.name)
        xmlFile:setString(path .. "#category", t.category)
        xmlFile:setString(path .. "#type",     t.type)
        xmlFile:setBool(path .. "#enabled",    t.enabled)
        xmlFile:setFloat(path .. "#createdAt", t.createdAt)

        -- Save all config fields
        local cfg     = t.config or {}
        local cfgPath = path .. ".config"
        for _, field in ipairs(CONFIG_SCHEMA) do
            local v = cfg[field.key]
            if v ~= nil then
                local fp = cfgPath .. "#" .. field.key
                if field.xtype == "float" then
                    xmlFile:setFloat(fp, v)
                elseif field.xtype == "int" then
                    xmlFile:setInt(fp, v)
                elseif field.xtype == "string" then
                    xmlFile:setString(fp, v)   -- save empty strings too; nil is already guarded above
                elseif field.xtype == "bool" then
                    xmlFile:setBool(fp, v)
                end
            end
        end
    end

    Logger.module("TriggerSerializer", "Saved " .. #triggers .. " trigger(s)")
end

-- ---------------------------------------------------------------------------
-- Load
-- ---------------------------------------------------------------------------

---Load all triggers from an open XMLFile handle.
---@param xmlFile table  FS25 XMLFile handle (from XMLFile.loadIfExists)
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
        local id   = xmlFile:getString(path .. "#id")
        if id then
            -- Load all config fields
            local cfg     = {}
            local cfgPath = path .. ".config"
            for _, field in ipairs(CONFIG_SCHEMA) do
                local fp = cfgPath .. "#" .. field.key
                local v
                if field.xtype == "float" then
                    v = xmlFile:getFloat(fp)
                elseif field.xtype == "int" then
                    v = xmlFile:getInt(fp)
                elseif field.xtype == "string" then
                    v = xmlFile:getString(fp)
                elseif field.xtype == "bool" then
                    v = xmlFile:getBool(fp)
                end
                if v ~= nil then cfg[field.key] = v end
            end

            -- Apply safe defaults for fields that must never be nil at runtime
            cfg.amount             = cfg.amount          or 0
            cfg.cooldownSec        = cfg.cooldownSec     or 0
            cfg.repeatLimit        = cfg.repeatLimit     or 0
            cfg.requireConfirm     = cfg.requireConfirm  == true
            cfg.quantity           = cfg.quantity        or 1
            cfg.timeFrom           = cfg.timeFrom        or 0
            cfg.timeTo             = cfg.timeTo          or 23
            cfg.minMoney           = cfg.minMoney        or 0
            cfg.probability        = cfg.probability     or 0.5
            cfg.message            = cfg.message         or ""
            cfg.body               = cfg.body            or ""
            cfg.itemName           = cfg.itemName        or ""
            cfg.eventName          = cfg.eventName       or ""
            cfg.fillType           = cfg.fillType        or ""
            cfg.stepMessage        = cfg.stepMessage     or ""
            cfg.step2Message       = cfg.step2Message    or ""
            cfg.step2Amount        = cfg.step2Amount     or 0
            cfg.step3Message       = cfg.step3Message    or ""
            cfg.timerSec           = cfg.timerSec        or 10
            if cfg.playerReceivesMoney == nil then
                cfg.playerReceivesMoney = true
            end
            cfg.itemValue     = cfg.itemValue     or 0
            cfg.itemQty       = cfg.itemQty       or 1
            cfg.barterCost    = cfg.barterCost    or 0
            cfg.barterOffer   = cfg.barterOffer   or ""
            cfg.barterReceive = cfg.barterReceive or ""
            cfg.callbackKey   = cfg.callbackKey   or ""
            cfg.eventKey      = cfg.eventKey      or ""
            cfg.delaySec      = cfg.delaySec      or 5
            cfg.conditionKey  = cfg.conditionKey  or ""
            cfg.animName      = cfg.animName      or ""
            cfg.animSpeed     = cfg.animSpeed      or 1.0
            cfg.markerType    = cfg.markerType    or "NONE"

            local trigger = {
                id        = id,
                name      = xmlFile:getString(path .. "#name")     or "Trigger",
                category  = xmlFile:getString(path .. "#category") or "UNKNOWN",
                type      = xmlFile:getString(path .. "#type")     or "UNKNOWN",
                enabled   = xmlFile:getBool(path .. "#enabled")    ~= false,
                config    = cfg,
                createdAt = xmlFile:getFloat(path .. "#createdAt") or 0,
            }
            table.insert(self.registry._triggers, trigger)
            self.registry._byId[trigger.id] = trigger
        end
    end

    Logger.module("TriggerSerializer", "Loaded " .. self.registry:count() .. " trigger(s)")
end
