-- =========================================================
-- CTHotspotManager.lua — FS25_CustomTriggerCreator
-- Manages map hotspot icons for player-created triggers.
--
-- APPROACH: drawFields hook (NOT addMapHotspot / PlaceableHotspot).
--
-- PlaceableHotspot internally requires an i3d icon node to be valid
-- every draw frame.  When that node is nil (bad release, async load
-- still pending, etc.) the game crashes at PlaceableHotspot.lua:213
-- "attempt to index nil with 'width'" — every single frame, unrecoverable.
--
-- Instead we hook ingameMap.drawFields and render Overlay tiles directly,
-- bypassing PlaceableHotspot entirely.  Same pattern used by
-- FS25_WorkplaceTriggers, NPCFavor, AutoDrive, etc.
-- =========================================================

CTHotspotManager = {}
CTHotspotManager._mt = { __index = CTHotspotManager }

-- Icon dimensions (normalised screen units)
local ICON_W    = 0.018
local ICON_H    = 0.018
local TEXT_SIZE = 0.009
local LABEL_GAP = 0.003

-- Colour: shop/marker blue matching the vanilla shopping icon
local ICON_R, ICON_G, ICON_B, ICON_A = 0.22, 0.70, 0.94, 1.00
local TEXT_R, TEXT_G, TEXT_B, TEXT_A = 0.85, 0.95, 1.00, 0.95

function CTHotspotManager.new()
    local self = setmetatable({}, CTHotspotManager._mt)
    -- triggerId -> { worldX, worldZ, name, overlay }
    self._hotspots      = {}
    self._hookInstalled = false
    return self
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---Add or replace a map icon for a trigger.
function CTHotspotManager:addHotspot(triggerId, name, worldX, worldZ)
    if not triggerId or not worldX or not worldZ then
        Logger.debug("CTHotspotManager: no position for "
            .. tostring(triggerId) .. " — skipping")
        return
    end

    -- Remove existing entry if any
    if self._hotspots[triggerId] then
        self:removeHotspot(triggerId)
    end

    self._hotspots[triggerId] = {
        worldX  = worldX,
        worldZ  = worldZ,
        name    = name or triggerId,
        overlay = nil,         -- created lazily in _drawAll
    }

    -- Ensure the draw hook is running
    self:_ensureHook()

    Logger.debug("CTHotspotManager: added hotspot '"
        .. tostring(name) .. "' at " .. worldX .. "," .. worldZ)
end

---Remove a map icon by trigger ID.
function CTHotspotManager:removeHotspot(triggerId)
    local entry = self._hotspots[triggerId]
    if not entry then return end

    -- Release overlay if created
    if entry.overlay then
        pcall(function() entry.overlay:delete() end)
        entry.overlay = nil
    end

    self._hotspots[triggerId] = nil
    Logger.debug("CTHotspotManager: removed hotspot for " .. triggerId)
end

---Sync icons to match the current registry state.
function CTHotspotManager:refreshFromRegistry(registry)
    if not registry then return end
    local all = registry:getAll()

    local activeIds = {}
    for _, t in ipairs(all) do
        activeIds[t.id] = true
        local x = t.config and t.config.worldX
        local z = t.config and t.config.worldZ
        if x and z then
            if not self._hotspots[t.id] then
                self:addHotspot(t.id, t.name, x, z)
            end
        end
    end

    -- Remove stale icons for deleted triggers
    for id, _ in pairs(self._hotspots) do
        if not activeIds[id] then
            self:removeHotspot(id)
        end
    end
end

---Clean up all icons on mod unload.
function CTHotspotManager:delete()
    for id, _ in pairs(self._hotspots) do
        self:removeHotspot(id)
    end
    self._hotspots      = {}
    self._hookInstalled = false
    Logger.module("CTHotspotManager", "Cleaned up")
end

-- ---------------------------------------------------------------------------
-- Internal — drawFields hook
-- ---------------------------------------------------------------------------

---Install the hook once after the map is available.
function CTHotspotManager:_ensureHook()
    if self._hookInstalled then return end

    local ingameMap = g_currentMission
        and g_currentMission.hud
        and g_currentMission.hud.ingameMap

    if not ingameMap then
        -- Map not ready yet — hook will be re-attempted on next addHotspot call
        Logger.debug("CTHotspotManager: ingameMap not ready, deferring hook")
        return
    end

    local mgr = self

    ingameMap.drawFields = Utils.appendedFunction(
        ingameMap.drawFields,
        function(map)
            pcall(function() mgr:_drawAll(map) end)
        end
    )

    self._hookInstalled = true
    Logger.debug("CTHotspotManager: map draw hook installed")
end

---Draw all hotspot icons onto the map each frame.
function CTHotspotManager:_drawAll(map)
    if not map or not map.layout then return end

    for _, entry in pairs(self._hotspots) do
        -- World → normalised map position (standard community formula)
        local nx = (entry.worldX + map.worldCenterOffsetX) / map.worldSizeX
                   * map.mapExtensionScaleFactor + map.mapExtensionOffsetX
        local nz = (entry.worldZ + map.worldCenterOffsetZ) / map.worldSizeZ
                   * map.mapExtensionScaleFactor + map.mapExtensionOffsetZ

        local sx, sy, _, visible =
            map.layout:getMapObjectPosition(nx, nz, ICON_W, ICON_H, 0, true)

        if visible then
            -- Lazy-create a plain white overlay (no i3d, no external asset)
            if not entry.overlay then
                local ok, ov = pcall(Overlay.new, GuiUtils.WHITE_ICON,
                    0, 0, ICON_W, ICON_H)
                if ok and ov then
                    entry.overlay = ov
                end
            end

            if entry.overlay then
                entry.overlay:setPosition(sx, sy)
                entry.overlay:setDimension(ICON_W, ICON_H)
                entry.overlay:setColor(ICON_R, ICON_G, ICON_B, ICON_A)
                entry.overlay:render()
            else
                -- Absolute fallback: coloured rect with no external assets
                setOverlayColor(0, ICON_R, ICON_G, ICON_B, ICON_A * 0.85)
                drawFilledRect(sx, sy, ICON_W, ICON_H)
            end

            -- Name label, only when zoomed in enough
            if entry.name and entry.name ~= ""
            and map.layout.scale and map.layout.scale > 0.5 then
                setTextAlignment(RenderText.ALIGN_CENTER)
                setTextBold(false)
                setTextColor(TEXT_R, TEXT_G, TEXT_B, TEXT_A)
                renderText(
                    sx + ICON_W * 0.5,
                    sy + ICON_H + LABEL_GAP,
                    TEXT_SIZE,
                    entry.name)
                setTextColor(1, 1, 1, 1)
                setTextAlignment(RenderText.ALIGN_LEFT)
            end
        end
    end
end
