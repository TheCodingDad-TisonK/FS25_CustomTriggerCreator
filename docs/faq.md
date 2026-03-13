# FAQ

---

### Where do my triggers save?

Triggers are saved to `ctc_data.xml` inside your savegame folder:

```
%USERPROFILE%\Documents\My Games\FarmingSimulator2025\saves\savegame1\ctc_data.xml
```

This file is written on every game save and read when the save loads. You do not need to do anything manually.

---

### Can I back up or share my triggers?

Yes. Use the **Export** button in the management panel. It writes a `ctc_export.xml` file to your savegame folder.

To share: send that file to another player. They use the **Import** button to merge it into their own trigger list.

---

### My triggers disappeared after a game update / mod update

Check whether `ctc_data.xml` still exists in your savegame folder. If it does, your triggers are intact — the mod may have failed to load. Check `log.txt` for `[CTC]` errors.

If the file is gone, use a backup or your `ctc_export.xml` if you exported one.

---

### The mod isn't doing anything when I press F8

Check these in order:

1. Make sure the mod is enabled in the mod manager
2. Load a **career** save — F8 does not work in test maps or the main menu
3. Check `log.txt` for `[CTC]` — you should see startup messages. Any `Error:` lines nearby indicate a load failure
4. Make sure no other dialog is open when pressing F8

---

### Typing in the wizard opens other mod menus (FarmTablet, etc.)

This was a known issue — fixed in **v1.0.5.0**. Update to the latest release.

---

### The trigger activates even when I'm not near it

The world proximity zone defaults to 3 metres. If you activated a trigger via the **RUN** button in the management panel, that bypasses world placement — it fires immediately regardless of position.

---

### Can I edit a trigger after creating it?

Not yet — this is planned for **v1.1**. For now, delete and recreate the trigger.

---

### Can I use this in multiplayer?

Yes, with limitations. Each player's client runs CTC independently. Triggers fire on the activating player's client only. Full multiplayer registry sync (so all players see the same triggers) is planned for **v1.2**.

---

### What does "Admin Mode" unlock?

Admin Mode enables the **Custom Script** trigger category, which exposes Lua callback, event hook, scheduled, and conditional callback trigger types. These require knowledge of Lua and the FS25 API to use meaningfully — hence the admin gate.

Enable it in **Settings → Admin Mode**.

---

### I'm a mod developer. How do I wire into CTC?

See [Developer API](developer-api.md).

---

### How do I report a bug?

[Open a Bug Report issue](https://github.com/TheCodingDad-TisonK/FS25_CustomTriggerCreator/issues/new/choose) — include your `log.txt` output and steps to reproduce.

---

### Does this work with modded maps / third-party maps?

Yes. CTC stores trigger world positions as raw XYZ coordinates — it doesn't depend on map-specific data. Triggers placed on a modded map will load correctly as long as the coordinates resolve on that map.

---

### What are the performance implications of many triggers?

The `CTWorldManager` runs a distance-squared check for each trigger every frame. This is intentionally cheap (no `math.sqrt`, no allocations). 100 triggers in the world adds negligible CPU cost.

The `CTMarkerManager` loads 3D assets asynchronously via `g_i3DManager` — no frame stutter on trigger creation.

---

### Can I disable the floating name labels above triggers?

Not yet via settings. This will be a toggle in a future update. As a workaround, set **Detection Radius** to a very small value so labels only appear when you're right on top of the trigger.
