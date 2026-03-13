-- =========================================================
-- main.lua — FS25_CustomTriggerCreator
-- =========================================================
-- Mod entry point. Loads all modules in dependency order,
-- then hooks into FS25 lifecycle events.
-- =========================================================
-- Author: TisonK
-- =========================================================

local modDirectory = g_currentModDirectory
local modName      = g_currentModName
local modItem      = g_modManager:getModByName(modName)
local modVersion   = modItem and modItem.version or "0.0.0"

print("[CTC] Starting FS25_CustomTriggerCreator v" .. modVersion .. " ...")

if not modDirectory then
    print("[CTC] ERROR — could not resolve mod directory. Aborting load.")
    return
end

-- =========================================================
-- Utilities
-- =========================================================
source(modDirectory .. "src/utils/Logger.lua")

-- =========================================================
-- Settings
-- =========================================================
source(modDirectory .. "src/settings/CTSettings.lua")
source(modDirectory .. "src/settings/CTSettingsIntegration.lua")

-- =========================================================
-- Core systems
-- =========================================================
source(modDirectory .. "src/core/MarkerDetector.lua")
source(modDirectory .. "src/core/TriggerRegistry.lua")
source(modDirectory .. "src/core/TriggerSerializer.lua")
source(modDirectory .. "src/core/TriggerExecutor.lua")
source(modDirectory .. "src/core/CTTriggerExporter.lua")

-- =========================================================
-- Triggers
-- =========================================================
source(modDirectory .. "src/triggers/BaseTrigger.lua")
source(modDirectory .. "src/triggers/EconomyTrigger.lua")
source(modDirectory .. "src/triggers/InteractionTrigger.lua")
source(modDirectory .. "src/triggers/NotificationTrigger.lua")
source(modDirectory .. "src/triggers/ConditionalTrigger.lua")
source(modDirectory .. "src/triggers/ChainedTrigger.lua")

-- =========================================================
-- HUD
-- =========================================================
source(modDirectory .. "src/hud/CTNotificationHUD.lua")
source(modDirectory .. "src/hud/CTHotspotManager.lua")

-- =========================================================
-- GUI
-- =========================================================
source(modDirectory .. "src/gui/DialogLoader.lua")
source(modDirectory .. "src/gui/CTManagementDialog.lua")
source(modDirectory .. "src/gui/CTCategoryDialog.lua")
source(modDirectory .. "src/gui/CTBuilderDialog.lua")
source(modDirectory .. "src/gui/CTConfirmDialog.lua")

-- =========================================================
-- Coordinator (depends on everything above)
-- =========================================================
source(modDirectory .. "src/CustomTriggerCreator.lua")

print("[CTC] All modules loaded")

-- =========================================================
-- Module-level state
-- =========================================================
local ctcSystem = nil
local ctcOpenOriginalFunc = nil
local ctcOpenEventId = nil

local function isMissionValid(mission)
    return mission ~= nil and not mission.cancelLoading
end

-- =========================================================
-- F8 action callback
-- =========================================================
local function ctcOpenCallback(target, actionName, inputValue, callbackState, isAnalog)
    if not ctcSystem or not ctcSystem.initialized then return end
    if not ctcSystem.settings.enabled then return end
    ctcSystem:openCreator()
end

-- =========================================================
-- RVB input hook — registers CTC_OPEN action event
-- =========================================================
local function hookCTCInput()
    if not PlayerInputComponent or not PlayerInputComponent.registerActionEvents then
        Logger.warn("PlayerInputComponent.registerActionEvents not available")
        return
    end

    ctcOpenOriginalFunc = PlayerInputComponent.registerActionEvents

    PlayerInputComponent.registerActionEvents = function(inputComponent, ...)
        ctcOpenOriginalFunc(inputComponent, ...)

        if inputComponent.player ~= nil and inputComponent.player.isOwner then
            g_inputBinding:beginActionEventsModification(PlayerInputComponent.INPUT_CONTEXT_NAME)

            local actionId = InputAction.CTC_OPEN
            if actionId ~= nil then
                local success, eventId = g_inputBinding:registerActionEvent(
                    actionId,
                    ctcSystem,
                    ctcOpenCallback,
                    false,   -- triggerUp
                    true,    -- triggerDown
                    false,   -- triggerAlways
                    false,   -- startActive (MUST be false)
                    nil,     -- callbackState
                    true     -- disableConflictingBindings
                )
                if success and eventId ~= nil then
                    ctcOpenEventId = eventId
                    g_inputBinding:setActionEventActive(eventId, true)
                    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_NORMAL)
                    g_inputBinding:setActionEventText(eventId, "Open Trigger Creator")
                end
            end

            g_inputBinding:endActionEventsModification()
        end
    end
