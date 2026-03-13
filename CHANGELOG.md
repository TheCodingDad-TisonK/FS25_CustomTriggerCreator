# CHANGELOG — FS25_CustomTriggerCreator

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] — 2026-03-13

### Added

**Phase 1 — Foundation**
- `Logger.lua` — prefixed `[CTC]` log utility with debug gating
- `CTSettings.lua` + `CTSettingsIntegration.lua` — settings data model and FS25 settings panel hooks
- `MarkerDetector.lua` — proximity detection for base-game markers (shops, silos, sell points)
- HUD proximity hint on marker approach
- `build.sh` — build + deploy script

**Phase 2 — Core GUI**
- `DialogLoader.lua` — centralized lazy-loading dialog registry
- `CTManagementDialog` — lists all player triggers with Toggle / Delete per row
- `CTCategoryDialog` — 6-category browser (Economy, Interaction, Conditional, Chained, Notification, Custom Script)
- `CTBuilderDialog` — 8-step wizard for trigger creation
- `TriggerRegistry.lua` — in-memory trigger store with CRUD
- `TriggerSerializer.lua` — save/load triggers to savegame XML (`ctc_data.xml`)
- F8 keybind to open creator

**Phase 3 — Trigger Types**
- `BaseTrigger.lua` — base class with cooldown, repeat limit, result codes
- `EconomyTrigger` — BUY_SELL, PAY_FEE, EARN, BARTER
- `InteractionTrigger` — TALK_NPC, GIVE_ITEM, FIRE_EVENT, ANIMATION
- `NotificationTrigger` — INFO, SUCCESS, WARNING, ERROR
- `CTNotificationHUD.lua` — top-right toast renderer (slide-in, hold, fade-out, max 5 stacked)
- `CTConfirmDialog` — reusable Yes/No confirmation dialog

**Phase 4 — Advanced Triggers**
- `ChainedTrigger` — TWO_STEP, THREE_STEP, BRANCHING, TIMED multi-step flows
- `ConditionalTrigger` — TIME_CHECK, MONEY_CHECK, RANDOM gates; ITEM_CHECK stub
- `TriggerExecutor.lua` — dispatches triggers, manages chained trigger lifecycle per frame
- Countdown bar in HUD for TIMED chains
- Per-row RUN button in management dialog
- Wizard step 4 shows real condition config fields for CONDITIONAL category

**Phase 5 — Polish & Release**
- `CTHotspotManager.lua` — map hotspot manager (prepared; requires world placement in Phase 6)
- `CTTriggerExporter.lua` — export all triggers to `ctc_export.xml`; import and merge from same file
- Export / Import buttons in management dialog
- Admin Mode gate — Custom Script category hidden unless Admin Mode is enabled in settings
- Complete EN and DE translation files (all categories, types, levels, wizard steps, conditions)
- Version bumped to 1.0.0

### Notes
- CTHotspotManager is wired and ready; hotspots activate once triggers have `config.worldX/worldZ` (Phase 6 world placement)
- ITEM_CHECK condition always passes through (Phase 6 inventory API integration)
- CUSTOM_SCRIPT trigger category requires Admin Mode enabled in settings
