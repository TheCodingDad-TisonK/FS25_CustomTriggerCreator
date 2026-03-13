<div align="center">
    
# 🎯 FS25 Custom Trigger Creator
### *In-Game Trigger Builder — No Code Required*

[![Downloads](https://img.shields.io/github/downloads/TheCodingDad-TisonK/FS25_CustomTriggerCreator/total?style=for-the-badge&logo=github&color=2196f3&logoColor=white)](https://github.com/TheCodingDad-TisonK/FS25_CustomTriggerCreator/releases)
[![Release](https://img.shields.io/github/v/release/TheCodingDad-TisonK/FS25_CustomTriggerCreator?style=for-the-badge&logo=tag&color=42a5f5&logoColor=white)](https://github.com/TheCodingDad-TisonK/FS25_CustomTriggerCreator/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-lightgrey?style=for-the-badge&logo=opensourceinitiative&logoColor=white)](LICENSE)

<br>

> *"Spent three hours editing XML to make a simple shop trigger — then found this. Built the same thing in two minutes with the wizard. Never touched a file."*

<br>

**FS25 triggers are locked behind XML files and Lua scripts. This mod changes that.**

Create any trigger — economy transactions, multi-step chained flows, conditional gates, HUD notifications — entirely from inside the game. No files. No code. Press F8, follow the wizard, done.

`Singleplayer` • `Multiplayer` • `Persistent saves` • `EN / DE`

</div>

> [!TIP]
> Want to be part of our community? Share triggers, report issues, and chat with other farmers on the **[FS25 Modding Community Discord](https://discord.gg/Th2pnq36)**!

---

<img width="1035" height="682" alt="ctc_new1" src="https://github.com/user-attachments/assets/d427e205-f10c-438b-ab60-f5dbe6122ef0" />

---
## ✨ Features

### 🧙 8-Step Trigger Wizard

Every trigger is built through the same guided flow — no experience needed.

```
Step 1  Pick a category
Step 2  Pick a trigger type within that category
Step 3  Configure type-specific settings (amounts, messages, fill types)
Step 4  Set conditions  (time window, balance check, probability gate)
Step 5  Set actions     (coming in v1.1)
Step 6  Advanced options (cooldown, repeat limit, confirmation prompt)
Step 7  Name your trigger
Step 8  Review & confirm
```

### 🗂️ Trigger Categories

| Category | Types | What it does |
|----------|-------|--------------|
| **Economy** | Buy/Sell, Pay Fee, Earn, Barter | Money transactions tied to your farm balance |
| **Interaction** | Talk NPC, Receive Item, Fire Event, Animation | Player interactions and external Lua callbacks |
| **Notification** | Info, Success, Warning, Error | Instant HUD toast announcements |
| **Conditional** | Time Check, Money Check, Random, Item Check | Gate any action behind a condition |
| **Chained** | 2-Step, 3-Step, Branching, Timed | Multi-step flows with confirmations and countdowns |
| **Custom Script** | Lua Callback, Event Hook, Scheduled, Conditional CB | Advanced — requires Admin Mode in settings |

### 🖥️ Management Dialog

Open with **F8** from anywhere in the game.

| Button | Action |
|--------|--------|
| **RUN** | Fire a trigger immediately — great for testing |
| **Toggle** | Enable or disable without deleting |
| **Delete** | Remove in one click |
| **Export** | Save all triggers to `ctc_export.xml` in your savegame folder |
| **Import** | Load and merge triggers from that file |

### 🔔 HUD Notifications

Top-right corner toast notifications with slide-in and fade-out animation. Up to 5 stacked. Timed chained triggers display a live countdown bar below the stack.

| Level | Colour | Use case |
|-------|--------|----------|
| `INFO` | Blue | Neutral messages, process started |
| `SUCCESS` | Green | Completed actions, rewards paid |
| `WARNING` | Amber | Condition not met, insufficient funds |
| `ERROR` | Red | Trigger failed or blocked |

### 🔗 Chained Trigger Types

| Type | Flow |
|------|------|
| **2-Step** | Notify → confirm dialog → optional reward |
| **3-Step** | Notify → confirm → notify → confirm → reward |
| **Branching** | Yes / No dialog — different outcome per path |
| **Timed** | Countdown timer with live HUD bar → auto-fires on completion |

### 📐 Conditional Triggers

Conditions are evaluated at activation time. Fail → warning toast, inner action not fired.

| Type | Config |
|------|--------|
| **Time Check** | Active window: From hour → To hour (midnight wrap supported) |
| **Money Check** | Player farm balance must be ≥ configured minimum |
| **Random** | Fires with a configured probability (0–100%) |
| **Item Check** | Always passes for now *(v1.3 inventory API)* |

### 🗺️ Map Hotspots *(v1.2 ready)*

`CTHotspotManager` is wired and ready. Map pins will appear on the minimap and world map once world placement is added in v1.1.

---

## ⚙️ Settings

Open via **ESC → Settings → Game Settings → Custom Trigger Creator**.

| Setting | Default | Description |
|---------|---------|-------------|
| **Mod Enabled** | On | Master on/off switch |
| **Detection Radius** | 5 m | Proximity range for nearby marker hints |
| **Notifications** | On | Master toggle for HUD toasts |
| **Notification Duration** | 4 s | How long toasts stay on screen |
| **Max Triggers Per Save** | 100 | Hard cap for performance |
| **Show Trigger Zones** | On | Visual debug overlay *(v1.2)* |
| **Admin Mode** | Off | Unlocks the Custom Script trigger category |
| **Debug Mode** | Off | Verbose `[CTC]` logging to `log.txt` |

> [!NOTE]
> Triggers and settings persist to `ctc_data.xml` inside your savegame folder and survive game restarts.

---

## 📦 Export & Import

**Export** writes a `ctc_export.xml` file to your current savegame folder containing all triggers.
**Import** reads that file and merges any triggers not already in the registry.

Use this to back up your trigger collection, restore after a save wipe, or share configs with other players.

---

## 🛠️ Installation

**1. Download** `FS25_CustomTriggerCreator.zip` from the [latest release](https://github.com/TheCodingDad-TisonK/FS25_CustomTriggerCreator/releases/latest).

**2. Copy** the ZIP (do not extract) to your mods folder:

| Platform | Path |
|----------|------|
| 🪟 Windows | `%USERPROFILE%\Documents\My Games\FarmingSimulator2025\mods\` |
| 🍎 macOS | `~/Library/Application Support/FarmingSimulator2025/mods/` |

**3. Enable** *Custom Trigger Creator* in the in-game mod manager.

**4. Load** any career save — press **F8** to open the creator.

---

## 🎮 Quick Start

```
1. Load your farm and press F8
2. Click + Create New
3. Pick a category → pick a type → configure it through the wizard
4. Hit Create Trigger on the review screen
5. Your trigger appears in the list — press RUN to test it immediately
6. Toggle it off/on or delete it at any time
7. Press Export to back up your trigger collection
```

> [!TIP]
> Start with a **Notification → Info** trigger to get familiar with the wizard before building economy or chained flows.

---

## ⌨️ Key Bindings

| Key | Action |
|-----|--------|
| **F8** | Open / close the Trigger Creator |

---

## 🔌 For Mod Developers

Register Lua callbacks for `FIRE_EVENT` triggers — no dependency required, just a nil-safe check:

```lua
-- In your mod's initialization (after g_CTCSystem is created):
if g_CTCSystem then
    g_CTCSystem.scriptRegistry["myEventKey"] = function()
        -- Your custom logic here
        print("My event fired from a CTC trigger!")
    end
end
```

Any `FIRE_EVENT` trigger configured with `eventName = "myEventKey"` will call your function on activation. The `scriptRegistry` table is available from the moment the mod loads.

---

## 🗺️ Roadmap

| Version | Planned |
|---------|---------|
| **1.1.0** | World placement — place triggers at any location on the map |
| **1.2.0** | CTHotspotManager — map pin per trigger (requires world placement) |
| **1.3.0** | ITEM_CHECK — inventory API integration |
| **1.4.0** | Multiplayer registry sync |
| **1.5.0** | Trigger edit — re-open wizard on existing trigger |

---

## 🤝 Contributing

Found a bug? [Open an issue](https://github.com/TheCodingDad-TisonK/FS25_CustomTriggerCreator/issues/new/choose) — the template will guide you through what's needed.

Have a feature idea? Check the roadmap above first, then [open a feature request](https://github.com/TheCodingDad-TisonK/FS25_CustomTriggerCreator/issues/new/choose).

---

## 📝 License

This mod is licensed under the **[MIT License](LICENSE)**.

Free to use, modify, and redistribute with attribution. Contributions via pull request are welcome.

**Author:** TisonK · **Version:** 1.0.0.0

---

<div align="center">

*Farming Simulator 25 is published by GIANTS Software. This is an independent fan creation, not affiliated with or endorsed by GIANTS Software.*

*Build the triggers your farm deserves.* 🎯

</div>
