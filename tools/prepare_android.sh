#!/usr/bin/env bash
# Generates the android/ folder and applies the Fire tablet configuration.
#
# The Android shell is generated in a THROWAWAY directory and only the android/
# folder is copied back. Running `flutter create --overwrite .` directly on this
# project would replace lib/main.dart with the Flutter counter demo and wipe the
# dependencies out of pubspec.yaml, which produces an APK that is not this app
# at all.
set -euo pipefail

APP_ID="com.itschool.toddler_coloring"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHELL_DIR="$(mktemp -d)"

cd "$PROJECT_ROOT"

cleanup() { rm -rf "$SHELL_DIR"; }
trap cleanup EXIT

echo "==> Generating a throwaway Android shell in $SHELL_DIR"
flutter create \
  --project-name toddler_coloring \
  --org com.itschool \
  --platforms=android \
  "$SHELL_DIR"

echo "==> Copying only the android/ folder into the project"
rm -rf android
cp -R "$SHELL_DIR/android" ./android

echo "==> Applying the Fire tablet overlay"
# Drop the generated activity so only ours remains.
find android/app/src/main/kotlin -name 'MainActivity.kt' -delete 2>/dev/null || true
find android/app/src/main/java -name 'MainActivity.java' -delete 2>/dev/null || true

mkdir -p android/app/src/main/kotlin/com/itschool/toddler_coloring
cp android_overlay/app/src/main/kotlin/com/itschool/toddler_coloring/MainActivity.kt \
   android/app/src/main/kotlin/com/itschool/toddler_coloring/MainActivity.kt
cp android_overlay/app/src/main/AndroidManifest.xml \
   android/app/src/main/AndroidManifest.xml

# Launcher icons. The generated shell ships Flutter's default icon, so the
# stale mipmap folders are removed first and ours copied in their place.
rm -rf android/app/src/main/res/mipmap-mdpi \
       android/app/src/main/res/mipmap-hdpi \
       android/app/src/main/res/mipmap-xhdpi \
       android/app/src/main/res/mipmap-xxhdpi \
       android/app/src/main/res/mipmap-xxxhdpi \
       android/app/src/main/res/mipmap-anydpi-v26
cp -R android_overlay/app/src/main/res/. android/app/src/main/res/

mkdir -p android/app/libs

echo "==> Appending the Gradle properties overlay"
# Append, never replace: the generated file already carries settings that
# Flutter needs. Our overlay only adds the heap size and AndroidX flags.
printf '\n' >> android/gradle.properties
cat android_overlay/gradle.properties >> android/gradle.properties

chmod +x android/gradlew || true

echo "==> Patching Gradle for old Fire tablets"
if [ -f android/app/build.gradle.kts ]; then
  python3 tools/patch_gradle.py android/app/build.gradle.kts kts "$APP_ID"
else
  python3 tools/patch_gradle.py android/app/build.gradle groovy "$APP_ID"
fi

echo "==> Resulting Gradle configuration (first 80 lines)"
if [ -f android/app/build.gradle.kts ]; then
  head -80 android/app/build.gradle.kts
else
  head -80 android/app/build.gradle
fi

echo "==> Configuring permanent release signing"
if [ -f android/app/build.gradle.kts ]; then
  python3 tools/add_release_signing.py android/app/build.gradle.kts kts
else
  python3 tools/add_release_signing.py android/app/build.gradle groovy
fi

echo "==> Making sure Maven Central is available for the Amazon SDK"
python3 tools/ensure_maven_central.py

# Real Amazon In-App Purchasing, always on.
#
# The Appstore SDK now comes from Maven Central (added by patch_gradle.py), so
# there is no jar to download by hand any more. The real purchase bridge always
# replaces the stub and the Amazon response receiver is always declared.
#
# On a non-Amazon device (phone, emulator, Appetize) the SDK simply reports that
# purchasing is unavailable. Every call in the bridge is wrapped in try/catch,
# so the app still runs perfectly and the free pictures stay playable.
echo "==> Enabling the real Amazon in-app purchase bridge"
cp android_overlay/amazon_iap/AmazonIapBridge.kt \
   android/app/src/main/kotlin/com/itschool/toddler_coloring/MainActivity.kt

# A jar dropped into android_overlay/app/libs/ is still honoured, for anyone who
# prefers the manual SDK download over Maven Central.
if ls android_overlay/app/libs/*.jar >/dev/null 2>&1; then
  echo "==> Also copying a manually supplied Amazon SDK jar"
  cp android_overlay/app/libs/*.jar android/app/libs/
fi

echo "==> Installing the Amazon Appstore public key (required for IAP)"
# Appstore SDK 3.x refuses every purchase unless the app ships the per-app
# public key downloaded from the Developer Console. Without this file the
# reviewer sees "IAP displays error" on a real Fire tablet even though the
# purchase code is correct.
PEM_SRC="store/AppstoreAuthenticationKey.pem"
PEM_DST="android/app/src/main/assets/AppstoreAuthenticationKey.pem"
if [ ! -f "$PEM_SRC" ]; then
  echo "" >&2
  echo "ERROR: $PEM_SRC is missing." >&2
  echo "Amazon IAP cannot work without it. To get it:" >&2
  echo "  1. Open developer.amazon.com console -> your app -> Upcoming Version" >&2
  echo "  2. Open the 'Upload Your App File' screen" >&2
  echo "  3. In 'Additional information' click 'View public key'" >&2
  echo "  4. Download AppstoreAuthenticationKey.pem" >&2
  echo "  5. Put it in the repo at store/AppstoreAuthenticationKey.pem" >&2
  echo "" >&2
  exit 1
fi
if ! grep -q "BEGIN PUBLIC KEY" "$PEM_SRC"; then
  echo "ERROR: $PEM_SRC does not look like a real key (no 'BEGIN PUBLIC KEY' line)." >&2
  echo "Download the real AppstoreAuthenticationKey.pem from the Developer Console." >&2
  exit 1
fi
mkdir -p android/app/src/main/assets
cp "$PEM_SRC" "$PEM_DST"
echo "    public key installed at $PEM_DST"

echo "==> Declaring the Amazon purchase response receiver"
python3 tools/add_iap_receiver.py

echo "==> Verifying the activity class matches the Gradle namespace"
python3 tools/verify_android.py "$APP_ID"

echo "==> Done. Application id: $APP_ID"
