-- =========================================================
-- CTHotspotManager.lua — FS25_CustomTriggerCreator
-- Manages map hotspot icons for player-created triggers.
--
-- Each trigger that has a world position (config.worldX/Z)
-- gets a map pin visible on the minimap and world map.
--
-- NOTE: Triggers currently have no world placement flow —
-- hotspots will appear once Phase 6 (world placement) is
-- implemented and triggers store worldX/worldZ in config.
-- Until then, refreshFromRegistry() is a no-op for all
-- triggers that lack position data.
-- =========================================================

CTHotspotManager = {}
CTHotspotManager._mt = { __index = CTHotspotManager }

function CTHotspotManager.new()
    local self = setmetatable({}, CTHotspotManager._mt)
    self._hotspots = {}  -- triggerId -> MapHotspot
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

    if not MapHotspot then
        Logger.warn("CTHotspotManager: MapHotspot API not available")
        return
    end

    local hotspot = MapHotspot.new(name or triggerId, MapHotspot.CATEGORY_USER)
    if not hotspot then
        Logger.warn("CTHotspotManager: MapHotspot.new() returned nil for " .. tostring(triggerId))
        return
    end

    hotspot:setWorldPosition(worldX, worldZ)

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
    hotspot:delete()
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
            self:addHotspot(t.id, t.name, x, z)
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
