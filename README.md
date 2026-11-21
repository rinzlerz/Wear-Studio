# Wear Studio

A modular smartwatch interface platform for Wear OS: a Flutter phone
companion for designing layouts, and a watch runtime that renders them.
The product spec is [`Wear-Studio-PRD.txt`](Wear-Studio-PRD.txt).

**Status: Phase 1 (Technical Feasibility and Foundation).** See
[docs/development/milestones.md](docs/development/milestones.md).

## Repository layout

```text
apps/
  companion/        Flutter phone app (Riverpod, GoRouter)
  wear/             Flutter Wear OS app (Phase 1 proof of concept)
packages/
  core/             Pure Dart: profile models, JSON, schema versions,
                    validation, sync protocol. Shared by both apps.
  platform/         Flutter plugin: Kotlin bridge to the Wear OS Data Layer
                    and device info. No business logic.
docs/
  architecture/     Decisions and how the pieces fit
  development/      Setup, emulator pairing, milestone reports
  feasibility/      Phase 1 feasibility report (fill in from device tests)
tool/
  bootstrap.ps1     Generates Gradle boilerplate and verifies the build
```

The PRD's suggested `native/` folder and the extra packages
(`widget_engine`, `theme_engine`, ...) are intentionally not created yet:
see [docs/architecture/overview.md](docs/architecture/overview.md).

## Quick start (Windows)

Prerequisites: Flutter stable **3.27 or newer** (pub workspaces), Android
Studio with an Android SDK, and a Wear OS emulator image (API 30+).

```powershell
cd Wear-Studio
powershell -ExecutionPolicy Bypass -File tool\bootstrap.ps1
```

The script generates the Android boilerplate from your Flutter SDK, applies
the Wear Studio settings, then runs analysis, tests and debug builds.

Then follow [docs/development/setup.md](docs/development/setup.md) to pair a
phone emulator with a Wear OS emulator and run both apps.

## Common commands

```powershell
flutter pub get                              # repo root (whole workspace)
cd packages/core; dart test; cd ../..        # core unit tests
cd apps/companion; flutter test; cd ../..
cd apps/wear; flutter test; cd ../..
flutter devices                              # find emulator ids
cd apps/companion; flutter run -d <phone-id>
cd apps/wear; flutter run -d <watch-id>
```
