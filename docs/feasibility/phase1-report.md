# Phase 1 technical feasibility report

PRD §2.3 requires a documented evaluation before committing to Flutter for the
watch runtime. Fill in each row from emulator **and** real-hardware runs.
Emulator results alone are not enough for performance and battery.

| | |
|---|---|
| Date | |
| Flutter version | |
| Watch(es) tested | e.g. Wear OS emulator API 33 round; Galaxy Watch 6 (Wear OS 5) |
| Phone(s) tested | |

## Results

| # | Check (PRD §2.3) | How to test | Result | Notes |
|---|---|---|---|---|
| 1 | Flutter runs on Wear OS | Launch `apps/wear`; cold-start time (`flutter run --profile`, first frame) | ☐ pass ☐ fail | |
| 2 | Circular display | Diagnostics shows `round true`; no content clipped at the edge | ☐ | |
| 3 | Touch interaction | Diagnostics touch test; Ping button; long press; swipe-right back | ☐ | |
| 4 | Lifecycle | Screen off/on, palm cover, app swipe-away, reopen: clock correct, no crash | ☐ | |
| 5 | Performance & memory | DevTools: frame times on main screen, memory after 10 min | ☐ | |
| 6 | Battery | 1 h with app in foreground vs. a native reference app (Battery Historian / `adb shell dumpsys batterystats`) | ☐ | |
| 7 | Bluetooth communication | Ping RTT (median of 10), profile delivery time, delivery after reconnect | ☐ | |
| 8 | Wear OS API access | Data Layer works; ambient mode, rotary input, tiles/complications reachable via plugin | ☐ | |

## Known gaps to evaluate

- **Ambient mode**: Flutter has no built-in ambient support. Evaluate
  `androidx.wear` `AmbientLifecycleObserver` exposed through the platform plugin.
- **Rotary input**: not wired yet; check `MotionEvent` rotary events reach Flutter.
- **Background delivery**: requires `WearableListenerService`.
- **System watch face**: Flutter cannot be the watch face; WFF (Phase 5).

## Decision

☐ Continue with Flutter for the watch runtime
☐ Switch the watch runtime to native Kotlin (Compose for Wear OS), keep Flutter for the phone

Reasoning:
