-- =========================================================
-- CTHotspotManager.lua — FS25_CustomTriggerCreator
-- Manages map hotspot icons for player-created triggers.
--
-- Each trigger that has worldX/worldZ in its config gets a
-- map icon visible on the minimap and world map.
-- Uses PlaceableHotspot (has icons) with MapHotspot fallback.
-- =========================================================

CTHotspotManager = {}
CTHotspotManager._mt = { __index = CTHotspotManager }

function CTHotspotManager.new()
    local self = setmetatable({}, CTHotspotManager._mt)
    self._hotspots = {}  -- triggerId -> hotspot object
    return self
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---Add or replace a hotspot for a trigger.
---@param triggerId string
---@param name      string
---@param worldX    number
---@param worldZ    number
function CTHotspotManager:addHotspot(triggerId, name, worldX, worldZ)
    if not triggerId or not worldX or not worldZ then
        Logger.debug("CTHotspotManager: no position for " .. tostring(triggerId) .. " — skipping")
        return
    end

    -- Remove existing hotspot if any
    if self._hotspots[triggerId] then
        self:removeHotspot(triggerId)
    end

    local hotspot = self:_createHotspot(name or triggerId, worldX, worldZ)
    if not hotspot then
        Logger.warn("CTHotspotManager: failed to create hotspot for " .. tostring(triggerId))
        return
    end

    if g_currentMission then
        g_currentMission:addMapHotspot(hotspot)
    end

    self._hotspots[triggerId] = hotspot
    Logger.debug("CTHotspotManager: added hotspot '" .. tostring(name) .. "' at " .. worldX .. "," .. worldZ)
end

---Remove a hotspot by trigger ID.
---@param triggerId string
function CTHotspotManager:removeHotspot(triggerId)
    local hotspot = self._hotspots[triggerId]
    if not hotspot then return end

    if g_currentMission then
        g_currentMission:removeMapHotspot(hotspot)
    end

    if hotspot.delete then hotspot:delete() end
    self._hotspots[triggerId] = nil
    Logger.debug("CTHotspotManager: removed hotspot for " .. triggerId)
end

---Sync hotspots to match the current registry state.
---Triggers without worldX/worldZ in config are silently skipped.
---@param registry TriggerRegistry
function CTHotspotManager:refreshFromRegistry(registry)
    if not registry then return end
    local all = registry:getAll()

    -- Index active trigger IDs
    local activeIds = {}
    for _, t in ipairs(all) do
        activeIds[t.id] = true
        local x = t.config and t.config.worldX
        local z = t.config and t.config.worldZ
        if x and z then
            -- Only add if not already present (prevents flicker on refresh)
            if not self._hotspots[t.id] then
                self:addHotspot(t.id, t.name, x, z)
            end
        end
    end

    -- Remove stale hotspots for deleted triggers
    for id, _ in pairs(self._hotspots) do
        if not activeIds[id] then
            self:removeHotspot(id)
        end
    end
end

---Clean up all hotspots on mod unload.
function CTHotspotManager:delete()
    for id, _ in pairs(self._hotspots) do
        self:removeHotspot(id)
    end
    self._hotspots = {}
    Logger.module("CTHotspotManager", "Cleaned up")
end

-- ---------------------------------------------------------------------------
-- Internal
-- ---------------------------------------------------------------------------

---Create a map hotspot at the given world position.
---Tries PlaceableHotspot first (has shop-style icon), falls back
---to MapHotspot with CATEGORY_SHOP, then CATEGORY_USER.
---@param name   string
---@param worldX number
---@param worldZ number
---@return table|nil  hotspot object or nil on failure
function CTHotspotManager:_createHotspot(name, worldX, worldZ)
    -- Attempt 1: PlaceableHotspot (shop-style icon, preferred)
    if PlaceableHotspot then
        local ok, hotspot = pcall(function()
            local h = PlaceableHotspot.new()
            h:setWorldPosition(worldX, worldZ)
            if h.setName then h:setName(name) end
            return h
        end)
        if ok and hotspot then
            return hotspot
        end
        Logger.debug("CTHotspotManager: PlaceableHotspot failed, trying MapHotspot")
    end

    -- Attempt 2: MapHotspot with CATEGORY_SHOP (shop bag icon)
    if MapHotspot then
        local category = MapHotspot.CATEGORY_SHOP or MapHotspot.CATEGORY_USER
        local ok, hotspot = pcall(function()
            local h = MapHotspot.new(name, category)
            h:setWorldPosition(worldX, worldZ)
            return h
        end)
        if ok and hotspot then
            return hotspot
        end
    end

    return nil
end
