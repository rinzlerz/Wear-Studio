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

### Next: Phase 2, UI rendering engine

Widget registry and contract, positioned widget containers from normalized
coordinates, theme engine, and the first three widgets (clock, battery,
system status).
