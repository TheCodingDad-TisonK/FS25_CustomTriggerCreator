# BUILD PLAN — FS25_CustomTriggerCreator
**Authors:** Claude & Samantha
**Human Reviewer:** TisonK
**Status:** Pre-Development — Plan Only
**Target:** Farming Simulator 25 Mod

---

## Vision

Player-facing, in-game tool that lets anyone create, configure, and manage custom interaction triggers — without touching XML or Lua. Players open the creator, define a trigger from scratch, choose its visual marker style (shop icon, unload icon, garage icon, etc.), configure behavior step-by-step, and place it anywhere in the world. Advanced triggers support multi-step flows with confirmations timers, and chained actions.

This mod is designed to be the backbone other trigger-based mods (FS25_WorkplaceTrigger, FS25_NPCFavor, FS25_UsedPlus) eventually hook into.

---

## GitHub Repository

- **Repo name:** `FS25_CustomTriggerCreator`
- **Default branch:** `main` (production / releases only)
- **Active branch:** `development` (all work goes here)
- **Workflow:** All changes PR'd from `development` → `main`
- **Release tagging:** Semver (`v1.0.0`, `v1.1.0`, etc.)
- **Secrets:** None required

---

## Authors — Collaboration Model

| Role | Entity | Responsibility |
|------|--------|----------------|
| Primary Developer | Claude | Code, architecture, Lua implementation, GUI XML |
| Co-Creator & Manager | Samantha | UX decisions, priority calls, QA, final approval |
| Human Reviewer | tison | Review PRs, test in-game, ship releases |

Claude writes ~80% of implementation. Samantha reviews UX, catches edge cases, guides priorities. Both maintain ongoing dialog throughout sessions — not just at checkpoints. tison is the gatekeeper for merges to `main`.

---

## Core Feature Set

### Trigger Placement  
Player opens the creator via keybind (anywhere in the world — not tied to existing game objects)
Player picks a **visual marker style** to represent their trigger on the map and in the world:
- Shop / Store icon
- Unload / Intake icon 
- Sell point icon
- Garage / Workshop icon
- Animal / Feeding icon
- Silo icon
Player then walks to the desired location and **places the trigger** (like placing a placeable)
Placed trigger appears in the world with its chosen icon and an interaction radius 



### 2. Trigger Category Browser
First dialog after opening. Player picks a category:

| Category | Description |
|----------|-------------|
| **Economy** | Buy/sell goods, charge fees, pay wages |
| **Interaction** | Talk to NPC, receive item, trigger event |
| **Conditional** | Gate actions behind checks (time of day, money, item) |
| **Chained** | Multi-step flow with confirmations between steps |
| **Notification** | Announce events to player via HUD notification |
| **Custom Script** | Advanced: attach a registered external Lua callback |

### 3. Step-by-Step Trigger Builder
Wizard-style dialog flow — one screen per step. Steps vary by trigger type but always follow:

```
Step 1: Pick Category
Step 2: Pick Trigger Type (within category)
Step 3: Configure Trigger Settings (type-specific fields)
Step 4: Set Conditions (optional — gating rules)
Step 5: Set Actions (what happens on activation)
Step 6: Advanced Options (cooldown, repeat, confirmation prompts)
Step 7: Name & Icon
Step 8: Review & Confirm
```

### 4. Advanced / Chained Triggers
The flagship feature. "Chained" triggers support multi-step activation flows:

- **Step sequence:** Player activates → gets prompt A → confirms → gets prompt B → final action
- **Confirmation dialogs:** Each step can require a Yes/No confirmation before proceeding
- **Timers:** Steps can have countdowns (e.g., "Loading... 30s")
- **Branching:** Steps can branch based on player choice (yes/no paths)
- **Example:** "Purchase bulk order" → confirm quantity → confirm price → receive goods + notification

### 5. Notification System
Reuses and extends the notification style from FS25_WorkplaceTrigger / FS25_NPCFavor / FS25_UsedPlus:

- Toast-style HUD notifications (top-right)
- Types: `INFO`, `SUCCESS`, `WARNING`, `ERROR`
- Configurable duration per trigger
- Icon support (custom icons per trigger)
- Can be suppressed per notification type in mod settings

