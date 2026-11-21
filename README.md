# Cool Off

**Check your pulse before you hit send.**

Cool Off is a Flutter app for the moment you're about to send an angry message. You
write (or paste) the message in the app, and a 20-second check with the front camera
reads your pulse and facial expression while you reread it. The result is
🟢 **Calm**, 🟡 **Warm** or 🔴 **Heated**, with the reasons in plain words. Then you
choose: send it, hold it for a while, or take a one-minute cool-down and check again.

It never blocks you. **Send anyway** is on every result.

Built for the DEV.to Presage SmartSpectra SDK Challenge. The entry has two parts that
were built together:

| | |
|---|---|
| **Cool Off** (this repo) | the app |
| **[smartspectra_flutter](https://github.com/waqaralisiyal23/smartspectra_flutter)** | the Flutter plugin for the SmartSpectra SDK that Cool Off runs on, open source and published on [pub.dev](https://pub.dev/packages/smartspectra_flutter) (Android + iOS) |

> ▶️ **Demo video:** https://youtu.be/PWOFyOhhTDs

> For wellness and informational use only. **Not a medical device.** Cool Off does not
> diagnose, treat or monitor any condition.

## How it works

1. **Calibrate once.** A calm 30-second reading sets *your* usual pulse, so every check
   is compared with you, not with an average person.
2. **Write.** Type or paste the message. A small meter warms up live as the text gets
   harsher (CAPS, `!!!`, insults, dismissive phrases like "get out of here",
   "always/never"), all on the phone. Words alone can reach Warm; Heated also needs
   your pulse or face.
3. **Check (~20 s).** The camera measures pulse and expression while the screen asks
   you to reread your message. The first pulse value takes about 12 seconds.
4. **Result.** Three signals are scored and combined:
   | Signal | Source |
   |---|---|
   | Pulse above your usual | SmartSpectra cardio metrics |
   | Anger, contempt, disgust (above your resting face) | SmartSpectra facial expressions |
   | Text heat | On-device heuristics on the message |

   If the pulse can't be read, the result says so and uses the other signals. It never
   invents a value.
5. **Act.**
   - **Send** opens the system share sheet: you pick WhatsApp, SMS, email…
     Cool Off never sends anything itself and never reads other apps.
   - **Hold** parks the message for 10 minutes (configurable) and notifies you when
     it's ready.
   - **Cool down** is a minute with a breathing guide and a **live pulse graph**, then
     an automatic re-check and a before/after card, e.g. *98 → 84 bpm · anger 71 → 12*.

### Learning from you
If you send a message while **Heated**, Cool Off asks the next morning: *"Glad you sent
it?"* 👍 / 👎 (in the app, or right from the notification on Android and iOS). The
answers feed **Insights** (messages cooled off, regretted heated sends, average pulse
drop after a cool-down) and slowly tune how early Cool Off speaks up. Sensitivity can
also be set by hand in Settings.

### Also
- **Android:** share text from any app *into* Cool Off to check it. (iOS needs a Share
  Extension with an App Group, which needs a paid Apple developer account; for now,
  copy and paste.)
- Accessibility: screen-reader labels on the gauges and charts, text up to 2×, and
  reduced-motion support.

## Camera consent and data handling

- **Consent first.** The welcome screens explain what the camera does and what's stored
  before any camera use, and ask for camera permission with an explanation.
- **Camera only during a check** (calibration, check, cool-down), with the preview
  always visible. It stops the moment the app goes to the background (enforced by the
  plugin).
- **Video is processed on the phone** by the SmartSpectra SDK. It is never recorded or
  uploaded.
- **Message text never leaves the phone.** Not to analytics, crash reports, the SDK or
  any server. It is stored only for held messages, plus in check-ins if you turn on
  *Keep message text*.
- **Everything is local:** baseline, check results, held messages and check-in answers
  live in an on-device database in the app's private storage. No accounts, no backend.
  *Settings → Delete all my data* wipes it all and returns to the welcome screen.
- **Network:** the SDK contacts Presage only to validate the API key and load its
  models. SDK telemetry is off and LLM Insights is not used.
- **Firebase:** Crashlytics (crash reports) and Analytics (anonymous usage events from a
  fixed allowlist) are on by default and can each be turned off in Settings. They never
  carry message text, recipients, pulse values, expression scores or results. The
  advertising ID is not collected.

## Built on `smartspectra_flutter`

Cool Off uses the plugin for everything camera-related:

- `SmartSpectra.instance.configure / start / stop` with `cardio` and `expressions`
  metrics, plus the `metrics`, `validation` (hints like "Too dark") and `errors` streams.
- `SmartSpectraPreview(onReady:)` for the round camera view; checks start only once
  frames are flowing.
- `SmartSpectraConfig(dnsFallback: true)` so checks still work on networks whose DNS
  can't resolve Presage's servers.
- The plugin stops the camera when the app is backgrounded, on both platforms.

Plugin: [pub.dev](https://pub.dev/packages/smartspectra_flutter) ·
[source](https://github.com/waqaralisiyal23/smartspectra_flutter)

## Run it yourself

### Requirements
- Flutter 3.47+ (Dart 3.13.5+)
- A **physical device** (the SDK needs a real front camera): Android 9+ (API 28) or
  iOS 17+. iOS builds use Swift Package Manager.
- A Presage SmartSpectra API key: register at
  [physiology.presagetech.com](https://physiology.presagetech.com/auth/register)
- A Firebase project of your own (the repo's Firebase config is not committed)
- Global tools: `dart pub global activate derry` and
  `dart pub global activate flutterfire_cli`

### Setup
```sh
# 1. API key: copy the template and paste your key into secrets.json
cp secrets.example.json secrets.json

# 2. Firebase: generates lib/firebase_options.dart and the platform config files.
#    The app won't compile without them.
flutterfire configure --platforms=android,ios \
  --android-package-name=com.codysseylabs.cooloff \
  --ios-bundle-id=com.codysseylabs.cooloff \
  --out=lib/firebase_options.dart

# 3. Dependencies and generated code (*.g.dart files are not committed)
flutter pub get
derry gen
```
If you use a different app ID, change it in `android/app/build.gradle.kts`
(`applicationId`) and `ios/Flutter/Platform.xcconfig` (`APPLICATION_ID`), and pass the
same ID to `flutterfire configure`. On iOS, set your own signing team in Xcode.

### Run
```sh
flutter run --dart-define=DART_ENV=qa --dart-define-from-file=secrets.json
```
`DART_ENV` is `qa` or `production` (settings in `config/`). VS Code users can pick
*main-qa* / *main-production* from `.vscode/launch.json`.

On iOS 27, debug builds are killed when the debugger detaches; use
`flutter run --profile` on the phone.

If an iOS build fails with *"requires minimum platform version 17.0 … but this target
supports 15.0"*, something ran `flutter pub get` during the build (that resets Flutter's
generated plugin package to iOS 15). VS Code's Dart extension does this automatically;
`.vscode/settings.json` turns that off for this project. Run `flutter pub get` yourself
after editing `pubspec.yaml`.

### Tests
```sh
flutter test
derry check-strict   # format check + analyzer
```
The heat engine, signal collection, auto-tuning, check-in schedule, database and
screen logic are covered without a camera (the measurement source is swappable).

### Demo tools (QA builds only)
*Settings → Demo* has shortcuts for testing and for recording the demo video. They are
hidden in production builds:
- **Check-ins due right away:** the next-morning "Glad you sent it?" shows at once
  (notification a minute later) instead of the next morning.
- **Fill with sample history:** adds two weeks of past checks, cool-downs and check-in
  answers (no message text) so Insights has something to show. *Delete all my data*
  removes it.
- A **1-minute** hold option.

The demo video labels the places where these are used.

### Without a camera
QA builds can replace the camera with a simulated reading, which is handy on an
emulator:
```sh
flutter run --dart-define=DART_ENV=qa --dart-define-from-file=secrets.json \
  --dart-define=SIMULATE_MEASUREMENT=true
```
A "SIMULATED" banner shows while it's on, and *Settings → Demo* switches between a calm
and a heated reading. Production builds ignore the flag.

## Project layout
```
lib/
  engine/     heat engine: pure Dart scoring, text heat, baseline, auto-tune
  stats/      Insights calculations
  services/   measurement (plugin wrapper), records, notifications, sharing, Firebase
  database/   Drift tables and DAOs (offline-first, sync-ready schema)
  pages/      onboarding, calibration, write, check, result, cool-down, held, insights, settings
  widgets/    heat ring, camera orb, beating heart, pulse chart, breathing halo…
tool/icon/    the app icon, drawn in code (see the file header to regenerate)
```
State management is BLoC with `built_value` models. Message text, measurements and
answers are only ever written to the local Drift database.

## License

[MIT](LICENSE)
