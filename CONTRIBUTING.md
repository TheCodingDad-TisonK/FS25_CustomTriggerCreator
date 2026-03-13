# Contributing to FS25 Custom Trigger Creator

Thanks for taking the time to contribute. Every bug report, feature suggestion, and pull request genuinely helps.

---

## Before you open anything

- **Check open issues first** — your bug or idea might already be tracked
- **Check the roadmap in the README** — planned features won't be accepted early as PRs
- **Test on the latest release** — older versions may have bugs already fixed

---

## Reporting bugs

Use the **Bug Report** issue template. The more detail you give, the faster it gets fixed.

Things that always help:
- The exact steps to reproduce it
- What you expected vs. what happened
- Your `log.txt` — located at `%USERPROFILE%\Documents\My Games\FarmingSimulator2025\log.txt`
- Which other mods you have active

---

## Suggesting features

Use the **Feature Request** template. Describe the problem you're trying to solve, not just the solution — there may be a better approach than what you had in mind.

---

## Pull requests

### Setup

This mod is pure Lua — no build tools or dependencies required beyond Farming Simulator 25 itself.

```
1. Fork the repository
2. Clone your fork
3. Check out the development branch — all work goes there, not main
4. Make your changes
5. Test in-game (see Testing below)
6. Open a PR against development
```

### Coding standards

This mod targets **Lua 5.1** (the FS25 runtime). A few things that will get a PR rejected:

| Don't use | Use instead |
|---|---|
| `goto` / labels | `if/else` or early `return` |
| `continue` | Guard clauses |
| `os.time()` / `os.date()` | `g_currentMission.time` |
| Slider widgets | `MultiTextOption` or stepper buttons |

Other conventions:
- All new files get a header comment block matching the existing style
- Log via `Logger.info()` / `Logger.debug()` / `Logger.warn()` — never bare `print()`
- Prefix all log output with the module name: `Logger.module("MyModule", "message")`
- No file should exceed ~1500 lines — if it's getting long, split it
- No trailing whitespace, no Windows line endings in Lua files

### Testing

Before opening a PR:

- [ ] Load a fresh career save and press F8 — dialog opens cleanly
- [ ] Create at least one trigger of each affected type through the full wizard
- [ ] Activate the trigger in-world via `[E]`
- [ ] Check `log.txt` — zero `[CTC]` errors
- [ ] If you changed XML, test in a fresh game load (not a reload)
- [ ] If you changed serialization, test save → quit → reload

### PR checklist

- [ ] Branch is based on `development`, not `main`
- [ ] Commit messages are clear and describe *why*, not just *what*
- [ ] No debug `print()` statements left in
- [ ] No hardcoded paths or player-specific values
- [ ] PR description explains what changed and why

---

## Project structure

```
FS25_CustomTriggerCreator/
├── main.lua                    Entry point — module loader and lifecycle hooks
├── modDesc.xml                 Mod descriptor — version, actions, l10n
├── gui/                        XML dialog layouts
├── src/
│   ├── core/                   Registry, executor, serializer, world/marker managers
│   ├── gui/                    Dialog Lua controllers
│   ├── hud/                    Notification HUD, map hotspots
│   ├── settings/               CTSettings + game integration
│   ├── triggers/               One file per trigger category
│   └── utils/                  Logger, helpers
├── translations/               l10n strings (EN / DE)
└── docs/                       Developer documentation
```

---

## Questions?

Open a [Discussion](https://github.com/TheCodingDad-TisonK/FS25_CustomTriggerCreator/discussions) or drop into the [Discord](https://discord.gg/Th2pnq36).
