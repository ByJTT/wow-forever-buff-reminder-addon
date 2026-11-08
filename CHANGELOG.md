# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
