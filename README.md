# FS25_CustomTriggerCreator

**Version:** 1.0.0
**Author:** TisonK
**Game:** Farming Simulator 25

Create, configure, and manage custom interaction triggers in-game — no XML or Lua knowledge required.

---

## What is it?

Custom Trigger Creator is an in-game tool that lets you build your own interaction triggers from scratch using a step-by-step wizard. Each trigger can fire economy transactions, display HUD notifications, run conditional checks, or execute multi-step chained flows — all configured live in your save without touching any files.

---

## Features

### Trigger Categories

| Category | Types | Description |
|----------|-------|-------------|
| **Economy** | Buy/Sell, Pay Fee, Earn, Barter | Money transactions tied to game farm balance |
| **Interaction** | Talk NPC, Receive Item, Fire Event, Animation | Player interactions and external Lua callbacks |
| **Notification** | Info, Success, Warning, Error | Instant HUD toast announcements |
| **Conditional** | Time Check, Money Check, Random, Item Check | Gate any action behind a condition |
| **Chained** | 2-Step, 3-Step, Branching, Timed | Multi-step flows with confirmations and countdowns |
| **Custom Script** | Lua Callback, Event Hook, Scheduled, Conditional CB | Advanced — requires Admin Mode |

### 8-Step Wizard
Every trigger is built through the same guided wizard:

1. Pick a category
2. Pick a trigger type
3. Configure type-specific settings (amounts, messages, fill types)
4. Set conditions (time window, balance check, probability)
5. Set actions *(Phase 6)*
6. Advanced options (cooldown, repeat limit, require confirmation)
7. Name your trigger
8. Review and confirm

### Management Dialog
- View all created triggers in a scrollable list
- **RUN** — fire a trigger immediately for testing
- **Toggle** — enable or disable without deleting
- **Delete** — remove with one click
- **Export** — save all triggers to `ctc_export.xml` in your savegame folder
- **Import** — load and merge triggers from that file

### HUD Notifications
Top-right corner toast notifications with slide-in and fade-out animation. Up to 5 stacked toasts. Timed chained triggers show a live countdown bar below the stack.

### Map Hotspots *(Phase 6 ready)*
`CTHotspotManager` is wired and ready. Hotspots will appear on the minimap and world map once world placement is added in Phase 6.

---

## Getting Started

1. Install the mod to your `mods` folder
2. Load any savegame
3. Press **F8** to open the Trigger Creator
4. Hit **+ Create New** and follow the wizard
5. Your trigger appears in the list immediately — press **RUN** to test it

---

## Controls

| Key | Action |
|-----|--------|
| **F8** | Open / close the Trigger Creator |

---

## Trigger Details

### Economy Triggers
| Type | Effect |
|------|--------|
| `EARN` | Adds money to player's farm |
| `PAY_FEE` | Deducts money (blocked if balance too low) |
| `BUY_SELL` | Exchange goods at a configured price per unit |
| `BARTER` | Item-for-item trade *(Phase 6 full impl)* |

### Conditional Triggers
Conditions are evaluated at activation time. If the condition fails, a warning toast is shown and no inner action fires.

| Type | Config |
|------|--------|
| `TIME_CHECK` | Active window: From hour → To hour (supports midnight wrap) |
| `MONEY_CHECK` | Player farm balance must be ≥ minimum |
| `RANDOM` | Fires with the configured probability (0–100%) |
| `ITEM_CHECK` | Always passes for now *(Phase 6 inventory API)* |

### Chained Triggers
| Type | Flow |
|------|------|
| `TWO_STEP` | Notify → confirm dialog → optional reward |
| `THREE_STEP` | Notify → confirm → notify → confirm → reward |
| `BRANCHING` | Yes/No dialog with separate outcomes per path |
| `TIMED` | Countdown timer between steps with live HUD bar |

---

## Advanced Options (Step 6)

| Option | Default | Description |
|--------|---------|-------------|
| Cooldown | None | Minimum seconds between activations |
| Repeat Limit | Unlimited | Max total activations (0 = unlimited) |
| Require Confirmation | Off | Shows a CTConfirmDialog before firing |

---

## Export & Import

Export writes a `ctc_export.xml` file to your current savegame folder. Import reads that file and adds any triggers not already present in the registry. Use this to back up trigger collections or share them between savegames.

---

## Mod Settings

Access via the in-game settings panel:

| Setting | Default | Description |
|---------|---------|-------------|
| Mod Enabled | On | Master on/off switch |
| Detection Radius | 5 m | Proximity range for nearby marker hints |
| Notifications | On | Master toggle for HUD toasts |
| Notification Duration | 4 s | How long toasts stay on screen |
| Max Triggers Per Save | 100 | Hard cap for performance |
| Show Trigger Zones | On | Visual debug overlay *(Phase 6)* |
| Admin Mode | Off | Unlocks Custom Script trigger category |
| Debug Mode | Off | Verbose logging to game log |

---

## For Mod Developers

Other mods can register Lua callbacks for `FIRE_EVENT` triggers:

```lua
-- In your mod's initialization:
if g_CTCSystem then
    g_CTCSystem.scriptRegistry["myEventKey"] = function()
        -- Your custom logic here
    end
end
```

Any `FIRE_EVENT` trigger with `eventName = "myEventKey"` will call your function on activation.

---

## Compatibility

- Farming Simulator 25
- Multiplayer: supported (trigger registry is local per client — multiplayer sync planned for Phase 6)
- No conflicts with other mods known

---

## Roadmap

| Version | Planned |
|---------|---------|
| 1.1.0 | World placement — place triggers at any location on the map |
| 1.2.0 | CTHotspotManager activation (requires world placement) |
| 1.3.0 | ITEM_CHECK inventory API integration |
| 1.4.0 | Multiplayer registry sync |

---

## License

MIT — free to use, modify, and redistribute with credit.
