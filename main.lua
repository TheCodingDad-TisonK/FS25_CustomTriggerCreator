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
-- Phase 1: Utilities
-- =========================================================
source(modDirectory .. "src/utils/Logger.lua")

-- =========================================================
-- Phase 2: Settings
-- =========================================================
source(modDirectory .. "src/settings/CTSettings.lua")
source(modDirectory .. "src/settings/CTSettingsIntegration.lua")

-- =========================================================
-- Phase 3: Core systems
-- =========================================================
source(modDirectory .. "src/core/MarkerDetector.lua")

-- =========================================================
-- Phase 4: Coordinator (depends on everything above)
-- =========================================================
source(modDirectory .. "src/CustomTriggerCreator.lua")

print("[CTC] All modules loaded")

-- =========================================================
-- Module-level state
-- =========================================================
local ctcSystem = nil

local function isMissionValid(mission)
    return mission ~= nil and not mission.cancelLoading
end

-- =========================================================
-- Mission lifecycle hooks
-- =========================================================

local function onLoad(mission)
    if not isMissionValid(mission) then return end

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
    ctcSystem:onMissionLoaded()
end

local function onUpdate(mission, dt)
    if ctcSystem then
        ctcSystem:update(dt)
    end
end

local function onDraw(mission)
    if ctcSystem then
        ctcSystem:draw()
    end
end

local function onDelete(mission)
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
Mission00.load                          = Utils.appendedFunction(Mission00.load,                          onLoad)
Mission00.loadMission00Finished         = Utils.appendedFunction(Mission00.loadMission00Finished,         onLoadFinished)
FSBaseMission.update                    = Utils.appendedFunction(FSBaseMission.update,                    onUpdate)
FSBaseMission.draw                      = Utils.appendedFunction(FSBaseMission.draw,                     onDraw)
FSBaseMission.delete                    = Utils.appendedFunction(FSBaseMission.delete,                   onDelete)
FSCareerMissionInfo.saveToXMLFile       = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile,      onSave)
Mission00.onStartMission                = Utils.appendedFunction(Mission00.onStartMission,               onStartMission)

print("[CTC] Hooks registered — mod ready")
