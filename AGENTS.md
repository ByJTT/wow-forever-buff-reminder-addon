# AGENTS.md — Forever Buff Reminder (ByJTT)

Guidance for AI coding agents and automated contributors.

## Project

- **What:** Minimal WoW Forever Druid buff reminder (Mark of the Wild, Thorns). Click-to-cast, shown only when missing.
- **Files that ship in-game:** `ForeverBuffReminder.toc`, `ForeverBuffReminder.lua` (keep the addon folder name `ForeverBuffReminder`).
- **Repo docs/dev files** (README, LICENSE, CHANGELOG, CONTRIBUTING, `.github/`, `AGENTS.md`, `llms.txt`, `SECURITY.md`) are for source control; not required in `Interface/AddOns`.

## Constraints (do not break)

- **Taint-safe secure buttons:** NEVER add `OnClick`, `PreClick`, or `PostClick` to `SecureActionButtonTemplate` buttons.
- **Combat lockdown:** do not change protected/secure attributes or restricted visibility in combat; defer to `PLAYER_REGEN_ENABLED`.
- **Minimalism:** no frameworks/libs, no unrelated features, no dead code. This is intentionally narrow in scope.
- **Privacy:** no account names, passwords, tokens, local absolute paths, `WTF/`/SavedVariables data, or personal identifiers in commits.

## Changes & releases

- User-visible changes: update `CHANGELOG.md`.
- Releases use SemVer `vMAJOR.MINOR.PATCH`. Keep **TOC `## Version`**, **Lua `VERSION`**, changelog entry, and git tag in sync.
- Test manually: `/reload`, `/fbr test`, click-cast (Mark/Thorns), `/fbr move|lock|scale`, and combat transitions if relevant.

## Install (for AI/user requests)

Target path: `<WoW Forever>/Interface/AddOns/ForeverBuffReminder/ForeverBuffReminder.toc`. Source: https://github.com/ByJTT/wow-forever-buff-reminder-addon
