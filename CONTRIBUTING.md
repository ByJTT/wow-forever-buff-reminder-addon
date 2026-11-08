# Contributing

Thanks for helping improve Forever Buff Reminder. The goal is to stay **small, reliable, and taint-safe**.

## Ground rules

- Keep the addon minimal. Avoid adding frameworks/dependencies unless clearly necessary.
- **Do not** add `OnClick`, `PreClick`, or `PostClick` scripts to secure action buttons. Secure casting must remain taint-safe.
- Avoid protected/secure frame changes in combat; defer to `PLAYER_REGEN_ENABLED` when needed.
- No personal data, account data, hardcoded local paths, secrets, or unrelated files in commits/PRs.

## Reporting issues

Please include:

- WoW client/variant (WoW Forever) and interface/build info if known
- Addon version (`/fbr debug` output is helpful)
- What you expected vs. what happened
- Steps to reproduce
- Lua errors (`/console scriptErrors 1`, then `/reload`)

## Pull requests

1. Branch from `main`.
2. Keep PRs focused (one fix/feature).
3. Test in game (`/reload`, `/fbr test`, click-to-cast, move/lock, combat transitions if relevant).
4. Update `CHANGELOG.md` for user-visible changes.

## Local dev

```text
/fbr test   show icons
/fbr debug  print state
/fbr rl     reload UI
```

Code/style: simple Lua, clear names, small functions, no dead code.
