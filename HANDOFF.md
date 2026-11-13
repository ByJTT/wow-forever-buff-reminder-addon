# HANDOFF.md - wow-forever-buff-reminder-addon ByJTT

> **Single-source handoff/status for humans and AI agents.** Read this first to get full context without re-explaining the project. Keep it updated when state/decisions change.
>
> - Repo: `ByJTT/wow-forever-buff-reminder-addon` (public) - https://github.com/ByJTT/wow-forever-buff-reminder-addon
> - Display name (TOC, "AddonName ByJTT"): **WoW Forever Buff Reminder Addon ByJTT**
> - By: **ByJTT** (solo studio) - https://byjtt.com - https://github.com/ByJTT
> - Support (PLACEHOLDER - replace before release/marketing): https://buymeacoffee.com/ByJTT
> - Target: **World of Warcraft: Forever** (Interface `16001, 30300`), feature-detected API fallbacks
> - **In-game folder name must remain `ForeverBuffReminder`** (repo name != install folder name)
> - License: MIT

## Current state (as of 2026-11-08, Windows session -> moving to Mac)

**v2.0.0 foundation baseline is pushed to `origin/main`; additional local polish commits may follow (see git log).** It has **NOT** been fully verified in-game on WoW Forever after the refactor, and the Mac environment may differ.

