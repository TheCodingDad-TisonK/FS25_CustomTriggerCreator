-- =========================================================
-- CTWorldManager.lua — FS25_CustomTriggerCreator
-- Manages world-space proximity zones for player-created
-- triggers that have a world position stored in config.
--
-- Each positioned trigger gets a CTTriggerActivatable that
-- is added to / removed from FS25's ActivatableObjectsSystem
-- as the player enters / leaves the interaction radius.
-- This is what shows "Press [E] to ..." and handles E-key.
-- =========================================================

CTWorldManager = {}
CTWorldManager._mt = { __index = CTWorldManager }

CTWorldManager.INTERACT_RADIUS    = 3.0   -- metres
CTWorldManager.INTERACT_RADIUS_SQ = 9.0   -- radius^2, avoids sqrt in update

---Create a new CTWorldManager.
---@return CTWorldManager
function CTWorldManager.new()
    local self = setmetatable({}, CTWorldManager._mt)
    -- id -> { activatable: CTTriggerActivatable, inRange: bool, record: table }
    self._zones = {}
    return self
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---Rebuild zones to match the current registry state.
---Call after trigger create, delete, or savegame load.
---@param registry TriggerRegistry
function CTWorldManager:refresh(registry)
    if not registry then return end
    local all    = registry:getAll()
    local active = {}

    for _, t in ipairs(all) do
        active[t.id] = true
        local cfg = t.config
        if cfg and cfg.worldX and cfg.worldZ then
            local zone = self._zones[t.id]
            if not zone then
                -- New positioned trigger
                self._zones[t.id] = {
                    activatable = CTTriggerActivatable.new(t),
                    inRange     = false,
                    record      = t,
                }
                Logger.debug("CTWorldManager: zone registered for " .. t.id)
            else
                -- Trigger updated (toggle/rename) — refresh live references
                zone.record               = t
                zone.activatable.record   = t
                zone.activatable.activateText = t.name
            end
        end
    end

    -- Remove zones for deleted triggers
    for id, zone in pairs(self._zones) do
        if not active[id] then
            self:_removeZone(id, zone)
        end
    end
end

---Per-frame proximity check.  Adds/removes activatables as player moves.
---@param dt number  Delta time in ms (FS25 convention)
function CTWorldManager:update(dt)
    if not g_localPlayer or not g_localPlayer.rootNode then return end
    local activSys = g_currentMission and g_currentMission.activatableObjectsSystem
    if not activSys then return end

    local px, py, pz = getWorldTranslation(g_localPlayer.rootNode)

    for id, zone in pairs(self._zones) do
        local cfg = zone.record and zone.record.config
        local wx  = cfg and cfg.worldX
        local wz  = cfg and cfg.worldZ
        if wx and wz then
            local wy    = cfg.worldY or 0
            local dx    = px - wx
            local dy    = py - wy
            local dz    = pz - wz
            local distSq = dx * dx + dy * dy + dz * dz
            local near  = distSq <= CTWorldManager.INTERACT_RADIUS_SQ

            if near ~= zone.inRange then
                zone.inRange = near
                if near then
                    activSys:addActivatable(zone.activatable)
                    Logger.debug("CTWorldManager: player entered zone " .. id)
                else
                    activSys:removeActivatable(zone.activatable)
                    Logger.debug("CTWorldManager: player left zone " .. id)
                end
            end
        end
    end
end

---Clean up all zones on mod unload.
function CTWorldManager:delete()
    local activSys = g_currentMission and g_currentMission.activatableObjectsSystem
    for id, zone in pairs(self._zones) do
        if zone.inRange and activSys then
            activSys:removeActivatable(zone.activatable)
        end
    end
    self._zones = {}
    Logger.module("CTWorldManager", "Cleaned up")
end

-- ---------------------------------------------------------------------------
-- Internal
-- ---------------------------------------------------------------------------

function CTWorldManager:_removeZone(id, zone)
    if zone.inRange then
        local activSys = g_currentMission and g_currentMission.activatableObjectsSystem
        if activSys then
            activSys:removeActivatable(zone.activatable)
        end
    end
    self._zones[id] = nil
    Logger.debug("CTWorldManager: zone removed for " .. tostring(id))
end
