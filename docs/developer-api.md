# Developer API

CTC exposes a lightweight API for other mods to register callbacks, hook events, and react to trigger activity. No hard dependency is required — everything is guarded by nil checks.

---

## The global reference

```lua
g_CTCSystem  -- CustomTriggerCreator instance, available after Mission00.loadMission00Finished
```

Always nil-check before using. CTC may not be installed, or may not have finished loading yet.

---

## Script Registry

The simplest integration point. Register a named Lua function — any `FIRE_EVENT` or `CALLBACK` trigger configured with that key will call it on activation.

### Register a callback

```lua
-- Safe pattern — works even if CTC isn't installed
if g_CTCSystem then
    g_CTCSystem.scriptRegistry["myMod.doSomething"] = function()
        -- Your logic here
        print("CTC fired myMod.doSomething")
    end
end
```

### Register with context data

Callbacks receive no arguments by default. If you need context (the trigger record), hook `triggerExecutor` events instead (see below).

### Unregister

```lua
if g_CTCSystem then
    g_CTCSystem.scriptRegistry["myMod.doSomething"] = nil
end
```

### Naming convention

Use a namespaced key — `modName.eventName` — to avoid collisions with other mods.

---

## Condition Registry

Gate a trigger behind your own Lua logic. Used by `CONDITIONAL_CB` triggers.

```lua
if g_CTCSystem then
    g_CTCSystem.conditionRegistry["myMod.isNight"] = function()
        local hour = g_currentMission.environment.currentHour
        return hour >= 22 or hour < 6  -- true = condition passes
    end
end
```

The registry key is set as the **Condition Key** in the wizard's Step 4.

---

## Listening for trigger execution

Hook into `TriggerExecutor` to react when any trigger fires.

```lua
-- After g_CTCSystem is available:
local executor = g_CTCSystem and g_CTCSystem.triggerExecutor
if executor then
    local originalExecute = executor.executeById
    executor.executeById = function(self, id)
        -- Pre-execution hook
        print("CTC is about to fire trigger: " .. tostring(id))
        return originalExecute(self, id)
    end
end
```

> Prefer the script registry for simple callbacks — direct executor wrapping is for advanced cases.

---

## Reading trigger data

```lua
local registry = g_CTCSystem and g_CTCSystem.triggerRegistry
if registry then
    local all = registry:getAll()       -- array of trigger records
    local t   = registry:getById(id)    -- single record or nil
    local n   = registry:count()        -- integer
end
```

### Trigger record structure

```lua
{
    id       = "ctc_0001",          -- unique string ID
    name     = "My Trigger",        -- player-set name
    category = "ECONOMY",           -- trigger category key
    type     = "PAY_FEE",           -- trigger type key
    enabled  = true,                -- current on/off state
    config   = {
        amount      = 500,
        worldX      = -776.4,       -- world position (nil if not placed)
        worldY      = 47.4,
        worldZ      = 118.3,
        markerType  = "SHOP",       -- 3D icon type ("NONE" = off)
        cooldownSec = 0,
        repeatLimit = 0,
        -- ... type-specific fields
    }
}
```

---

## Pushing notifications from your mod

```lua
local hud = g_CTCSystem and g_CTCSystem.notificationHUD
if hud then
    hud:push("My Mod", "Something happened", "SUCCESS")
    -- Levels: "INFO", "SUCCESS", "WARNING", "ERROR"
end
```

---

## Checking if CTC is ready

```lua
-- Safe check — works at any point in the game lifecycle
local function ctcReady()
    return g_CTCSystem ~= nil and g_CTCSystem.initialized == true
end
```

---

## Example: Full integration

```lua
-- yourmod/main.lua

local function onCTCReady()
    -- Register event callbacks
    g_CTCSystem.scriptRegistry["myMod.openShop"] = function()
        MyShop:open()
    end

    g_CTCSystem.scriptRegistry["myMod.closeShop"] = function()
        MyShop:close()
    end

    -- Register a condition gate
    g_CTCSystem.conditionRegistry["myMod.shopIsOpen"] = function()
        return MyShop ~= nil and MyShop.isOpen
    end

    print("[MyMod] CTC integration registered")
end

-- Hook after mission load, when g_CTCSystem is available
Mission00.loadMission00Finished = Utils.appendedFunction(
    Mission00.loadMission00Finished,
    function(mission)
        if g_CTCSystem then
            onCTCReady()
        end
    end
)
```

---

## Version compatibility

The `scriptRegistry` and `conditionRegistry` tables are stable from v1.0.0 onward. The trigger record structure may gain new fields in future versions — always access fields with nil checks if you're reading `config.*` values.

```lua
local amount = t.config and t.config.amount or 0
```
