# wow-forever-buff-reminder-addon — WoW Forever Buff Reminder Addon ByJTT

> **WoW Forever Buff Reminder Addon ByJTT** · a taint-safe, WoW-authentic missing-buff reminder for **World of Warcraft: Forever**. Data-driven foundation (curated catalog, scales to all classes/races/buffs). Solo dev studio: **ByJTT**.
>
> **Project status / full context (humans + AI):** see [`HANDOFF.md`](HANDOFF.md). Agent rules: [`AGENTS.md`](AGENTS.md).

Shows missing buffs as secure **click-to-cast** icons (only when needed). Includes onboarding and in-game settings (`/fbr config`).

**Keywords (discovery):** WoW Forever addon, World of Warcraft Forever, buff reminder, all classes, click to cast, secure/taint-safe, ByJTT, data-driven, curated catalog, WoW-authentic UI.

## Features

- **All-classes foundation (curated v1)** — data-driven buff engine + curated catalog, scalable to all classes/races/buffs (extensible). Druid Mark/Thorns preserved and migrated from v1 settings.
- **Only when needed** — no permanent frame; icons appear when tracked buffs are missing.
- **One-click cast** — secure spell button with runtime-resolved spell name/icon.
- **Taint-safe** — no `OnClick`/`PreClick`/`PostClick` handlers on secure buttons; protected changes deferred out of combat.
- **WoW-authentic UX** — onboarding (first run), Blizzard-native settings when available (`/fbr config`), tooltips, pulse/sound, drag/lock/scale/grow.
- **ByJTT foundation reference** — minimal deps (1 Lua + TOC + Bindings), schema migrations, diagnostics (`/fbr debug`), and consistent “AddonName ByJTT” branding.

> **Branding/support:** by **ByJTT** · https://byjtt.com · https://github.com/ByJTT · Support (placeholder): https://buymeacoffee.com/ByJTT (set your real Buy Me a Coffee URL before release/marketing)

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

- Click a missing-buff icon to cast/apply it.
- **Shift+Drag** an icon to move (or `/fbr move` then `/fbr lock`).
- Open in-game settings: **`/fbr config`**. Show onboarding: **`/fbr onboarding`**.

```text
/fbr                 help
/fbr config          open settings (WoW UI)
/fbr lock | unlock   lock/unlock position (Shift+Drag moves)
/fbr move            show icons and unlock for repositioning
/fbr scale <0.6-2.0> icon scale
/fbr grow right|down layout direction
/fbr pulse | sound   toggle pulse / hint sound
/fbr form            toggle cancel-form macro mode
/fbr reset           reset position
/fbr test            show missing icons for testing
/fbr debug           print status / catalog state
/fbr onboarding      show onboarding
/fbr rl              reload UI
Legacy (Druid): /fbr motw | /fbr thorns
```

## Scope & foundation

- **v2 foundation (local):** data-driven engine + **curated catalog** for class buffs (scales to all classes/races/buffs; extensible spec/registry). Legacy Druid Mark/Thorns toggles and settings migrate automatically.
- **WoW Forever target:** Interface `16001, 30300` with feature-detected API fallbacks. Buff spell IDs/ranks can vary by client — use `/fbr config` to toggle rules and `/fbr debug` to report issues.
- **Not in scope (yet):** exhaustive “every buff”, weapon enchants/temporary item buffs, user-authored custom buff UI (schema supports future expansion).

| | WoW Forever Buff Reminder Addon ByJTT | Broad buff-reminder addons (typical) |
| --- | --- | --- |
| Goal | Clean, reliable, taint-safe missing-buff reminders (ByJTT foundation) | All-in-one buff/resource reminders |
| Scope | Curated class buffs, extensible engine | Often all cases, pets, ammo/shards, weapon buffs, food, custom buffs |
| Setup | Onboarding + recommended defaults + `/fbr config` | Options panels/profiles/custom rules |
| Click-to-cast | Yes, secure + taint-safe | Varies |
| Footprint | 1 Lua + TOC + Bindings, no libs | Larger (expected) |

## Troubleshooting

- **No icons:** tracked buffs may already be active, none enabled for your class, or rules set off by default. Use `/fbr config`, `/fbr test`, or `/fbr debug`.
- **Click doesn’t cast:** run `/fbr debug` and enable Lua errors (`/console scriptErrors 1`, `/reload`). Check combat/lockdown (actions defer in combat) and spell availability for your class/rank.
- **Position/UI:** `/fbr move`, `/fbr reset`, or `/fbr config`. If upgrading from v1, legacy Druid toggles/position migrate automatically.
- **Report issues:** include WoW Forever build/interface, addon version (`/fbr debug`), steps, expected/actual, and Lua errors. No account data/local personal paths.

## Versioning & releases

- [Semantic Versioning](https://semver.org/) + [Keep a Changelog](https://keepachangelog.com/).
- Releases are tagged `vMAJOR.MINOR.PATCH`. TOC `## Version`, Lua `VERSION`, `CHANGELOG.md`, and the git tag must match.

## Contributing & security

Issues and focused PRs welcome — keep changes minimal and taint-safe. See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).

## ByJTT (studio)

**WoW Forever Buff Reminder Addon ByJTT** is a ByJTT foundation reference addon (solo studio: **ByJTT**).

- Web: https://byjtt.com
- GitHub: https://github.com/ByJTT
- Repo: https://github.com/ByJTT/wow-forever-buff-reminder-addon
- Support (placeholder — set your real URL): https://buymeacoffee.com/ByJTT

## License

[MIT](LICENSE) · by **ByJTT**
