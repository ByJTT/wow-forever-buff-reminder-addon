# Forever Buff Reminder Addon (WoW Forever)

> **ByJTT** · Minimal, taint-safe Druid buff reminder for **World of Warcraft: Forever**.

A lightweight addon that shows **Mark of the Wild** and **Thorns** only when they’re missing. **Click an icon to cast.** When you’re covered, it disappears.

**Keywords (discovery):** WoW Forever addon, World of Warcraft Forever, Druid buff reminder, Mark of the Wild, Thorns, click to cast, secure/taint-safe, minimal addon.

## Features

- **Only when needed** — no permanent frame.
- **One-click cast** — secure spell button with runtime-resolved spell name.
- **Taint-safe** — no `OnClick`/`PreClick`/`PostClick` handlers on secure buttons.
- **Minimal** — 1 Lua file + TOC, no libraries/dependencies.
- **QOL** — Shift-drag move, scale, pulse, optional hint sound, `/fbr` controls.

## Install (manual)

1. Download or clone this repository.
2. Place the addon so the final path is exactly:
   ```text
   <WoW Forever>\Interface\AddOns\ForeverBuffReminder\ForeverBuffReminder.toc
   ```
   **Important:** the in-game addon folder must be named **`ForeverBuffReminder`** (the folder containing `ForeverBuffReminder.toc`), even if the GitHub repo is named `wow-forever-buff-reminder-addon`.
3. `/reload` in game.
4. If needed, enable **Load out of date AddOns** at character select.

## For AI assistants / automation (install request)

If a user asks an AI to “install the Forever Buff Reminder addon for WoW Forever”:

1. Locate the WoW Forever install’s `Interface\AddOns\` directory.
2. Create/copy a folder named **`ForeverBuffReminder`** containing `ForeverBuffReminder.toc` and `ForeverBuffReminder.lua` from this repo.
3. Verify `ForeverBuffReminder.toc` exists at the path above. Tell the user to `/reload`.
4. Do **not** copy repo-only docs/dev files into the AddOns folder unless desired; only the TOC/Lua are required.

Source: https://github.com/ByJTT/wow-forever-buff-reminder-addon

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
/fbr rl              reload UI
```

## Comparison (vs. broad “Buff Reminder”-style addons)

This project is intentionally **minimal and focused**.

| | Forever Buff Reminder (ByJTT) | Broad buff-reminder addons (typical) |
| --- | --- | --- |
| Goal | Clean, reliable Druid Mark/Thorns QOL | All-in-one buff/resource reminders |
| Scope | Druid: MotW + Thorns | Often all classes, pets, ammo/shards, weapon buffs, food, custom buffs |
| Setup | Zero-config | Options panels/profiles/custom rules |
| Click-to-cast | Yes, secure + taint-safe | Varies by addon |
| Extra states | Missing reminder (subtle pulse) | Often expiring countdowns, low-resource warnings, hide contexts |
| Footprint | 1 Lua file, no libs | Larger (expected) |

**When to choose this:** you want the smallest addon that reliably solves Mark/Thorns for WoW Forever. **When to choose a broader addon:** you need multi-class/custom buff/resource/expiry coverage.

## Troubleshooting

- **No icons:** buffs may already be active, or you’re not on a Druid. Use `/fbr test`.
- **Click doesn’t cast:** run `/fbr debug` and enable Lua errors (`/console scriptErrors 1`, `/reload`). Open an issue with the output.
- **Position/UI:** `/fbr move` or `/fbr reset`.

## Versioning & releases

- [Semantic Versioning](https://semver.org/) + [Keep a Changelog](https://keepachangelog.com/).
- Releases are tagged `vMAJOR.MINOR.PATCH`. TOC `## Version`, Lua `VERSION`, `CHANGELOG.md`, and the git tag must match.

## Contributing & security

Issues and focused PRs welcome — keep changes minimal and taint-safe. See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) · ByJTT