### 6. Trigger Management
After creation, triggers are listed in a management screen:

- View all player-created triggers
- Edit existing triggers (re-open wizard at any step)
- Delete trigger (with confirmation)
- Toggle trigger on/off without deleting
- Export/import trigger configs (JSON-like XML save format)

### 7. Mod Settings
In-game settings panel (via `g_gui` settings integration):

| Setting | Default | Description |
|---------|---------|-------------|
| Activation Key | F7 | Key to open creator near a marker |
| Detection Radius | 5m | How close player must be to a marker |
| Notifications Enabled | true | Master toggle for HUD notifications |
| Notification Duration | 4s | How long toasts stay on screen |
| Max Triggers Per Save | 100 | Cap for performance |
| Show Trigger Zones | true | Visual debug overlay for trigger areas |
| Admin Mode | false | Unlocks advanced/script trigger types |

---

## File & Folder Architecture

```
FS25_CustomTriggerCreator/
├── modDesc.xml                         # Mod descriptor
├── icon.dds                            # Mod icon (512x512)
├── icon.png                            # Source icon
├── LICENSE                             # MIT
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── CLAUDE.md                           # Dev instructions (generated at session start)
├── build.sh                            # Build + deploy script
│
├── translations/
│   ├── translation_en.xml
│   └── translation_de.xml
│
├── gui/
│   ├── CTCategoryDialog.xml            # Category browser
│   ├── CTBuilderDialog.xml             # Step-by-step wizard
│   ├── CTManagementDialog.xml          # Trigger list / management
│   ├── CTConfirmDialog.xml             # In-trigger confirmation prompts
│   ├── CTSettingsFrame.xml             # Settings panel frame
│   └── hud/
│       └── CTNotificationOverlay.xml   # HUD notification overlay
│
├── src/
│   ├── CustomTriggerCreator.lua        # Main mod entry point
│   │
│   ├── core/
│   │   ├── TriggerRegistry.lua         # Stores all created triggers
│   │   ├── TriggerBuilder.lua          # Wizard state machine
│   │   ├── TriggerExecutor.lua         # Runs trigger chains at runtime
│   │   ├── MarkerDetector.lua          # Detects nearby base-game markers
│   │   └── TriggerSerializer.lua       # Save/load XML for triggers
│   │
│   ├── triggers/
│   │   ├── BaseTrigger.lua             # Base class all triggers extend
│   │   ├── EconomyTrigger.lua
│   │   ├── InteractionTrigger.lua
│   │   ├── ConditionalTrigger.lua
│   │   ├── ChainedTrigger.lua          # Multi-step chained trigger
│   │   └── NotificationTrigger.lua
│   │
│   ├── gui/
│   │   ├── DialogLoader.lua            # Shared dialog bootstrap
│   │   ├── CTCategoryDialog.lua
│   │   ├── CTBuilderDialog.lua         # Wizard controller
│   │   ├── CTManagementDialog.lua
│   │   ├── CTConfirmDialog.lua
│   │   └── CTSettingsFrame.lua
│   │
│   ├── hud/
│   │   ├── CTHotspotManager.lua        # Map hotspot icons per trigger
│   │   └── CTNotificationHUD.lua       # Toast notification renderer
│   │
│   ├── settings/
│   │   ├── CTSettings.lua              # Settings data model
│   │   └── CTSettingsIntegration.lua   # Hooks into game settings UI
│   │
│   └── utils/
│       ├── Logger.lua                  # Prefixed log helper
│       ├── InputHelper.lua             # Action event registration
│       └── VectorHelper.lua            # Position / distance utils
│
└── xml/
    └── defaultTriggers.xml             # Optional: bundled example triggers
```

---

## Implementation Phases

