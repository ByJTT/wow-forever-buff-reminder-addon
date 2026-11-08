# Changelog

All notable changes to this project will be documented in this file.

## [2.1.0] - 2026-05-08

### Fixed
- Click-to-cast reliability by using secure `type="spell"` attributes without taint-prone secure click handlers.
- Visual artifact (“inner square”) by replacing fragile action-bar border art with a clean, client-safe icon skin.

### Added
- Runtime spell name/icon resolution with API fallbacks.
- `/fbr` options: lock/unlock, move, motw/thorns toggles, scale, pulse, sound, test, debug, reset.
- Subtle pulse/sound hint when buffs become missing.
- Public project docs (README, LICENSE, contributing guide, issue templates).

## [1.0.0] - 2026-05-08

### Added
- Initial Druid buff reminder for Mark of the Wild and Thorns on WoW Forever.
