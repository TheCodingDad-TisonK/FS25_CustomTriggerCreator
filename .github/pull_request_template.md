## What does this PR do?

<!-- One paragraph. What changed and why. -->

## Related issue

<!-- Closes #123 / Fixes #123 / Related to #123 -->

## Type of change

- [ ] Bug fix
- [ ] New trigger type or category
- [ ] UI / dialog change
- [ ] Refactor (no behaviour change)
- [ ] Docs update

## Testing done

- [ ] Loaded a fresh career save — F8 opens the dialog cleanly
- [ ] Created and activated at least one trigger of each affected type
- [ ] Checked `log.txt` — zero `[CTC]` errors
- [ ] Tested save → quit → reload (if serialization was touched)
- [ ] Tested in multiplayer (if relevant)

## Screenshots

<!-- If you changed any UI, attach before/after screenshots. -->

## Checklist

- [ ] Branch targets `development`, not `main`
- [ ] No debug `print()` calls left in
- [ ] No hardcoded paths or player-specific values
- [ ] Lua 5.1 compatible (no `goto`, no `continue`, no `os.time()`)
