# Baby Coloring: Toddler Games

An offline, ad-free coloring app for Amazon Fire tablets.
Flutter / Dart. No backend, no accounts, no analytics, no permissions.

- 30 picture packs, 600 pictures
- 30 pictures free
- Full library unlocks with a single $3.99 Amazon In-App Purchase
- Purchase is tied to the shopper's Amazon account and restores on any Fire tablet

---

## Crash fixes applied in this build

The first version of this project had five defects that would each have made
the app fail. All of them are fixed:

1. **The build produced the wrong app.** `flutter create --overwrite .` was run
   inside the project, which replaced `lib/main.dart` with the Flutter counter
   demo and stripped the dependencies out of `pubspec.yaml`. The Android shell
   is now generated in a throwaway directory and only `android/` is copied back.
2. **Instant crash on launch.** The Kotlin package was
   `com.itschool.toddlercoloring` while Gradle's namespace was
   `com.itschool.toddler_coloring`, so Android could not find the activity.
   Everything now uses `com.itschool.toddler_coloring`, and
   `tools/verify_android.py` fails the build if they ever drift apart again.
3. **No Material ancestor.** Screens returned a plain widget instead of a
   Scaffold, so every button and snack bar threw. `PlayfulBackground` now
   provides the Scaffold for every screen.
4. **Install could be blocked.** The manifest declared the Amazon IAP receiver
   and its custom permission even when the SDK was absent. The receiver is now
   added by `tools/add_iap_receiver.py`, and `tools/verify_android.py` refuses
   to build unless the Appstore SDK is genuinely on the classpath.
5. **Misaligned taps and possible overflow.** The canvas measured itself
   outside its card, so touches were offset by the padding, and AspectRatio
   could overflow in landscape. Both are now measured inside the card.

Also hardened: startup is wrapped in try/catch so no single failure blocks the
app, `ErrorWidget.builder` shows a friendly screen instead of a red one, PNG
export is guarded and uses less memory, artwork geometry is cached, and system
font scaling is clamped so layouts cannot overflow.

---

## 1. Put the project on GitHub

1. Create a new **private** repository on GitHub.
2. Unzip this project and drag every file and folder into the repository
   (including the hidden `.github` folder).
3. Commit to the `main` branch.

That is all. There is no Gradle wrapper or binary file to worry about, because
the Android project is generated during the build.

## 2. Get an APK for free

The workflow in `.github/workflows/build-apk.yml` runs automatically on every
push to `main`, and can also be started manually from the **Actions** tab.

It will:

1. install Flutter,
2. run `flutter analyze` and `flutter test`,
3. generate the Android project with `tools/prepare_android.sh`,
4. build a debug APK and an unsigned release APK,
5. upload both as a downloadable artifact called `toddler-coloring-apk`.

Download the artifact from the finished workflow run.

## 3. Test the APK

| Where | What it proves |
| --- | --- |
| Appetize.io / TestMu | UI, coloring, tools, undo, screen sizes |
| Any Android phone | Real touch feel, autosave, offline behaviour |
| Amazon App Tester | In-app purchase responses |
| A real Fire tablet | Fire OS performance and the live purchase flow |

The purchase code cannot be fully verified anywhere except on a device with the
Amazon Appstore. Everything else in the app runs anywhere.

## 4. Turn on real Amazon purchases

On a non-Amazon device (an ordinary phone, an emulator, Appetize) the SDK
reports that purchasing is unavailable, the unlock button says so politely, and
nothing crashes. The 30 free pictures stay fully playable, which is what makes
free testing possible before launch.

In-app purchasing is **already switched on**. There is no jar to download and
no script to run. Amazon publishes the Appstore SDK on Maven Central, so
`tools/patch_gradle.py` adds it as an ordinary Gradle dependency:

```
implementation("com.amazon.device:amazon-appstore-sdk:3.0.9")
```

