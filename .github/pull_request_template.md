## Summary

## Testing (WoW Forever, in game)
- [ ] `/reload` (Lua errors on: `/console scriptErrors 1`)
- [ ] `/fbr config` opens settings; toggles persist
- [ ] `/fbr onboarding` shows; first-run/migration behavior sane
- [ ] `/fbr test` shows missing icons for relevant class
- [ ] Click-to-cast works (secure, taint-safe)
- [ ] Drag (Shift+Drag) / lock / scale / grow / reset work
- [ ] `/fbr debug` output reviewed
- [ ] Combat transitions: no taint/Lua errors; protected changes deferred
- [ ] Legacy v1 migration OK (if schema/settings changed): Druid Mark/Thorns/position preserved

## Safety & foundation
- [ ] Taint-safe: **no** `OnClick`/`PreClick`/`PostClick` on `SecureActionButtonTemplate`; attribute-only casting
- [ ] No protected/secure changes in combat (defer to `PLAYER_REGEN_ENABLED`)
- [ ] No secrets, account data, or local personal paths
- [ ] `CHANGELOG.md` updated (if user-visible); TOC `## Version` + Lua `VERSION`/schema aligned for releases
- [ ] Branding/links correct (ByJTT / byjtt.com / GitHub / support placeholder as applicable)