# Forever Buff Reminder

> ByJTT — minimal, taint-safe buff reminder for WoW Forever.

A lightweight **Druid** addon for **WoW Forever**. It shows **Mark of the Wild** and **Thorns** only when they’re missing. Click an icon to cast. When you’re covered, it disappears.

## Features

- **Only when needed** — no permanent frame.
- **One-click cast** — secure spell button, runtime-resolved spell name.
- **Taint-safe** — no secure `OnClick`/`PreClick`/`PostClick` handlers.
- **Minimal** — single Lua file, no libraries/dependencies.
- **Small QOL touches** — Shift-drag move, scale, pulse, optional hint sound, `/fbr` controls.

## Install

1. Copy the `ForeverBuffReminder` folder to:
   `World of Warcraft/_forever_/Interface/AddOns/ForeverBuffReminder`
2. Run `/reload` in game.
3. If needed, enable **Load out of date AddOns** at character select.

## Usage

- Click a missing-buff icon to cast it.
- **Shift+Drag** an icon to move.

```text
/fbr                 help
/fbr lock | unlock   lock/unlock position
/fbr move            show icons and unlock for repositioning
/fbr motw | thorns   toggle reminders
/fbr scale <0.6-2.0> icon scale
/fbr pulse           toggle pulse
/fbr sound           toggle hint sound
/fbr reset           reset position
/fbr test            show icons for testing
/fbr debug           print status
```

## Comparison (vs. “Buff Reminder Forever” / similar addons)

Based on the feature set you shared for *Buff Reminder Forever*:

| | Forever Buff Reminder (ByJTT) | Buff Reminder Forever (described) |
| --- | --- | --- |
| Goal | **Minimal, focused, ship-solid** | **Broad, all-in-one reminder suite** |
| Scope | Druid: MotW + Thorns | All classes, pets, ammo, shards, weapon buffs, food, custom buffs |
| Setup | Zero-config | Built-in profiles/options + custom reminders |
| Click-to-cast | Yes, secure/taint-safe | Yes (left/right cast options described) |
| “Any of” / custom buffs | No (intentional) | Yes (commas, Spell ID, `/sid`) |
| Running-out countdown/colors | Simple missing reminder (pulse cue) | Red/yellow/orange states, countdown, low-resource warnings |
| Combat/edge cases | Combat-safe deferral; keeps scope narrow | Combat buff memory, hide in combat/rest/flight/mount options |
| UI | Minimal icon(s) only when missing | Horizontal/vertical, minimap/compartment/options panel |
| Footprint | **1 Lua file, no libs** | Larger feature surface (expected) |

**Bottom line:** if you want *every* buff/pet/resource case covered, a broader addon like Buff Reminder Forever is the right category. If you want the **cleanest, smallest Druid QOL** that nails Mark/Thorns with reliable click-cast and no bloat, this is that.

## Troubleshooting

- No icons: buffs may already be active, or you’re not on a Druid. Use `/fbr test`.
- Click doesn’t cast: run `/fbr debug` and enable Lua errors (`/console scriptErrors 1`, `/reload`). Open an issue with the output.
- Position: `/fbr move` or `/fbr reset`.

## Versioning & releases

This project uses **Semantic Versioning** and a Keep a Changelog changelog.
- Tag releases as `vMAJOR.MINOR.PATCH` (e.g., `v1.0.0`).
- TOC `## Version`, Lua `VERSION`, changelog, and git tag must match for a release.

## Contributing

Issues and focused PRs welcome. Keep changes minimal and taint-safe. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
