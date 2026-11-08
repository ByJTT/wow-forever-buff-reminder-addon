# AGENTS.md — wow-forever-buff-reminder-addon ByJTT (Foundation)

Guidance for AI coding agents and automated contributors.

> **Read [`HANDOFF.md`](HANDOFF.md) first** for full project context, current state, decisions, verification checklist, and open items (kept up to date for humans + agents).

## Project

- **Repo:** `wow-forever-buff-reminder-addon` (ByJTT). **Display name (TOC):** `WoW Forever Buff Reminder Addon ByJTT` (“AddonName ByJTT” style). **By:** ByJTT (solo studio).
- **What:** WoW Forever missing-buff reminder. Secure click-to-cast icons shown only when needed. **ByJTT foundation reference**: data-driven engine + curated buff catalog, scalable to all classes/races/buffs (curated v1, extensible), WoW-authentic UI/UX + onboarding.
- **Target:** World of Warcraft: Forever (Interface 16001, 30300). Feature-detect APIs/fallbacks; verify in-game.
- **In-game install (folder name must remain stable):** `<WoW Forever>/Interface/AddOns/ForeverBuffReminder/ForeverBuffReminder.toc`
- **Files that ship in-game:** `ForeverBuffReminder.toc`, `ForeverBuffReminder.lua`, `Bindings.xml` (required by TOC/loadout as applicable). Repo docs/dev files (`README`, `LICENSE`, `CHANGELOG`, `CONTRIBUTING`, `.github/`, `AGENTS.md`, `HANDOFF.md`, `llms.txt`, `SECURITY.md`, `DEV.md`) are source-control only.
- **Public branding/links (safe to include):** https://byjtt.com · https://github.com/ByJTT · repo https://github.com/ByJTT/wow-forever-buff-reminder-addon · support placeholder https://buymeacoffee.com/ByJTT (replace when real URL is confirmed).

## Constraints (do not break)

- **Taint-safe secure buttons:** NEVER add `OnClick`, `PreClick`, or `PostClick` to `SecureActionButtonTemplate` buttons. Casting is attribute-only (`type`/`spell`/`macrotext`) with runtime-resolved spell name.
- **Combat lockdown:** do not change protected/secure attributes or restricted visibility in combat; defer to `PLAYER_REGEN_ENABLED`/pending. Keep secure mutation isolated.
- **Minimalism + safety:** no frameworks/libs (no Ace) unless clearly necessary and justified; no dead code. No secrets/tokens. No account names, passwords, `WTF`/SavedVariables data, or personal/local absolute paths in commits/public files.
- **Foundation discipline:** preserve data-driven rule spec/registry, SV schema+migrations (never destructively drop unknown keys; migrate legacy `showMotW/showThorns` etc.), `/fbr` slash parity, WoW-authentic settings/onboarding patterns, and `ByJTT` namespace/brand usage as the reference for future addons.

## Changes & releases

- User-visible changes: update `CHANGELOG.md`.
- Releases use SemVer `vMAJOR.MINOR.PATCH`. Keep **TOC `## Version`**, **Lua `VERSION` (+ `SCHEMA` if relevant)**, changelog entry, and git tag in sync. (Local-only unless explicitly asked to push/tag.)
- Test manually (WoW Forever): `/reload`, `/console scriptErrors 1`, `/fbr config` & onboarding, `/fbr test`, click-cast on relevant class buffs, drag/lock/scale/grow, `/fbr debug`, and in-combat defer/no-taint checks. Verify legacy Druid migration (Mark/Thorns toggles/position) when changing schema.

## Install (for AI/user requests)

Target path: `<WoW Forever>/Interface/AddOns/ForeverBuffReminder/ForeverBuffReminder.toc`. Source: https://github.com/ByJTT/wow-forever-buff-reminder-addon