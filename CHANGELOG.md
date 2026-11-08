# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-05-08 (local foundation, not yet tagged/released)

### Added
- **ByJTT foundation (reference):** `ByJTT` namespace/brand, compat providers (WoW Forever API fallbacks), schema-versioned SavedVariables (`_schema`/migrations), data-driven buff rule spec + registry, read/plan/apply evaluation engine, secure button pool.
- **All-classes/races/buffs (curated v1):** curated class buff catalog with extensible spec; class/race-aware eligibility. Druid **Mark of the Wild** and **Thorns** preserved as migrated rules.
- **WoW-authentic UX:** onboarding (first run, re-openable), Blizzard-native settings when available (`/fbr config`) with buff toggles, About/Support (placeholder), layout/scale/grow, test/debug.
- **Branding:** “AddonName ByJTT” display name (`WoW Forever Buff Reminder Addon ByJTT`), byjtt.com + GitHub links, Buy Me a Coffee **placeholder** (replace with real URL before release).

### Changed
- Scope expanded from Druid-only to foundation for all classes (curated v1). Legacy v1.0.1 settings migrated (`showMotW`/`showThorns`, position, toggles).
- `/fbr` parity expanded (`config`, `grow`, `onboarding`, legacy `motw`/`thorns` aliases). Bindings/docs updated.
- TOC/Lua/README/AGENTS/llms/DEV/CONTRIBUTING/templates updated to foundation + ByJTT branding/links.

### Safety
- **Taint-safe preserved:** no `OnClick`/`PreClick`/`PostClick` on `SecureActionButtonTemplate`; attribute-only secure casting; protected changes deferred out of combat (`InCombatLockdown`/pending + `PLAYER_REGEN_ENABLED`).

## [1.0.1] - 2026-05-08

### Changed
- Repo moved/renamed to **ByJTT/wow-forever-buff-reminder-addon** for clearer WoW Forever discovery; canonical links updated.
- README rewritten for clarity and discovery (install path, comparison, **AI assistant install instructions**).
- Added minimal AI/agent docs: `llms.txt`, `AGENTS.md`.
- Added `SECURITY.md` and issue template config; improved bug/PR/contributing guidance.

## [1.0.0] - 2026-05-08

### Added
- Minimal Druid buff reminder for WoW Forever: **Mark of the Wild** and **Thorns**.
- Icons appear only when a tracked buff is missing; hidden when fully buffed.
- Secure click-to-cast (`type="spell"` with runtime-resolved spell name/icon; API fallbacks).
- Taint-safe design: no `OnClick`/`PreClick`/`PostClick` handlers on secure buttons.
- Combat-safe behavior (defer secure/visibility-sensitive updates out of combat).
- `/fbr` options: help, lock/unlock, move, motw/thorns toggles, scale, pulse, sound, test, debug, reset, reload.
- Shift-drag repositioning, saved variables, subtle pulse/hint feedback.
- Public repo docs: README, MIT license, contributing guide, issue/PR templates.
