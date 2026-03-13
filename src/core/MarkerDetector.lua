-- =========================================================
-- MarkerDetector.lua — FS25_CustomTriggerCreator
-- Detects when the local player is near a base-game marker
-- (sell points, shops, garages, silos, etc.).
--
-- Uses distance-squared checks — never math.sqrt in update().
-- Runs on every update() tick; skips when player unavailable.
-- =========================================================

MarkerDetector = {}
MarkerDetector._mt = { __index = MarkerDetector }

-- How many frames to skip between full scans (performance)
local SCAN_INTERVAL = 10

-- Marker type identifiers
MarkerDetector.TYPE = {
    SELL_POINT  = "SELL_POINT",
    SHOP        = "SHOP",
    SILO        = "SILO",
    UNKNOWN     = "UNKNOWN",
}

---Create a new MarkerDetector.
---@param settings CTSettings
---@return MarkerDetector
function MarkerDetector.new(settings)
    local self = setmetatable({}, MarkerDetector._mt)
    self.settings        = settings
    self.nearbyMarker    = nil      -- currently nearest marker within radius, or nil
    self.nearbyType      = nil      -- MarkerDetector.TYPE value
    self.nearbyDist      = nil      -- distance to nearest marker (metres)
    self._frameCounter   = 0
    self._markers        = {}       -- cached list of {node, type, label}
    self._cacheValid     = false
    return self
end

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

---Get the local player world position. Returns x, y, z or nil.
local function getPlayerPosition()
    -- Prefer g_localPlayer
    if g_localPlayer then
        local px, py, pz = getWorldTranslation(g_localPlayer.rootNode)
        if px then return px, py, pz end
    end

    -- Fallback: mission player
    local mission = g_currentMission
    if mission and mission.player and mission.player.rootNode then
        local px, py, pz = getWorldTranslation(mission.player.rootNode)
        if px then return px, py, pz end
    end

    -- Fallback: controlled vehicle
    if mission and mission.controlledVehicle then
        local vx, vy, vz = getWorldTranslation(mission.controlledVehicle.rootNode)
        if vx then return vx, vy, vz end
    end

    return nil
end

---Build the flat list of scannable markers from live game state.
---Called once after mission load and whenever the cache is invalidated.
function MarkerDetector:_buildMarkerCache()
    self._markers = {}
    local mission = g_currentMission
    if not mission then return end

    -- Sell points
    if mission.sellPoints then
        for _, sp in ipairs(mission.sellPoints) do
            if sp.triggerId or sp.rootNode then
                local node = sp.triggerId or sp.rootNode
                local label = sp.fillTypeId and tostring(sp.fillTypeId) or "Sell Point"
                table.insert(self._markers, { node = node, type = MarkerDetector.TYPE.SELL_POINT, label = label })
            end
        end
    end

    -- Shop (ShopController root node)
    if mission.shopController and mission.shopController.shopNode then
        table.insert(self._markers, {
            node  = mission.shopController.shopNode,
            type  = MarkerDetector.TYPE.SHOP,
            label = "Shop",
        })
    end

    -- Silos — iterate placeables looking for storage triggers
    if mission.storageSystem and mission.storageSystem.storages then
        for _, storage in ipairs(mission.storageSystem.storages) do
            if storage.node then
                table.insert(self._markers, {
                    node  = storage.node,
                    type  = MarkerDetector.TYPE.SILO,
                    label = "Storage",
                })
            end
        end
    end

    self._cacheValid = true
    local L = Logger or _G["Logger"]
    if L then
        L.module("MarkerDetector", "Marker cache built: " .. #self._markers .. " markers")
    end
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---Initialize after mission load.
function MarkerDetector:initialize()
    self._cacheValid = false
    self._frameCounter = 0
    Logger.module("MarkerDetector", "Initialized")
end

---Invalidate the marker cache (call when placeables change, etc.).
function MarkerDetector:invalidateCache()
    self._cacheValid = false
end

---Per-frame update. Call from FSBaseMission.update.
---@param dt number  Delta time in ms (not used — kept for hook signature compatibility)
function MarkerDetector:update(dt)
    self._frameCounter = self._frameCounter + 1
    if self._frameCounter < SCAN_INTERVAL then return end
    self._frameCounter = 0

    -- Rebuild cache lazily
    if not self._cacheValid then
        self:_buildMarkerCache()
    end

    local px, py, pz = getPlayerPosition()
    if not px then
        self.nearbyMarker = nil
        self.nearbyType   = nil
        self.nearbyDist   = nil
        return
    end

    local radiusSq = self.settings:getDetectionRadiusSq()
    local bestDist  = math.huge
    local bestMarker = nil
    local bestType   = nil

    for _, entry in ipairs(self._markers) do
        if entry.node then
            local mx, my, mz = getWorldTranslation(entry.node)
            if mx then
                local dx = px - mx
                local dy = py - my
                local dz = pz - mz
                local distSq = dx * dx + dy * dy + dz * dz
                if distSq <= radiusSq and distSq < bestDist then
                    bestDist   = distSq
                    bestMarker = entry
                    bestType   = entry.type
                end
            end
        end
    end

    -- Update state (avoid redundant reassignment when nothing changed)
    self.nearbyMarker = bestMarker
    self.nearbyType   = bestType
    self.nearbyDist   = bestMarker and math.sqrt(bestDist) or nil
end

---Returns true when the player is within range of a base-game marker.
---@return boolean
function MarkerDetector:isNearMarker()
    return self.nearbyMarker ~= nil
end

---Returns a short label for the currently nearby marker, or nil.
---@return string|nil
function MarkerDetector:getNearbyLabel()
    if self.nearbyMarker then
        return self.nearbyMarker.label
    end
    return nil
end

---Clean up.
function MarkerDetector:delete()
    self._markers    = {}
    self._cacheValid = false
    self.nearbyMarker = nil
    Logger.module("MarkerDetector", "Cleaned up")
end
