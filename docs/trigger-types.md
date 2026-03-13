# Trigger Types Reference

Every trigger is built through the same 6-step wizard (7 steps for Conditional triggers). This document covers what each type does, what you configure in Step 3, and how it behaves at activation time.

---

## Economy

Money flows in or out of the player's farm account.

### Buy / Sell — `BUY_SELL`

Charges or credits the player a configured amount when activated.

| Config | Description |
|---|---|
| Amount | The value in $ to charge (negative) or credit (positive) |

**Behaviour:** Calls the FS25 finance API. Fails with a WARNING toast if the player doesn't have enough money.

---

### Pay Fee — `PAY_FEE`

Deducts a flat fee from the player's balance.

| Config | Description |
|---|---|
| Amount | Fee in $ — always a deduction |

**Behaviour:** Same as BUY_SELL with a forced negative value. WARNING toast if insufficient funds.

---

### Earn Reward — `EARN`

Pays the player a flat amount.

| Config | Description |
|---|---|
| Amount | Reward in $ |

**Behaviour:** Credits the player's farm account immediately. SUCCESS toast on completion.

---

### Barter — `BARTER`

Trade one thing for another (item → item, money → item, etc.).

| Config | Description |
|---|---|
| Cost | What the player pays ($ amount) |
| Offer | What the player offers (item name) |
| Receive | What the player receives |

**Behaviour:** Checks balance and inventory before completing the exchange.

---

## Interaction

Player-facing interactions — conversations, items, events, animations.

### Talk to NPC — `TALK_NPC`

Displays a dialog message to the player.

| Config | Description |
|---|---|
| Message | The first line of dialog text |
| Body | Optional second line / detail text |

**Behaviour:** Opens a CTConfirmDialog with the configured text. The player dismisses it. No game state change beyond the dialog.

---

### Receive Item — `GIVE_ITEM`

Hands an item to the player.

| Config | Description |
|---|---|
| Item Name | The fill type or item identifier |
| Quantity | How many to give |

**Behaviour:** Calls the item/fill system to add the item to player inventory. Fails with WARNING if inventory is full.

---

### Fire Event — `FIRE_EVENT`

Calls a named Lua function registered by another mod.

| Config | Description |
|---|---|
| Event Name | The key used to register the callback |

**Behaviour:** Looks up `g_CTCSystem.scriptRegistry[eventName]` and calls it. If the key isn't registered, a WARNING toast is shown. See [Developer API](developer-api.md) for how to register callbacks.

---

### Play Animation — `ANIMATION`

Triggers a named world animation.

| Config | Description |
|---|---|
| Animation Name | The animation identifier |

**Behaviour:** Calls the animation system with the configured name.

---

## Notification

Push a HUD toast message. Nothing else happens — these are purely informational.

| Type | Colour | Use case |
|---|---|---|
| `INFO` | Blue | Neutral announcements, process started |
| `SUCCESS` | Green | Something completed successfully |
| `WARNING` | Amber | Something the player should know |
| `ERROR` | Red | Something failed or is blocked |

| Config | Description |
|---|---|
| Message | The notification headline |
| Body | Optional secondary line |

---

## Conditional

Evaluates a condition at activation time. If the condition **passes**, the inner action fires. If it **fails**, a WARNING toast is shown and nothing else happens.

Conditional triggers have an extra wizard step (Step 4) for configuring the gate.

### Time Check — `TIME_CHECK`

Active only within a configured time window.

| Config | Description |
|---|---|
| From Hour | Window start (0–23) |
| To Hour | Window end (0–23) |

Midnight wrapping is supported — a window of `22 → 6` is valid.

---

### Money Check — `MONEY_CHECK`

Passes only if the player's farm balance is at or above a threshold.

| Config | Description |
|---|---|
| Min Balance | Minimum $ required |

---

### Random — `RANDOM`

Fires with a configured probability.

| Config | Description |
|---|---|
| Probability | 0.0–1.0 (0% to 100%) |

Every activation rolls a fresh random value. There is no memory between activations.

---

### Item Check — `ITEM_CHECK`

Gates on whether the player holds a specific item.

| Config | Description |
|---|---|
| Item Name | Fill type or item identifier to check |
| Quantity | Minimum quantity required |

> Full inventory API integration is planned for v1.3.

---

## Chained

Multi-step flows. Each step can show a dialog, wait for confirmation, or fire an action.

### 2-Step — `TWO_STEP`

```
Activate → info notification → confirm dialog → reward / outcome
```

### 3-Step — `THREE_STEP`

```
Activate → notification → confirm → notification → confirm → outcome
```

### Branching — `BRANCHING`

```
Activate → Yes/No dialog → yes path OR no path
```

Each path can have its own outcome configured.

### Timed — `TIMED`

```
Activate → countdown timer (HUD bar) → auto-fires on completion
```

| Config | Description |
|---|---|
| Duration | Countdown length in seconds |

The HUD shows a live progress bar below the notification stack during the countdown.

---

## Custom Script

Advanced types — only available when **Admin Mode** is enabled in Settings.

### Lua Callback — `CALLBACK`

Calls a registered Lua function when activated. Same as FIRE_EVENT but surfaced separately for scripting workflows.

### Event Hook — `EVENT_HOOK`

Subscribes to a named game event via `g_messageCenter`.

| Config | Description |
|---|---|
| Event Key | The MessageType to subscribe to |

### Scheduled — `SCHEDULED`

Runs a callback on a repeating interval.

| Config | Description |
|---|---|
| Delay (sec) | Interval between invocations |

### Conditional Callback — `CONDITIONAL_CB`

Calls a Lua function only if a registered gate function returns true.

| Config | Description |
|---|---|
| Callback Key | The function to call |
| Condition Key | The gate function to evaluate |

---

## Advanced options (all types)

Configured in Step 5 of the wizard.

| Option | Default | Description |
|---|---|---|
| Cooldown | 0 s | Minimum time between activations |
| Repeat Limit | 0 | Max lifetime activations (0 = unlimited) |
| Require Confirm | Off | Show a Yes/No dialog before firing |
