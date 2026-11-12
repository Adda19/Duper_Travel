# AGENTS.md

Dupper (Dupper Travel): a Flutter app to plan trips: trips, places, a wishlist and trip costs.
UI text and domain names are in Spanish (`descripcion`, `montoEstimado`, `fecha`...); keep that.

## Commands
- Test: `flutter test` (must pass before any PR). Tests live in `test/`, one file per unit.
- Dependencies: `flutter pub get`.

## Layout
- `lib/main.dart`, `lib/app.dart`: entry point and app widget.
- `lib/core/`: constants (Hive box names in `app_constants.dart`), theme, utils (providers, backup).
- `lib/features/<feature>/{models,screens,...}`: costs, places, trips, wishlist.

## Conventions
- Storage is Hive. Models are `HiveObject`s with `@HiveType`/`@HiveField`; never reuse or renumber a
  field index. The `*.g.dart` adapters are generated: do not edit them by hand. If a model gains a field,
  add the `@HiveField` with the next free index, update the adapter the same way build_runner would,
  and keep `toJson`/`fromJson` in sync (the backup feature depends on them).
- New JSON fields must be optional in `fromJson` (old backups must still load).
- A good test: plain `flutter_test`, no device or Hive box needed, tests models and pure logic.

## Factory rules
- Phase state lives in `.factory/` as markdown files. Never put plan or review text in code comments.
- Only the paths in SCOPE (factory.conf) may change. Do not touch factory.sh, doctor.sh, .factory-engine/,
  gates/, .claude/, dashboard/, factory.conf or this file.