`tools/prepare_android.sh` then always installs the real purchase bridge and
`tools/add_iap_receiver.py` declares Amazon's response receiver, without which
a purchase starts and never comes back.

The only thing left to do by hand is the store side:

1. Create the app and the IAP product in the Amazon Developer Console.
   - SKU: `full_library_unlock` (must match exactly)
   - Type: **Entitlement** (one time, non-consumable)
   - Price: `$3.99`
2. Build and submit:

   ```bash
   flutter build apk --release
   ```

To try a purchase before going live, install Amazon's free **App Tester** app
on a Fire tablet and load an `amazon.sdktester.json` describing the SKU.

A jar dropped into `android_overlay/app/libs/` is still honoured if you prefer
the manual SDK download, but it is no longer needed.

The Dart side never changes: it always talks to the `toddler_coloring/iap`
channel and caches the last verified entitlement so paying families keep access
while offline.

## 5. Sign the release APK

Amazon requires a signed APK.

```bash
keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

Keep `upload.jks` and its passwords **out of the repository**. Store them as
encrypted GitHub Secrets if you want CI to sign for you. Losing the keystore
means you can never update the app again.

---

## Project layout

```text
lib/
  main.dart                     app entry, orientation, service warm up
  app_theme.dart                colors, palette, touch target sizes
  models/art.dart               region, picture and stroke models
  data/art_library.dart         vector placeholder artwork
  data/catalog.dart             30 categories, 600 pictures, free/paid split
  coloring/canvas_controller.dart  fills, strokes, undo, autosave
  coloring/coloring_painter.dart   canvas and thumbnail painters
  services/entitlement_service.dart  Amazon IAP + offline entitlement cache
  services/drawing_storage.dart      saved artwork + crash-safe autosave
  screens/                      splash, home, category, coloring, drawings,
                                parents, unlock
  widgets/                      squish buttons, cards, background, gate
android_overlay/                Fire tablet manifest, activity, IAP bridge
tools/                          Android generation and IAP activation scripts
test/                           catalog, artwork and canvas logic tests
```

## Replacing the placeholder artwork

Every picture is drawn from geometry in `lib/data/art_library.dart`, in a
1000 x 1000 space. Add a new builder, register it in `ArtLibrary.builders`, and
it becomes available to the catalog immediately. Because the artwork is vector
rather than bitmap, it is razor sharp on every Fire tablet and costs almost no
memory, which matters on 1 GB devices.

## Design and safety rules baked in

- Minimum touch target of 72 dp everywhere.
- Undo history capped at 20 steps so RAM stays flat.
- Autosave every 700 ms after an edit; a crash never loses a drawing.
- Parental gate before purchase, before restore and before deleting artwork.
- No ads, no external links, no analytics, no permissions in the manifest.

## Artwork in this build (v3)

All 600 pages are 600 DIFFERENT drawings. Nothing is repeated anywhere.

See ARTWORK.md for how the pictures are stored and how to regenerate them.

## Gradle fixes applied in this build (v3)

The first build that produced an APK was compiling the Flutter counter demo,
not this app: the old prepare script ran `flutter create --overwrite .` inside
the project root, which replaced lib/main.dart and stripped the plugins out of
pubspec.yaml. With zero plugins Gradle had almost nothing to do, so it passed.

Now that the real project is compiled with its two native plugins, the Android
configuration has to be pinned properly:

| Setting | Value | Why |
| --- | --- | --- |
| compileSdk | 36 | modern plugins refuse to build below this |
| ndkVersion | 27.0.12077973 | stops the "requires Android NDK" failure |
| targetSdk | 34 | Amazon Appstore requirement |
| minSdk | 22 | older Fire HD tablets |
| Gradle heap | 4 GB | the runner default is too small |
| useAndroidX / Jetifier | true | required by every modern plugin |

The workflow also builds with `--stacktrace` and, if a build fails, prints the
generated Gradle files and `flutter doctor -v` so the real cause is visible in
the log instead of a generic message.
