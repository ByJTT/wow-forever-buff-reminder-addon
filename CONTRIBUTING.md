# Contributing - WoW Forever Buff Reminder Addon ByJTT

Thanks for helping improve **WoW Forever Buff Reminder Addon ByJTT** (ByJTT foundation reference for WoW Forever). Keep it **small, reliable, taint-safe, and WoW-authentic**.

## Ground rules

- **Taint-safe (non-negotiable):** NEVER add `OnClick`, `PreClick`, or `PostClick` to `SecureActionButtonTemplate` buttons. Attribute-only secure casting.
- **Combat lockdown:** do not change protected/secure attributes or restricted visibility in combat; defer to `PLAYER_REGEN_ENABLED`/pending.
- **Minimal:** no frameworks/libs (no Ace) unless clearly necessary. Prefer simple Lua, small focused functions, no dead code.
- **Privacy:** no personal data, account data, tokens/secrets, hardcoded local absolute paths, or `WTF`/SavedVariables data in commits/PRs. Public branding links (byjtt.com, GitHub, repo, support placeholder) are OK.
- **Foundation discipline:** preserve data-driven buff spec/registry, schema migrations (additive; never destructively drop unknown keys), `/fbr` + settings parity, WoW Forever API feature-detection/fallbacks, and "AddonName ByJTT" branding.
- **Release sync:** TOC `## Version`, Lua `VERSION`/`SCHEMA` (as applicable), `CHANGELOG.md`, and git tag must match (SemVer).

## Reporting issues

Use issue templates and include:
- WoW client/variant (**WoW Forever**) and interface/build if known
- Addon version + state (`/fbr debug` output)
- Expected vs actual behavior, steps to reproduce
- Lua errors (`/console scriptErrors 1`, then `/reload`)
- No account data/local personal paths

## Pull requests

1. Branch from `main`. Keep PRs focused.
2. Test in game (WoW Forever): `/reload`, `/fbr config`, `/fbr onboarding`, `/fbr test`, click-cast, drag/lock/scale/grow, `/fbr debug`, and combat transitions/defer (no taint/Lua errors). Verify legacy v1 migration if touching schema.
3. Update `CHANGELOG.md` for user-visible changes.

## Local dev

```text
/fbr config     settings UI
/fbr test       show missing icons
/fbr debug      print state/catalog
/fbr onboarding show onboarding
/fbr rl         reload UI
/console scriptErrors 1
```