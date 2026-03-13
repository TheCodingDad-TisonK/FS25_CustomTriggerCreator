-- =========================================================
-- TriggerRegistry.lua — FS25_CustomTriggerCreator
-- In-memory store for all player-created triggers.
-- Single source of truth at runtime.
-- =========================================================

TriggerRegistry = {}
TriggerRegistry._mt = { __index = TriggerRegistry }

-- Trigger data shape:
--   id        string  Unique identifier, e.g. "ctc_0001"
--   name      string  Display name
--   category  string  Category key (from CTCategoryDialog.CATEGORIES)
--   type      string  Type key within the category
--   enabled   bool
--   config    table   Type-specific configuration (Phase 3+)
--   createdAt number  g_currentMission.time snapshot at creation

---Create a new TriggerRegistry.
---@param settings CTSettings
---@return TriggerRegistry
function TriggerRegistry.new(settings)
    local self = setmetatable({}, TriggerRegistry._mt)
    self.settings  = settings
    self._triggers = {}    -- list ordered by insertion
    self._byId     = {}    -- id -> trigger (fast lookup)
    self._nextSeq  = 1     -- monotonic counter for ID generation
    return self
end

-- ---------------------------------------------------------------------------
-- ID generation
-- ---------------------------------------------------------------------------

function TriggerRegistry:_generateId()
    local id = string.format("ctc_%04d", self._nextSeq)
    self._nextSeq = self._nextSeq + 1
    return id
end

-- ---------------------------------------------------------------------------
-- CRUD
-- ---------------------------------------------------------------------------

---Add a new trigger. Enforces maxTriggersPerSave.
---@param data table  Partial trigger data (name, category, type, config)
---@return table|nil  The complete trigger record, or nil if rejected
function TriggerRegistry:add(data)
    local maxT = self.settings and self.settings.maxTriggersPerSave or 100
    if #self._triggers >= maxT then
        Logger.warn("TriggerRegistry: max trigger limit reached (" .. maxT .. ")")
        return nil
    end

    local trigger = {
        id        = self:_generateId(),
        name      = data.name or "Trigger",
        category  = data.category or "UNKNOWN",
        type      = data.type or "UNKNOWN",
        enabled   = data.enabled ~= false,   -- default true
        config    = data.config or {},
        createdAt = (g_currentMission and g_currentMission.time) or 0,
    }

    table.insert(self._triggers, trigger)
    self._byId[trigger.id] = trigger

    Logger.module("TriggerRegistry", "Added: " .. trigger.id .. " (" .. trigger.name .. ")")
    return trigger
end

---Remove a trigger by ID.
---@param id string
---@return boolean  true if found and removed
function TriggerRegistry:remove(id)
    if not self._byId[id] then return false end

    for i, t in ipairs(self._triggers) do
        if t.id == id then
            table.remove(self._triggers, i)
            break
        end
    end
    self._byId[id] = nil

    Logger.module("TriggerRegistry", "Removed: " .. id)
    return true
end

---Get a trigger by ID.
---@param id string
---@return table|nil
function TriggerRegistry:getById(id)
    return self._byId[id]
end

---Get all triggers (ordered list, read-only view).
---@return table[]
function TriggerRegistry:getAll()
    return self._triggers
end

---Get the number of registered triggers.
---@return number
function TriggerRegistry:count()
    return #self._triggers
end

---Toggle a trigger's enabled state.
---@param id string
---@return boolean|nil  New enabled state, or nil if not found
function TriggerRegistry:toggle(id)
    local t = self._byId[id]
    if not t then return nil end
    t.enabled = not t.enabled
    Logger.module("TriggerRegistry", "Toggled " .. id .. " → " .. tostring(t.enabled))
    return t.enabled
end

---Update a trigger's fields.
---@param id string
---@param updates table  Fields to update (name, enabled, config)
---@return boolean
function TriggerRegistry:update(id, updates)
    local t = self._byId[id]
    if not t then return false end
    if updates.name    ~= nil then t.name    = updates.name    end
    if updates.enabled ~= nil then t.enabled = updates.enabled end
    if updates.config  ~= nil then t.config  = updates.config  end
    Logger.module("TriggerRegistry", "Updated: " .. id)
    return true
end

---Clear all triggers (used on load before populating from XML).
function TriggerRegistry:clear()
    self._triggers = {}
    self._byId     = {}
    self._nextSeq  = 1
    Logger.module("TriggerRegistry", "Cleared")
end