end

hookCTCInput()

-- =========================================================
-- Mission lifecycle hooks
-- =========================================================

local function onLoad(mission)
    if not isMissionValid(mission) then return end
    -- Re-anchor Logger in case FS25 reset the global environment between
    -- the initial source() pass and this lifecycle callback firing.
    -- Without this, 'Logger' can be nil here, causing:
    --   "attempt to index nil with 'info'"  (FS25 error log line 145)
    if Logger == nil then
        Logger = _G["Logger"]
    end
    if Logger == nil then
        print("[CTC] ERROR — Logger is nil in onLoad; skipping system creation")
        return
    end
    Logger.info("Creating CustomTriggerCreator system...")
    ctcSystem = CustomTriggerCreator.new(mission, modDirectory, modName)
    getfenv(0)["g_CTCSystem"] = ctcSystem
    Logger.info("System created")
end

local function onLoadFinished(mission, node)
    if not isMissionValid(mission) then return end
    if not ctcSystem then
        Logger.error("onLoadFinished — ctcSystem is nil, attempting late init")
        ctcSystem = CustomTriggerCreator.new(mission, modDirectory, modName)
        getfenv(0)["g_CTCSystem"] = ctcSystem
    end

    -- Register and eagerly load all dialogs while ZIP context is active
    DialogLoader.init(modDirectory)
    DialogLoader.register("CTManagementDialog", CTManagementDialog, "gui/CTManagementDialog.xml")
    DialogLoader.register("CTCategoryDialog",   CTCategoryDialog,   "gui/CTCategoryDialog.xml")
    DialogLoader.register("CTBuilderDialog",    CTBuilderDialog,    "gui/CTBuilderDialog.xml")
    DialogLoader.register("CTConfirmDialog",    CTConfirmDialog,    "gui/CTConfirmDialog.xml")

    DialogLoader.ensureLoaded("CTManagementDialog")
    DialogLoader.ensureLoaded("CTCategoryDialog")
    DialogLoader.ensureLoaded("CTBuilderDialog")
    DialogLoader.ensureLoaded("CTConfirmDialog")

    ctcSystem:onMissionLoaded()
end

local function onUpdate(mission, dt)
    if ctcSystem then ctcSystem:update(dt) end
end

local function onDraw(mission)
    if ctcSystem then ctcSystem:draw() end
end

local function onDelete(mission)
    DialogLoader.cleanup()
    if ctcSystem then
        ctcSystem:delete()
        ctcSystem = nil
        getfenv(0)["g_CTCSystem"] = nil
    end
end

-- FSCareerMissionInfo.saveToXMLFile is a method — first arg is missionInfo (self)
local function onSave(missionInfo)
    if not ctcSystem then return end
    local savePath = missionInfo and missionInfo.savegameDirectory
    if not savePath then return end

    local xmlPath = savePath .. "/ctc_data.xml"
    local xmlFile = XMLFile.create("CTCData", xmlPath, "CustomTriggerCreator")
    if xmlFile then
        ctcSystem:saveToXML(xmlFile)
        xmlFile:save()
        xmlFile:delete()
    end
end

local function onStartMission(mission)
    if not ctcSystem then return end
    local missionInfo = mission and mission.missionInfo
    if not missionInfo then return end
    local savePath = missionInfo.savegameDirectory
    if not savePath then return end

    local xmlPath = savePath .. "/ctc_data.xml"
    local xmlFile = XMLFile.loadIfExists("CTCData", xmlPath)
    if xmlFile then
        ctcSystem:loadFromXML(xmlFile)
        xmlFile:delete()
    end
end

-- =========================================================
-- Hook registration
-- =========================================================
Mission00.load                    = Utils.appendedFunction(Mission00.load,                    onLoad)
Mission00.loadMission00Finished   = Utils.appendedFunction(Mission00.loadMission00Finished,   onLoadFinished)
FSBaseMission.update              = Utils.appendedFunction(FSBaseMission.update,              onUpdate)
FSBaseMission.draw                = Utils.appendedFunction(FSBaseMission.draw,                onDraw)
FSBaseMission.delete              = Utils.appendedFunction(FSBaseMission.delete,              onDelete)
FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, onSave)
Mission00.onStartMission          = Utils.appendedFunction(Mission00.onStartMission,          onStartMission)

print("[CTC] Hooks registered — mod ready")
