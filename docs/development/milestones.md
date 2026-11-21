# Milestone reports

Per PRD §13, each milestone ends with this summary.

## Phase 1: Technical feasibility and foundation

### Files created

- Workspace: `pubspec.yaml`, `.gitignore`, `.gitattributes`, `README.md`,
  `tool/bootstrap.ps1`
- `packages/core`: profile/widget models, JSON helpers, schema versioning,
  `ProfileValidator`, `SyncEnvelope`, `RevisionClock`, `PingTracker`,
  `decideIncomingProfile`, sample profiles, 3 test files
- `packages/platform`: Dart API (`DataLayer`, `DeviceInfoSource`) and the
  Kotlin `WearStudioPlatformPlugin`, plus a channel test
- `apps/companion`: Riverpod/GoRouter app, connection controller, Home
  screen, Android manifest, capability, `MainActivity`, widget tests
- `apps/wear`: Riverpod/GoRouter app, watch controller, atomic file store,
  round-safe layout, lifecycle-aware clock, diagnostics screen, Wear
  manifest, capability, `MainActivity`, tests
- Docs: architecture overview, setup, feasibility report template

### Features implemented

- Phone discovers watches with the Wear Studio app (capabilities) and shows
  connection status.
- Ping/pong in both directions with round-trip time.
- Phone publishes a validated profile as a Data Layer item with a revision.
- Watch restores its last profile offline, catches up on start, applies only
  newer valid revisions, persists them atomically.
- Watch shows time/date (configured by the profile's clock settings),
  phone-link state and profile summary on a round-safe layout.
- Diagnostics screen with the values needed for the feasibility report.

### Build status

Written without access to a Flutter SDK, so **not yet compiled or run**.
`tool/bootstrap.ps1` runs analysis, all tests and both debug builds; record
the result here after running it.

### Tests written

- core: JSON parsing of the PRD example, round trips, malformed input, schema
  versions, validation rules, envelope encoding, stale/duplicate/invalid sync
  decisions, revision clock, ping tracker
- platform: channel argument/result mapping, error mapping
- companion: watch listing, empty state, profile publishing, ping answering
- wear: offline restore, catch-up, revision ordering, invalid profile
  rejection, ping answering, main screen rendering

### Known limitations

- Data Layer events are handled only while the app is open.
- Full-profile sync only (no incremental patches yet).
- No widget rendering yet: the watch shows a summary of the profile.
- No ambient mode, rotary input or tiles yet.
- Phone does not persist profiles yet.

### Remaining Phase 1 tasks

1. Run `tool/bootstrap.ps1` and fix anything the SDK reports.
2. Run the smoke test in `setup.md` on paired emulators.
3. Repeat on a real watch and complete `docs/feasibility/phase1-report.md`.
4. Record the Flutter vs. native decision for the watch runtime.

### Result

Built and installed on a Pixel Watch (release, split per ABI: the debug
APK did not fit the watch's free storage). Phone and watch ping each other
in both directions. Feasibility report still to be completed.

## Phase 2: UI rendering engine

### Files created or modified

- `packages/core`: `ThemeOverrides`, schema version 2 with v1→v2 migration,
  override validation, four themed sample profiles, `schema_test.dart`
- `packages/theme_engine` (new): `WatchTheme`, `WidgetSurfaceStyle`, the four
  built-in themes, `ThemeRegistry` (fallback, overrides), `WatchThemeScope`,
  hex colour parsing, tests
- `packages/widget_engine` (new): `WatchWidgetDefinition` contract with
  settings schema and size limits, `WidgetRegistry`, `resolveLayout`,
  `WatchFaceCanvas`, `WidgetFrame`, `WatchEnvironment` + `MinuteClock`, the
  digital clock, battery and system status widgets, unknown-type
  placeholder, tests
- `packages/platform`: `getBatteryStatus` (Kotlin `BatteryManager`) and
  `BatterySource`
- `apps/wear`: renders the active profile with the engine; `WatchEnvironmentHost`
  feeds time/battery/phone link and pauses them when hidden; default layout
  before the first sync; ping moved to diagnostics
- `apps/companion`: one "Send" button per sample profile

### Features implemented

- Registry-based widgets: adding a widget type is a new definition, the
  engine does not change (FR-003).
- Normalized centre/size layout on any screen size, z-order, visibility,
  size clamping to each widget's limits (FR-002 data model).
- Per-widget settings with defaults and invalid-value replacement.
- Theme engine with four themes and user overrides (colours, font scale,
  glow, animation intensity); themes never touch widget code (FR-004).
- Three working widget types (MVP item 5) with live data.
- Unknown widget types render a placeholder instead of breaking the layout.

### Build status

Not yet compiled: run `tool/bootstrap.ps1`.

### Tests written

Theme parsing/fallback/overrides, schema migration, override validation,
registry, settings resolution, layout maths, canvas rendering, theme switch
restyles the same widgets, override colours applied, low-battery colour,
watch default layout, profile switch from the phone.

### Known limitations

- Animations (FR-005) are not implemented; themes only declare a preset.
- No wallpapers/images yet (needs Data Layer assets).
- Widgets are not interactive yet (tap/long-press actions come with the
  widgets that need them in Phase 4).
- Ambient mode still not handled.

### Next: Phase 3, companion editor