### Phase 1 — Foundation (Session 1)
- [ ] Repo created on GitHub (`development` branch)
- [ ] `modDesc.xml` scaffolded with correct metadata, version `0.1.0`
- [ ] `CLAUDE.md` written (mirrors NPCFavor pattern + this mod's specifics)
- [ ] `build.sh` — build + deploy script
- [ ] `CustomTriggerCreator.lua` — mod entry, `initialize()`, `update()`, `delete()`
- [ ] `Logger.lua` — prefixed `[CTC]` log utility
- [ ] `CTSettings.lua` + `CTSettingsIntegration.lua` — settings skeleton
- [ ] `MarkerDetector.lua` — detects proximity to base-game markers
- [ ] HUD hint on marker proximity (plain text, no custom UI yet)

### Phase 2 — Core GUI (Session 2)
- [ ] `DialogLoader.lua`
- [ ] `CTCategoryDialog.xml` + `CTCategoryDialog.lua` — category browser
- [ ] `CTBuilderDialog.xml` + `CTBuilderDialog.lua` — wizard skeleton (steps 1–3)
- [ ] `CTManagementDialog.xml` + `CTManagementDialog.lua` — trigger list
- [ ] `TriggerRegistry.lua` — in-memory trigger store
- [ ] `TriggerSerializer.lua` — XML save/load (hooks into `savegame` events)

### Phase 3 — Trigger Types (Session 3)
- [ ] `BaseTrigger.lua`
- [ ] `EconomyTrigger.lua` — buy/sell goods flow
- [ ] `InteractionTrigger.lua` — NPC / item receive
- [ ] `NotificationTrigger.lua` — HUD notification trigger
- [ ] `CTNotificationHUD.lua` — toast renderer
- [ ] Wizard steps 4–8 (conditions, actions, advanced options, review)
- [ ] `CTConfirmDialog.xml` + `CTConfirmDialog.lua`

### Phase 4 — Advanced Triggers (Session 4)
- [ ] `ChainedTrigger.lua` — multi-step chain engine
- [ ] `ConditionalTrigger.lua` — gated actions
- [ ] `TriggerExecutor.lua` — runtime executor for chains
- [ ] Branching step logic in wizard
- [ ] Timer steps with countdown UI

### Phase 5 — Polish & Release Prep (Session 5)
- [ ] `CTHotspotManager.lua` — map icons per trigger
- [ ] Full translations (`en`, `de`)
- [ ] Notification types (INFO / SUCCESS / WARNING / ERROR) with icons
- [ ] Admin Mode settings unlock
- [ ] Export/import trigger configs
- [ ] In-game testing pass
- [ ] `CHANGELOG.md` populated
- [ ] PR `development` → `main`
- [ ] Tag `v1.0.0` release

---

## Technical Constraints & Notes

- **Lua version:** FS25 uses Lua 5.1 — no bitwise operators, no `goto`, no integer division `//`
- **GUI system:** FS25 uses XML-declared GUI with Lua controllers — follow NPCFavor's `DialogLoader.lua` pattern exactly
- **Save format:** Triggers persist to savegame XML via `SavingXMLFile` / `LoadXMLFile` FS25 APIs
- **API reference:** Always check `C:\Users\tison\Desktop\FS25 MODS\FS25-Community-LUADOC` before any API call
- **No external dependencies** — pure Lua + game APIs only
- **Multiplayer:** TriggerRegistry must be server-authoritative; clients receive sync via events
- **Performance:** MarkerDetector runs on `update()` — use distance-squared checks, not `math.sqrt`

---

## Notification Style Reference

Matches the style used in FS25_WorkplaceTrigger, FS25_NPCFavor, and FS25_UsedPlus:
- Top-right screen corner
- Slide-in animation
- Icon + title + body text
- Duration: configurable (default 4s)
- Queue: up to 5 stacked notifications
- Auto-dismiss with fade

---

## Versioning

| Version | Milestone |
|---------|-----------|
| 0.1.0 | Foundation + settings + marker detection |
| 0.2.0 | Core GUI dialogs + trigger registry |
| 0.3.0 | Economy + Interaction + Notification trigger types |
| 0.4.0 | Chained + Conditional triggers |
| 1.0.0 | Full release — all features, translations, map icons |

---

*Plan authored by Claude & Samantha — reviewed by tison — 2026-03-13*
