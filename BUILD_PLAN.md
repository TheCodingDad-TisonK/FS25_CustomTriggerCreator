# BUILD PLAN — FS25_CustomTriggerCreator
**Authors:** Claude & Samantha
**Human Reviewer:** TisonK
**Status:** Active Development — v1.0.0 Shipped, Phase 6 In Progress
**Target:** Farming Simulator 25 Mod

---

## Vision

Player-facing, in-game tool that lets anyone create, configure, and manage custom interaction triggers — without touching XML or Lua. Players open the creator, define a trigger from scratch, choose its visual marker style (shop icon, unload icon, garage icon, etc.), configure behavior step-by-step, and place it anywhere in the world. Advanced triggers support multi-step flows with confirmations, timers, and chained actions.

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

### 1. Trigger Placement
Player opens the creator via keybind (F8 — anywhere in the world).
Player picks a **visual marker style** to represent their trigger on the map and in the world:
- Shop / Store icon
- Unload / Intake icon
- Sell point icon
- Garage / Workshop icon
- Animal / Feeding icon
- Silo icon

Player then walks to the desired location and **places the trigger** (like placing a placeable).
Placed trigger appears in the world with its chosen icon and an interaction radius.

### 2. Trigger Category Browser
First dialog after opening. Player picks a category:

| Category | Description |
|----------|-------------|
| **Economy** | Buy/sell goods, charge fees, pay wages |
| **Interaction** | Talk to NPC, receive item, trigger event |
| **Conditional** | Gate actions behind checks (time of day, money, item) |
| **Chained** | Multi-step flow with confirmations between steps |
| **Notification** | Announce events to player via HUD notification |
| **Custom Script** | Advanced: attach a registered external Lua callback (Admin Mode only) |

### 3. Step-by-Step Trigger Builder
Wizard-style dialog flow — one screen per step:

```
Step 1: Pick Category        (CTCategoryDialog)
Step 2: Pick Trigger Type    (within category)
Step 3: Configure Settings   (type-specific fields)
Step 4: Set Conditions       (optional — CONDITIONAL category only)
Step 5: Set World Position   (walk-to-place flow — Phase 6)
Step 6: Advanced Options     (cooldown, repeat, confirmation prompts)
Step 7: Name & Icon
Step 8: Review & Confirm
```

### 4. Advanced / Chained Triggers
Multi-step activation flows:
- **TWO_STEP:** Action → confirm → reward
- **THREE_STEP:** Triple confirmation flow
- **BRANCHING:** Yes/No branch at each step (full UI — Phase 6)
- **TIMED:** Countdown between steps (HUD countdown — Phase 6)

### 5. Notification System
- Toast-style HUD notifications (top-right)
- Types: `INFO`, `SUCCESS`, `WARNING`, `ERROR`
- Configurable duration per trigger
- Queue: up to 5 stacked notifications
- Auto-dismiss with fade

### 6. Trigger Management
- View all player-created triggers
- Toggle trigger on/off, Delete (with confirmation)
- RUN button for direct manual execution
- Export all triggers to `ctc_export.xml` in savegame dir
- Import / merge triggers from same file

### 7. Mod Settings

| Setting | Default | Description |
|---------|---------|-------------|
| Activation Key | F8 | Key to open creator |
| Detection Radius | 5m | How close player must be to a base-game marker |
| Notifications Enabled | true | Master toggle for HUD notifications |
| Notification Duration | 4s | How long toasts stay on screen |
| Max Triggers Per Save | 100 | Cap for performance |
| Show Trigger Zones | true | Visual debug overlay for trigger areas |
| Admin Mode | false | Unlocks Custom Script category |

---

## File & Folder Architecture

