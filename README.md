# Forever Buff Reminder

A minimal, taint-safe buff reminder for **Druid** characters on **WoW Forever**.

It shows **Mark of the Wild** and **Thorns** only when they’re missing. Click an icon to cast. When you’re fully buffed, it disappears.

## Why this instead of a heavy aura setup?

| | Forever Buff Reminder | Typical WeakAuras-style setup |
| --- | --- | --- |
| Setup | Install and play | Import/configure auras, fix after patches |
| Visibility | Only appears when something is missing | Often always-on or manually managed |
| Casting | Secure click-to-cast button | Depends on aura/action setup |
| Taint risk | Designed to avoid secure-button taint | Varies by implementation |
| Footprint | One small Lua file | Framework + aura data |

## Install

1. Download/copy the `ForeverBuffReminder` folder into:
   `World of Warcraft/_forever_/Interface/AddOns/`
2. `/reload` in game.
3. If needed, enable **Load out of date AddOns** on the character select AddOns screen.

## Usage

- Missing buffs appear as icons. **Click** an icon to cast.
- **Shift+Drag** an icon to move it.
- Type `/fbr` for options.

Commands:

```text
/fbr                 help
/fbr lock | unlock   lock/unlock position
/fbr move            show icons and unlock for repositioning
/fbr motw | thorns   toggle reminders
/fbr scale <0.6-2.0> icon scale
/fbr pulse           toggle pulse animation
/fbr sound           toggle hint sound
/fbr reset           reset position
/fbr test            show icons for testing
/fbr debug           print status
```

## Notes

- **Druid only** (by design, minimal scope).
- Casting uses secure button attributes (`type=spell`) and resolves spell names at runtime.
- The addon does **not** hook secure `OnClick/PreClick/PostClick` handlers, which helps avoid taint.
- Saved settings live in `ForeverBuffReminderDB` (WoW SavedVariables).

## Troubleshooting

- Icons don’t appear: confirm you’re on a Druid and the buffs are actually missing (`/fbr test` forces display).
- Click does nothing: run `/fbr debug` and include the output in an issue. Enable Lua errors with `/console scriptErrors 1`.
- Wrong position: `/fbr reset`.

## Contributing

Keep changes minimal, taint-safe, and compatible with WoW Forever. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