### What's shipped in code (working baseline intent)
- **Taint-safe secure core (do not break):** `SecureActionButtonTemplate`, attribute-only casting (`type`/`spell`/`macrotext`) with runtime-resolved spell name/icon; **NO** `OnClick`/`PreClick`/`PostClick` on secure buttons; protected/secure attribute or restricted visibility changes **deferred out of combat** (`InCombatLockdown` / `pendingSecure` -> `PLAYER_REGEN_ENABLED`). Read/plan/apply split.
- **ByJTT foundation (reference for future ByJTT WoW addons):** `ByJTT.Brand`/`ByJTT.Addons.ForeverBuffReminder` namespace, compat providers (`pcall`/feature-detect for `C_Spell`/`GetSpellInfo`, `C_UnitAuras`/`UnitAura`/`UnitBuff`, spell-known APIs), schema-versioned SavedVariables (`_schema=2`, additive migrations, **never destructively drop unknown keys**), data-driven buff rule spec + registry (`ns:RegisterBuffPack`), evaluation engine, secure button pool.
- **Curated catalog v1 (scales to all classes/races/buffs; extensible):** class self/maintenance buffs for Warrior/Priest/Mage/Paladin/Hunter/Rogue/Warlock/Shaman/Druid with conservative spell ID sets + name fallbacks and `known` gating. Some situational rules default **off**. **Druid Mark of the Wild (`druid_motw`, 1126) and Thorns (`druid_thorns`, 467) preserved**; legacy `/fbr motw|thorns` aliases kept.
- **Legacy migration (v1.0.1 -> v2):** `showMotW`/`showThorns`/position/toggles/`cancelForm`/etc. migrated; Druid defaults/behavior intended equivalent.
- **WoW-authentic UX:** onboarding (first-run/migration, re-openable), feature-detected Blizzard settings (`Settings`/`InterfaceOptions`) via `/fbr config` with buff toggles + About/Support, tooltips, pulse/sound, drag/lock/scale/grow, `showInCombat` semantics explicit, `/fbr` parity + debug.
- **Branding:** "AddonName ByJTT" style - display/TOC: `WoW Forever Buff Reminder Addon ByJTT`. byjtt.com + GitHub links. Support is a **PLACEHOLDER** URL in TOC/Lua/docs/UI (`https://buymeacoffee.com/ByJTT`) - replace with the real Buy Me a Coffee URL everywhere before release/marketing.
- **Docs/contract updated:** `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `DEV.md`, `CHANGELOG.md` (v2.0.0 noted local/not yet tagged+released), `llms.txt`, `.github/*`. (Bindings.xml not currently shipped.)

### Bug fixed in this session
- `LEARNED_SPELL_IN_TAB` (and shapeshift/talent events) registered via `pcall` to avoid "unknown event" on WoW Forever (`ForeverBuffReminder.lua` event registration).

## In-game files (ship/install)
- `ForeverBuffReminder.toc`, `ForeverBuffReminder.lua` (required). Everything else is repo/docs.
- Install path: `<WoW Forever>/Interface/AddOns/ForeverBuffReminder/ForeverBuffReminder.toc` (folder name **`ForeverBuffReminder`**).

## Key commands (in game)
`/fbr help|config|lock|unlock|move|scale|grow right|down|pulse|sound|form|reset|test|debug|onboarding|rl` (legacy: `motw|thorns`). Enable Lua errors: `/console scriptErrors 1`.

## Verification checklist (do this on Mac/WoW Forever first)
1. `/reload` + `/console scriptErrors 1` - **no Lua errors/taint** (esp. no unknown-event errors).
2. **Druid regression/migration:** Mark/Thorns show only when missing; **secure click-cast works**; hide when covered; `/fbr motw|thorns` + position/scale/toggles preserved from v1 DB. `/fbr debug`.
3. **Multi-class:** `/fbr config` shows curated catalog; on a non-Druid, relevant rules appear; **click-cast** works for known spells (IDs/ranks may need tuning per WoW Forever). Toggle noisy situational rules off.
4. **Combat/lockdown:** in combat, no protected attribute/visibility churn/taint (deferred); after leaving combat refresh applies; casting follows game rules.
5. **UX:** onboarding appears once (re-open via `/fbr onboarding`), `/fbr config` opens (or fallback), drag/lock/scale/grow/pulse/sound/reset/tooltips.
6. **Catalog tuning:** confirm spell IDs/ranks/names for WoW Forever; prefer ID sets + name fallback; gate by `known`; keep situational/short-duration/noisy rules off by default or annotated.

## Open items / next steps (priority)
1. **In-game verification on WoW Forever (Mac):** run the checklist above; fix any client-specific API/event/Settings issues (feature-detect/pcall). Catalog IDs are **best-effort** and likely need tuning from `/fbr debug` + real testing.
2. **Replace Buy Me a Coffee placeholder** `https://buymeacoffee.com/ByJTT` with the real URL in: `ForeverBuffReminder.lua` (`ByJTT.Brand.support`), `ForeverBuffReminder.toc` (`X-ByJTT-Support`), `README.md`, `AGENTS.md`, `llms.txt`, `CHANGELOG.md` notes, and in-game About/onboarding text (and add a "WoW coffee icon" asset only if desired/safe).
3. **Decide SemVer/release when verified:** `v2.0.0` is set (scope/DB schema shift) with migrations - confirm rationale; sync TOC `## Version` + Lua `VERSION`/`SCHEMA` + `CHANGELOG` + git tag `vX.Y.Z` + GitHub release **only when explicitly requested**.
4. **Expand curated catalog carefully:** more classes/races/buffs (stances/forms/paladin auras/weapon imbues are nuanced - weapon/temporary enchants were out of scope), keeping curation + `known` gating + UX clarity. User-authored custom buff UI is future (schema ready).
5. **Template/future addons:** extract a `wow-forever-addon-template` repo under ByJTT (deferred earlier) reusing this foundation contract.

## Architecture anchors (quick)
- `ForeverBuffReminder.lua`: header/brand/ns (`1-33`), compat (`34+`), SV schema+migration (`150+`), buff spec/catalog/registry (`219-338`), engine read/plan (`340+`), secure button+UpdateSecure+apply (taint-safe; search `UpdateSecure`/`pendingSecure`), onboarding, options (feature-detected), events (`967-974`, `pcall` for client variance), slash (`979+`). **Central invariant:** no secure handlers; no protected changes in combat.
- `ForeverBuffReminder.toc`: metadata/version/SV/`X-ByJTT-*`/load order.
- `AGENTS.md`: agent rules (taint, lockdown, privacy, migrations, SemVer sync). `DEV.md`: dev/debug. `llms.txt`: AI/install summary.

## How to work (Mac/local)
```sh
git clone https://github.com/ByJTT/wow-forever-buff-reminder-addon.git ForeverBuffReminder
# place/link as: <WoW Forever>/Interface/AddOns/ForeverBuffReminder/
# edit, then /reload in game; keep taint-safety invariants
git add -A && git commit -m "..." && git push origin main  # only when ready
```
Use `/fbr debug` + `/console scriptErrors 1` for every change. No personal data/local absolute paths/secrets in commits. No Ace/deps unless justified.

## Decisions log (why)
- **"AddonName ByJTT"** display style; in-game folder/`ADDON_NAME` remain `ForeverBuffReminder` for loader stability (repo name SEO-friendly). By = solo studio **ByJTT** (not a personal name in branding).
- **1 Lua + TOC, no libs** for low risk/simple install; foundation pattern lives inside, extractable later.
- **Curated v1, extensible engine** (not "exhaustive every buff now") to balance "all classes/races/buffs long-term" with reliability/UX on WoW Forever.
- **Local-only until verified**; commit/push requested by user to continue on Mac. **Not tagged/released as v2.0.0 on GitHub yet** (CHANGELOG notes local foundation) - tag/release only after verification + real support URL.

## 2026-11-13 (autopilot polish / handoff update)

- Reviewed overnight state and restored broken issue-template YAML drift in git checkouts (kept HEAD templates).
- Buff reminder: kept uncommitted polish (encoding/doc consistency, standalone `/fbr config` fallback dialog, `/fbr lock` clears test-mode) and fixed stale HANDOFF references (Bindings.xml not shipped; handoff reflects ongoing local polish on top of pushed baseline).
- Fishing: retained major uncommitted reliability/UX hardening pass (coalesced refresh + broader event coverage, safer pole/bite/loot heuristics, restored session counters, `/ffish show|hide`, smarter `/ffish cast|lure` behavior, richer debug/options fallback) for commit.
- Leveling guide: initialized git tracking for the addon folder, adding HANDOFF and relative (established-guide-pattern) scaffold/content/polish improvements without real in-game data tuning. 10-60 routes remain scaffolds/WIP pending WoW Forever verification.
- No in-game verification performed in this environment; Buy Me a Coffee URLs remain placeholders; no tags/releases created.
