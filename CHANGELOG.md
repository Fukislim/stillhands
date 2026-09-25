# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-09-25

### Added
- Menu-bar app that locks input with one global shortcut and unlocks with the same shortcut.
- Native menu (one- or two-finger click) with Lock Now, quick toggles, auto-unlock and a Settings window.
- Separate toggles for keyboard (including media keys), clicks & scrolling (including trackpad gestures), and pointer movement.
- Screen stays on and visible while locked; optional "Black out screens".
- Random three-modifier shortcut on first launch, a 🎲 button for a new one, and a recorder that rejects weak or system-reserved combos.
- Safety auto-unlock (off / 5 / 15 / 30 / 60 min, default 30).
- Open at login.
- Purple app icon and README banner built on the Twemoji palm-down hand (CC BY 4.0).
- Eight menu-bar icon styles in two rows, basic (hand, spread hand, padlock, eye) and funky (alien, genie lamp, cat, Eye of Horus), picked in the ✋ menu with side-by-side previews of the unlocked and locked look; the icon is dimmed until Accessibility is granted.
- Releases: every push to `prod` publishes a GitHub Release for the version in `Info.plist` and updates the Homebrew cask.
- Homebrew: `brew install --cask fukislim/tap/stillhands`.
- `make signing`: stable local code signature so Accessibility access survives rebuilds.
- Refuses to lock while a password field (Secure Input) is active.
