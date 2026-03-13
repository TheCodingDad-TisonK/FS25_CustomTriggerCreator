-- =========================================================
-- CTMarkerManager.lua — FS25_CustomTriggerCreator
-- Manages 3D floating world markers for triggers.
-- Uses shared FS25 i3d assets loaded async via g_i3DManager.
--
-- config.markerType controls which marker is spawned:
--   "NONE"  — no 3D marker
--   "SHOP"  — markerIconShopping.i3d (shopping bag, default)
--
-- Same approach as FS25_WorkplaceTriggers.
-- =========================================================

CTMarkerManager = {}
CTMarkerManager._mt = { __index = CTMarkerManager }

-- Maps markerType string → shared i3d asset path
CTMarkerManager.MARKER_I3D = {
    SHOP = "$data/shared/assets/marker/markerIconShopping.i3d",
}

CTMarkerManager.Y_OFFSET = 0.2   -- metres above trigger position

---@return CTMarkerManager
function CTMarkerManager.new()
    local self = setmetatable({}, CTMarkerManager._mt)
    -- id -> { rootNode, i3dNode, filename, loaded }
    self._markers = {}
    return self
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---Spawn a 3D marker for a trigger if its markerType requires one.
---@param record table  Trigger record with config.worldX/Y/Z and config.markerType
function CTMarkerManager:spawnMarker(record)
    if not record then return end
    local id  = record.id
    local cfg = record.config

    if not cfg or not cfg.worldX or not cfg.worldZ then return end

    local markerType = cfg.markerType or "NONE"
    if markerType == "NONE" or markerType == "" then return end

    -- Already spawned
    if self._markers[id] then return end

    local rawPath = CTMarkerManager.MARKER_I3D[markerType]
    if not rawPath then
        Logger.warn("CTMarkerManager: unknown markerType '" .. markerType .. "' for " .. id)
        return
    end

    -- Create an empty transform group to anchor the i3d
    local rootNode = createTransformGroup("ctc_marker_" .. id)
    if not rootNode or rootNode == 0 then
        Logger.warn("CTMarkerManager: createTransformGroup failed for " .. id)
        return
    end

    link(getRootNode(), rootNode)
    setWorldTranslation(rootNode,
        cfg.worldX,
        (cfg.worldY or 0) + CTMarkerManager.Y_OFFSET,
        cfg.worldZ)

    local resolvedPath = Utils.getFilename(rawPath, "")

    self._markers[id] = {
        rootNode = rootNode,
        i3dNode  = nil,
        filename = resolvedPath,
        loaded   = false,
    }

    g_i3DManager:loadSharedI3DFileAsync(
        resolvedPath, false, false,
        CTMarkerManager._onMarkerLoaded, self,
        { id = id }
    )

    Logger.debug("CTMarkerManager: queued " .. markerType .. " marker for " .. id)
end

---Remove a 3D marker by trigger ID.
---@param id string
function CTMarkerManager:removeMarker(id)
    local marker = self._markers[id]
    if not marker then return end

    -- Release shared i3d reference
    if marker.filename and marker.filename ~= "" then
        pcall(function()
            g_i3DManager:releaseSharedI3DFile(marker.filename, false)
        end)
    end

    -- delete() removes rootNode and all children (including linked i3dNode)
    if marker.rootNode and marker.rootNode ~= 0 then
        pcall(function() delete(marker.rootNode) end)
    end

    self._markers[id] = nil
    Logger.debug("CTMarkerManager: removed marker for " .. tostring(id))
end

---Rebuild markers to match the current registry state.
---Call after trigger create, delete, or savegame load.
---@param registry TriggerRegistry
function CTMarkerManager:refreshFromRegistry(registry)
    if not registry then return end
    local all      = registry:getAll()
    local activeIds = {}

    for _, t in ipairs(all) do
        activeIds[t.id] = true
        if not self._markers[t.id] then
            self:spawnMarker(t)
        end
    end

    -- Remove markers for deleted triggers
    for id, _ in pairs(self._markers) do
        if not activeIds[id] then
            self:removeMarker(id)
        end
    end
end

---Clean up all markers on mod unload.
function CTMarkerManager:delete()
    for id, _ in pairs(self._markers) do
        self:removeMarker(id)
    end
    self._markers = {}
    Logger.module("CTMarkerManager", "Cleaned up")
end

-- ---------------------------------------------------------------------------
-- Internal
-- ---------------------------------------------------------------------------

---Async callback from g_i3DManager:loadSharedI3DFileAsync.
---@param i3dNode     number  Loaded root node (0 on failure)
---@param failedReason string|nil
---@param args        table   { id = triggerId }
function CTMarkerManager:_onMarkerLoaded(i3dNode, failedReason, args)
    local id = args and args.id
    if not id then return end

    local marker = self._markers[id]
    if not marker then
        -- Trigger deleted before load completed — orphan node cleanup
        if i3dNode and i3dNode ~= 0 then
            pcall(function() delete(i3dNode) end)
        end
        return
    end

    if not i3dNode or i3dNode == 0 then
        Logger.warn("CTMarkerManager: i3d load failed for " .. id
            .. ": " .. tostring(failedReason))
        return
    end

    link(marker.rootNode, i3dNode)
    marker.i3dNode = i3dNode
    marker.loaded  = true
    Logger.debug("CTMarkerManager: marker ready for " .. id)
end
