# AGENTS.md

## Project overview
- QuakeNav shows a map that routes users to evacuation sites (not a chosen destination).
- The app reads seismic/relay signals via Firebase to drive evacuation guidance.

## Tech stack
- Flutter
- Firebase
- OpenStreetMap

## How to run
- flutter pub get
- flutter run

## Coding conventions
- Structure: `lib/screens`, `lib/widgets`, `lib/services`, `lib/models`, `lib/utils`
- Files: `lower_snake_case.dart`
- Classes/Widgets: `UpperCamelCase`
- Methods/vars: `lowerCamelCase`
- Keep widget `build` methods focused; split large UI into smaller widgets
- Avoid Firebase calls directly in UI; use service classes in `lib/services`
- Map logic lives in a dedicated service or widget wrapper (no inline map setup in UI)

## Do / Don’t
- Do keep Firebase access centralized.
- Do keep map routing logic centralized.
- Don’t add libraries outside Flutter, Firebase, OpenStreetMap without approval.
