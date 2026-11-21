# Development setup

## 1. Tools

| Tool | Version |
|---|---|
| Flutter | stable, 3.27 or newer (`flutter --version`) |
| Android Studio | current stable, with Android SDK Platform for the API levels below |
| JDK | the one bundled with Android Studio (`flutter doctor` must show no Android issues) |
| Emulator images | Phone: Google Play, API 34+. Watch: Wear OS (Google Play), API 30+ (Wear OS 3+) |

Run `flutter doctor` and fix anything under *Android toolchain* first.

## 2. Bootstrap

```powershell
powershell -ExecutionPolicy Bypass -File tool\bootstrap.ps1
```

What it does: `flutter create` fills in the Gradle wrapper, settings, styles
and icons for `apps/companion`, `apps/wear` and `packages/platform` (your
authored files are backed up and restored), sets the shared application id
`com.wearstudio.app`, sets minSdk, adds the Play services Wearable
dependency, then runs `pub get`, format, analyze, tests and debug builds.

Commit the generated files afterwards. They are now part of the project.

## 3. Pair a phone emulator with a watch emulator

1. In Android Studio → Device Manager, create a **phone** with a Google Play
   image and a **Wear OS** device (round, e.g. *Wear OS Large Round*).
2. Start both.
3. Android Studio → *Tools* → **Wear OS Emulator Pairing Assistant**, pick
   both devices and follow the prompts. It installs the Wear OS companion app
   on the phone if needed.
4. Check pairing: the watch shows the phone as connected, and the Wear OS app
   on the phone shows the watch.

A real watch also works: pair it with your phone normally and enable ADB
debugging over Wi-Fi on the watch (*Developer options*).

## 4. Run both apps

```powershell
flutter devices                         # note both ids
cd apps\wear;      flutter run -d <watch-id>
cd apps\companion; flutter run -d <phone-id>
```

Both must be built from this repo with the same debug key (the default on one
machine), or the Data Layer will not connect them.

## 5. Phase 1 smoke test

1. Phone: the Home card lists the watch. If it says *No watch with Wear
   Studio found*, the watch app is not installed or ids/keys differ.
2. Phone: **Ping watch** → the log shows a round-trip time.
3. Phone: **Send "Minimal"** → the watch shows *Minimal · 2 widgets*.
4. Watch: **Ping phone** → the button shows the round-trip time.
5. Stop the phone app, swipe the watch app away and reopen it → it still shows
   the last profile (offline persistence).
6. Watch: long-press the main screen → diagnostics (device, screen, log,
   touch test). Swipe right to go back.

Record results in [../feasibility/phase1-report.md](../feasibility/phase1-report.md).

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| *Wear OS unavailable* on the phone | Phone image without Google Play, or Wear OS app not installed/paired |
| Watch found in *Connected* but not as a Wear Studio watch | Watch app not installed, or `wear.xml` capability missing |
| Ping sent, no pong | Different application ids or signing keys between the two APKs |
| Profile not updating | Watch app not running: it catches up on next launch (background delivery is a later milestone) |
| Gradle: `minSdk` merger error | Re-run `tool\bootstrap.ps1`; it sets minSdk for the apps and plugin |
