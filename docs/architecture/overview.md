# Architecture overview (Phase 1)

This document records the structural decisions made in Step 1 of the PRD's
implementation workflow (§13) and the reasons for them.

## Components

```text
 Phone: apps/companion (Flutter)          Watch: apps/wear (Flutter)
 ┌───────────────────────────────┐        ┌───────────────────────────────┐
 │ UI (Riverpod + GoRouter)      │        │ UI (Riverpod + GoRouter)      │
 │ CompanionController           │        │ WatchController               │
 │   ping / publish profile      │        │   restore → catch-up → listen │
 ├───────────────────────────────┤        ├───────────────────────────────┤
 │ packages/core (pure Dart)     │        │ packages/core (pure Dart)     │
 │   WatchProfile, validation,   │        │   same code: decode, validate,│
 │   SyncEnvelope, revisions     │        │   decideIncomingProfile       │
 ├───────────────────────────────┤        ├───────────────────────────────┤
 │ packages/platform (plugin)    │        │ packages/platform (plugin)    │
 │   Kotlin → Play services      │◄──────►│   Kotlin → Play services      │
 │   Wearable Data Layer         │  BT /  │   Wearable Data Layer         │
 └───────────────────────────────┘  cloud └───────────────────────────────┘
                                                   FileProfileStore (JSON)
```

The native Watch Face Format face (PRD component C) is Phase 5 and will be a
separate resource-only Gradle module.

## Decisions

### D1. Pub workspace monorepo

The root `pubspec.yaml` declares a Dart pub workspace (Dart 3.6 / Flutter
3.27+). All packages share one lockfile and one `flutter pub get`. No extra
tool (melos) is needed at this size.

### D2. Only the modules with a job today

PRD §4 lists eight packages; §4 also says not to create modules before their
responsibilities are established. Phase 1 has two:

| Package | Responsibility | Why separate |
|---|---|---|
| `core` | Models, JSON, schema versioning, validation, sync protocol | Pure Dart, shared by both apps, fast unit tests |
| `platform` | Kotlin bridge (Data Layer, device info) | Native code shared by both apps through Flutter's plugin mechanism |

Phase 2 added `theme_engine` and `widget_engine` (Flutter, no platform or
Riverpod dependency) so the phone editor can reuse the exact renderer as its
live preview in Phase 3. `widget_engine` depends on `theme_engine`, never the
reverse, which enforces "themes are independent of widget functionality". `communication`, `configuration` and
`data` from the PRD map onto `core` + `platform` for now.

### D3. Native code lives in a Flutter plugin, not a top-level `native/`

A top-level `native/` folder is not part of either app's Gradle build.
Putting the Kotlin bridge in `packages/platform` (a Flutter plugin) means both
apps get the same Kotlin code automatically, registered by Flutter, with the
Dart API next to it. The plugin only translates calls; decisions (what to
sync, validation, revisions) are in Dart (PRD §2.2).

### D4. Same application id on phone and watch

The Wear OS Data Layer only delivers data and messages between apps with the
**same package name and the same signing certificate**. Both apps therefore
use `com.wearstudio.app` (set by `tool/bootstrap.ps1`). They are two APKs
with different `uses-feature` declarations. Release builds must be signed with
the same key.

### D5. Data Layer usage

| Path | Client | Purpose |
|---|---|---|
| `/wear-studio/profile/active` | DataClient (data item) | Active profile, persisted and synced by Play services, delivered on reconnection |
| `/wear-studio/ping`, `/pong` | MessageClient | Liveness and latency test |

Capabilities (`res/values/wear.xml`): `wear_studio_companion` on the phone,
`wear_studio_watch` on the watch, so each side finds the node that has the
other app rather than just any paired device.

Data items are limited to about 100 KB. Wallpapers and other large files
will use Data Layer assets (later phase).

### D6. Revisions make sync idempotent

Every profile is wrapped in a `SyncEnvelope` with a revision from a
monotonic `RevisionClock` on the phone. The watch applies an envelope only if
its revision is newer than the stored one (`decideIncomingProfile`), and only
if it passes `ProfileValidator`. Redelivery after a reconnection, or the
catch-up read at start-up, therefore never duplicates or regresses the
configuration (FR-001 acceptance criteria).

Phase 1 sends the full profile. Incremental updates (§6.3) are planned for the
sync milestone once the editor produces fine-grained changes; the envelope's
`type` field leaves room for a `profilePatch` payload.

### D7. Watch storage

Phase 1 stores one file, `active_profile.json`, written atomically
(write-then-rename). The engine for multiple profiles and assets (Drift or a
file store) will be chosen in Phase 2/3, when there is more than one record.
The phone does not persist profiles yet (Phase 3).

### D8. Coordinates

Positions are the **centre** of the widget, normalized 0.0–1.0 over the
watch's bounding square; sizes are fractions of the side. The validator
rejects values outside range and warns when a widget overflows the screen.

## Platform restrictions recorded so far

- Flutter has no official Wear OS support. It runs as a regular Android app;
  round-screen insets, rotary input and ambient mode need native help or
  community packages. These are evaluated in the feasibility report.
- A Flutter app cannot be the system watch face. The interactive runtime
  (component B) is an app the user opens or sets as a tile/complication target;
  the always-on face is the separate WFF component (Phase 5). The product
  experience across the two must be designed explicitly.
- Data Layer events reach Dart only while the app is running. Background
  delivery needs a `WearableListenerService` (sync milestone). Until then the
  watch catches up from the persisted data item on start.
- Android does not allow third-party apps to bypass lock-screen security
  (FR-007); no such feature will be built.

## Main risks

| Risk | Impact | Mitigation |
|---|---|---|
| Flutter performance/battery on watch hardware | Could force a native watch runtime (PRD §2.3) | Measure in Phase 1 on a real watch; `core` is pure Dart so only the UI would be rewritten |
| Ambient mode / lifecycle in Flutter | Battery drain, burn-in | Evaluate AmbientLifecycleObserver via the plugin |
| Phone/watch id or signing mismatch | Sync silently does nothing | D4, documented in setup |
| Theme names "DedSec"/"JARVIS" are third-party trademarks | Store rejection | Rename before any public release |

## Rendering (Phase 2)

```text
WatchProfile ──► ThemeRegistry.forProfile ──► WatchTheme (+ overrides)
      │                                            │
      └─► resolveLayout(registry, side) ──► [ResolvedWidget rect, settings]
                                                   │
WatchFaceCanvas: background → Positioned(key = widgetId) → WidgetFrame
                 → WatchWidgetDefinition.build(context, WatchWidgetContext)
                                                   ▲
WatchEnvironmentScope (clock, battery, phone link) ┘  supplied by the host app
```

- Widgets read data only from `WatchEnvironment`, so the same widgets run
  on the watch (live data) and in the phone preview (fixed or mirrored data).
- The host owns update frequency: one clock tick and one battery read per
  minute, both stopped when the app is hidden.
- Each widget sits in its own `RepaintBoundary` with a stable key, so one
  widget changing does not repaint or reset the others.