```
FS25_CustomTriggerCreator/
├── modDesc.xml
├── icon.dds / icon.png
├── LICENSE
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── CLAUDE.md
├── BUILD_PLAN.md
├── build.sh
│
├── translations/
│   ├── translation_en.xml          ✓
│   └── translation_de.xml          ✓
│
├── gui/
│   ├── CTCategoryDialog.xml        ✓
│   ├── CTBuilderDialog.xml         ✓
│   ├── CTManagementDialog.xml      ✓
│   ├── CTConfirmDialog.xml         ✓
│   ├── CTSettingsDialog.xml        ✓
│   └── CTHelpDialog.xml            ✓
│
├── src/
│   ├── CustomTriggerCreator.lua    ✓  Main coordinator
│   │
│   ├── core/
│   │   ├── TriggerRegistry.lua     ✓  In-memory trigger store
│   │   ├── TriggerSerializer.lua   ✓  Save/load to ctc_data.xml
│   │   ├── TriggerExecutor.lua     ✓  Runtime dispatcher / chain runner
│   │   ├── MarkerDetector.lua      ✓  Base-game marker proximity
│   │   ├── CTWorldManager.lua      ✓  World-space proximity zones (activatables)
│   │   ├── CTMarkerManager.lua     ✓  3D floating i3d marker nodes per trigger
│   │   ├── CTTriggerActivatable.lua ✓  ActivatableObjectsSystem integration
│   │   └── CTTriggerExporter.lua   ✓  Export/import ctc_export.xml
│   │
│   ├── triggers/
│   │   ├── BaseTrigger.lua         ✓  Base class (cooldown, repeat, result codes)
│   │   ├── EconomyTrigger.lua      ✓  BUY_SELL, PAY_FEE, EARN, BARTER
│   │   ├── InteractionTrigger.lua  ✓  TALK_NPC, GIVE_ITEM, FIRE_EVENT, ANIMATION
│   │   ├── ConditionalTrigger.lua  ✓  TIME_CHECK, MONEY_CHECK, RANDOM (ITEM_CHECK stub)
│   │   ├── ChainedTrigger.lua      ✓  TWO_STEP, THREE_STEP, BRANCHING, TIMED
│   │   ├── NotificationTrigger.lua ✓  INFO, SUCCESS, WARNING, ERROR
│   │   └── CustomScriptTrigger.lua ✓  External Lua callback (Admin Mode only)
│   │
│   ├── gui/
│   │   ├── DialogLoader.lua        ✓  Centralized dialog registry
│   │   ├── CTCategoryDialog.lua    ✓  Category browser
│   │   ├── CTBuilderDialog.lua     ✓  8-step wizard (Step 5 wires to world placement)
│   │   ├── CTManagementDialog.lua  ✓  Trigger list w/ Toggle, Delete, Run, Export
│   │   ├── CTConfirmDialog.lua     ✓  Reusable Yes/No confirmation
│   │   ├── CTSettingsDialog.lua    ✓  In-game settings panel
│   │   └── CTHelpDialog.lua        ✓  In-game help / reference
│   │
│   ├── hud/
│   │   ├── CTNotificationHUD.lua   ✓  Toast renderer (slide-in, hold, fade)
│   │   └── CTHotspotManager.lua    ✓  Map icon overlay (activates when worldX/Z set)
│   │
│   ├── settings/
│   │   ├── CTSettings.lua          ✓  Settings data model
│   │   └── CTSettingsIntegration.lua ✓ FS25 settings panel hooks
│   │
│   └── utils/
│       └── Logger.lua              ✓  Prefixed [CTC] log utility
│
└── xml/
    └── defaultTriggers.xml         ○  Optional — bundled example triggers (deferred)
```

---

## Implementation Phases

### Phase 1 — Foundation ✓ COMPLETE
- [x] Repo created on GitHub (`development` branch)
- [x] `modDesc.xml` scaffolded with correct metadata
- [x] `CLAUDE.md` written
- [x] `build.sh` — build + deploy script
- [x] `CustomTriggerCreator.lua` — mod entry, `initialize()`, `update()`, `delete()`
- [x] `Logger.lua` — prefixed `[CTC]` log utility
- [x] `CTSettings.lua` + `CTSettingsIntegration.lua` — settings skeleton
- [x] `MarkerDetector.lua` — proximity detection for base-game markers
- [x] HUD hint on marker proximity

### Phase 2 — Core GUI ✓ COMPLETE
- [x] `DialogLoader.lua`
- [x] `CTCategoryDialog.xml` + `CTCategoryDialog.lua` — category browser
- [x] `CTBuilderDialog.xml` + `CTBuilderDialog.lua` — wizard skeleton (steps 1–3)
- [x] `CTManagementDialog.xml` + `CTManagementDialog.lua` — trigger list
- [x] `TriggerRegistry.lua` — in-memory trigger store
- [x] `TriggerSerializer.lua` — XML save/load (hooks into savegame events)
- [x] F8 keybind to open creator

### Phase 3 — Trigger Types ✓ COMPLETE
- [x] `BaseTrigger.lua`
- [x] `EconomyTrigger.lua` — BUY_SELL, PAY_FEE, EARN, BARTER
- [x] `InteractionTrigger.lua` — TALK_NPC, GIVE_ITEM, FIRE_EVENT, ANIMATION
- [x] `NotificationTrigger.lua` — INFO, SUCCESS, WARNING, ERROR
- [x] `CTNotificationHUD.lua` — toast renderer
- [x] Wizard steps 4–8 (conditions, advanced options, name, review)
- [x] `CTConfirmDialog.xml` + `CTConfirmDialog.lua`

