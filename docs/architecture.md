# Architecture

This document covers the module layout, lifecycle, and data flow for contributors.

---

## Entry point

`modDesc.xml` declares a single source file:

```xml
<sourceFile filename="main.lua" />
```

`main.lua` sources all modules in dependency order, then registers FS25 lifecycle hooks.

---

## Load order

```
1. src/utils/Logger.lua
2. src/settings/CTSettings.lua
3. src/settings/CTSettingsIntegration.lua
4. src/core/MarkerDetector.lua
5. src/core/TriggerRegistry.lua
6. src/core/TriggerSerializer.lua
7. src/core/TriggerExecutor.lua
8. src/core/CTTriggerExporter.lua
9. src/core/CTTriggerActivatable.lua
10. src/core/CTWorldManager.lua
11. src/core/CTMarkerManager.lua
12. src/triggers/BaseTrigger.lua
13. src/triggers/EconomyTrigger.lua
14. src/triggers/InteractionTrigger.lua
15. src/triggers/NotificationTrigger.lua
16. src/triggers/ConditionalTrigger.lua
17. src/triggers/ChainedTrigger.lua
18. src/triggers/CustomScriptTrigger.lua
19. src/hud/CTNotificationHUD.lua
20. src/hud/CTHotspotManager.lua
21. src/gui/DialogLoader.lua
22. src/gui/CTManagementDialog.lua
23. src/gui/CTCategoryDialog.lua
24. src/gui/CTBuilderDialog.lua
25. src/gui/CTConfirmDialog.lua
26. src/gui/CTSettingsDialog.lua
27. src/gui/CTHelpDialog.lua
28. src/CustomTriggerCreator.lua       ← coordinator, depends on everything above
```

---

## Lifecycle hooks

| FS25 hook | CTC action |
|---|---|
| `Mission00.load` | Creates `CustomTriggerCreator` instance, sets `g_CTCSystem` |
| `Mission00.loadMission00Finished` | Registers and eagerly loads all dialogs; installs keyEvent guard |
| `Mission00.onStartMission` | Loads `ctc_data.xml` from savegame |
| `FSBaseMission.update` | Drives `CTWorldManager` proximity checks |
| `FSBaseMission.draw` | Renders HUD toasts and world beacons |
| `FSBaseMission.delete` | Cleans up all managers and dialogs |
| `FSCareerMissionInfo.saveToXMLFile` | Writes `ctc_data.xml` to savegame |

---

## Central coordinator

`CustomTriggerCreator` owns all subsystems:

```
CustomTriggerCreator (g_CTCSystem)
├── settings              CTSettings
├── settingsIntegration   CTSettingsIntegration
├── markerDetector        MarkerDetector
├── triggerRegistry       TriggerRegistry
├── triggerBuilder        TriggerBuilder
├── triggerExecutor       TriggerExecutor
├── triggerExporter       CTTriggerExporter
├── notificationHUD       CTNotificationHUD
├── hotspotManager        CTHotspotManager
├── worldManager          CTWorldManager
├── markerManager         CTMarkerManager
├── scriptRegistry        table  (key → Lua function, for FIRE_EVENT)
└── conditionRegistry     table  (key → gate function, for CONDITIONAL_CB)
```

---

## Data flow — creating a trigger

```
Player presses F8
  → CTManagementDialog opens
  → Player clicks + Create New
    → CTCategoryDialog opens (pick category)
    → CTBuilderDialog:startWizard(category)
      → 6-step wizard
      → onClickCreate()
        → TriggerBuilder:build(config)        builds the record
        → TriggerRegistry:add(record)         stores in memory
        → CTWorldManager:refresh(registry)    creates proximity zone
        → CTMarkerManager:spawnMarker(record) queues 3D icon async
        → CTHotspotManager:addHotspot(record) pins map icon
        → TriggerSerializer (auto-save)       persists to XML
        → CTNotificationHUD:push(...)         "Trigger Created" toast
```

---

## Data flow — activating a trigger

```
Player walks into CTWorldManager zone
  → CTTriggerActivatable:getIsActivatable()  returns true (if enabled, not busy)
  → FS25 shows "[E] Activate: TriggerName"
  → Player presses E
    → CTTriggerActivatable:run()
      → TriggerExecutor:executeById(id)
        → registry:getById(id)               fetches record
        → CLASS_MAP[record.type].execute()   fires the trigger class
          → EconomyTrigger / NotificationTrigger / etc.
        → notificationHUD:push(result)       shows outcome toast
```

---

## Trigger class anatomy

Each trigger type in `src/triggers/` follows this interface:

```lua
MyTrigger = {}
MyTrigger._mt = { __index = MyTrigger }

function MyTrigger.new(record)
    local self = setmetatable({}, MyTrigger._mt)
    self.record = record
    return self
end

---@param record table  The full trigger record from the registry
---@return boolean ok
---@return string  message
function MyTrigger:execute(record)
    -- Implementation
    return true, "Success message"
end
```

`TriggerExecutor` looks up the class in its `CLASS_MAP` table, instantiates it, calls `:execute()`, and handles the result.

---

## GUI system notes

- All dialogs extend `MessageDialog` (not `DialogElement` — deprecated in FS25)
- Dialog XML uses `onOpen="onDialogOpen"` / `onClose="onDialogClose"` (not `onOpen` / `onClose` — stack overflow)
- Coordinate system: Y=0 at bottom, increases upward. Dialog content Y is negative going down from top.
- `TextInputElement` requires `maxInputTextWidth` in its profile — without it, `draw()` throws every frame
- 3-layer button pattern: `Bitmap` (bg) + `Text` (label) + `Button extends="emptyPanel"` (hit area)
- Images from a ZIP must be set dynamically via `setImageFilename()` in Lua — XML `imageFilename` doesn't resolve from ZIP

---

## Serialization

Triggers save to `{savegameDirectory}/ctc_data.xml` using FS25's `XMLFile` API.

```xml
<CustomTriggerCreator>
    <triggers>
        <trigger id="ctc_0001" name="My Trigger" category="ECONOMY" type="PAY_FEE" enabled="true">
            <config amount="500" worldX="-776.4" worldY="47.4" worldZ="118.3" markerType="SHOP" cooldownSec="0" repeatLimit="0"/>
        </trigger>
    </triggers>
    <meta nextId="2"/>
</CustomTriggerCreator>
```

`TriggerSerializer` handles both save and load. New config fields must be added to `CONFIG_SCHEMA` in that file along with a default value for backward compatibility.

---

## keyEvent guard

`main.lua` captures `Mission00.keyEvent` at module load time (before later-loading mods append their handlers) and stores it as `preModKeyEvent`. In `onLoadFinished`, after all mods have registered their hooks, the guard replaces `Mission00.keyEvent`:

```lua
Mission00.keyEvent = function(mission, ...)
    if g_gui ~= nil and g_gui.currentGui ~= nil then
        return preModKeyEvent(mission, ...)  -- bypass third-party handlers
    end
    return fullKeyEvent(mission, ...)        -- normal path
end
```

This prevents mods like FS25_FarmTablet (which use `Utils.appendedFunction` and don't check `g_gui.currentGui`) from intercepting keystrokes while a CTC dialog is open.