### Phase 4 — Advanced Triggers ✓ COMPLETE
- [x] `ChainedTrigger.lua` — TWO_STEP, THREE_STEP, BRANCHING, TIMED
- [x] `ConditionalTrigger.lua` — TIME_CHECK, MONEY_CHECK, RANDOM
- [x] `TriggerExecutor.lua` — runtime executor for chains
- [x] Countdown bar in HUD for TIMED chains
- [x] Per-row RUN button in management dialog
- [x] Wizard step 4 — real condition config fields for CONDITIONAL

### Phase 5 — Polish & Release ✓ COMPLETE (v1.0.0 shipped 2026-03-13)
- [x] `CTHotspotManager.lua` — map icon overlay (ready; activates on worldX/Z)
- [x] Full translations (EN + DE)
- [x] Admin Mode gate — Custom Script category hidden unless enabled
- [x] `CTTriggerExporter.lua` — export/import triggers to `ctc_export.xml`
- [x] Export / Import buttons in management dialog
- [x] `CTSettingsDialog` + `CTHelpDialog`
- [x] CHANGELOG.md populated
- [x] PR `development` → `main` + `v1.0.0` tag

### Phase 6 — World Placement (NEXT) 🔧 IN PROGRESS
The infrastructure is largely ready (`CTWorldManager`, `CTMarkerManager`, `CTTriggerActivatable` all exist). The missing piece is the wizard UX to let the player actually pick and place a trigger location in the world, and wiring that position into all dependent systems.

**Target use case (user story — issue #20):** Ferry crossing automation with AutoDrive — a chained trigger sequence that calls the ferry, waits for the barrier, repositions AD via a Custom Script callback, pauses during the crossing (TIMED chain), and resumes AD on arrival. This is the primary integration scenario to validate when Custom Script inter-mod callbacks land. Also noted: presence-based light timers and single-door triggers as TIMED + CONDITIONAL chain targets.

- [ ] **Wizard Step 5 (World Position)** — Replace the current stub with a "walk to location" flow:
  - Player clicks "Set Position" in wizard
  - Wizard closes temporarily; player walks to desired spot; presses Confirm
  - Position stored as `config.worldX`, `config.worldY`, `config.worldZ`
  - Wizard reopens at step 6 with position confirmed
- [ ] **CTMarkerManager** — Expand marker types beyond `SHOP`:
  - UNLOAD, SELL, GARAGE, ANIMAL, SILO icons (using base-game shared i3d assets)
- [ ] **CTHotspotManager** — Activate map hotspot icons once worldX/Z are set
- [ ] **BRANCHING chain wizard UX** — Step-specific Yes/No path config in CTBuilderDialog
- [ ] **TIMED chain wizard UX** — Per-step countdown duration field in CTBuilderDialog
- [ ] **ITEM_CHECK condition** — Wire to FS25 inventory API (check LUADOC first)
- [ ] **Multiplayer** — TriggerRegistry server-authoritative sync via game events
- [ ] **`xml/defaultTriggers.xml`** — Optional bundled example triggers

**Release target:** v1.1.0

---

## Technical Constraints & Notes

- **Lua version:** FS25 uses Lua 5.1 — no bitwise operators, no `goto`, no `continue`, no integer division `//`
- **GUI system:** FS25 uses XML-declared GUI with Lua controllers — follow `DialogLoader.lua` pattern exactly
- **Save format:** Triggers persist to `ctc_data.xml` via `XMLFile` FS25 APIs
- **Export format:** `ctc_export.xml` in savegame directory via `CTTriggerExporter`
- **API reference:** Always check `C:\Users\tison\Desktop\FS25 MODS\FS25-Community-LUADOC` before any API call
- **No external dependencies** — pure Lua + game APIs only
- **Performance:** CTWorldManager uses distance-squared checks — never `math.sqrt` in `update()`
- **Activation key:** F8 (F7 is taken by FS25_NPCFavor)
- **Map hotspots:** CTHotspotManager uses `drawFields` hook — NOT `addMapHotspot` / `PlaceableHotspot` (crashes without valid i3d node)
- **3D markers:** CTMarkerManager loads shared `$data/shared/assets/marker/*.i3d` via `g_i3DManager` async

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

| Version | Milestone | Status |
|---------|-----------|--------|
| 0.1.0 | Foundation + settings + marker detection | Shipped (internal) |
| 0.2.0 | Core GUI dialogs + trigger registry | Shipped (internal) |
| 0.3.0 | Economy + Interaction + Notification trigger types | Shipped (internal) |
| 0.4.0 | Chained + Conditional triggers | Shipped (internal) |
| 1.0.0 | Full release — all features, translations, map icons | **Shipped 2026-03-13** |
| 1.0.x | Bugfix patches | 1.0.5.1 current |
| 1.1.0 | World placement — triggers placed in the 3D world | Phase 6 target |

---

*Plan authored by Claude & Samantha — reviewed by tison*
*Last updated: 2026-03-15*
