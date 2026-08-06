#!/usr/bin/env bash
# Switches the app from the safe stub to the real Amazon In-App Purchasing
# bridge, and declares the Amazon response receiver in the manifest.
#
# Run this only after you have downloaded the Amazon In-App Purchasing SDK jar
# from the Amazon Developer Console and placed it in android/app/libs/.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

if [ ! -d android ]; then
  echo "ERROR: android/ not found. Run tools/prepare_android.sh first."
  exit 1
fi

if ! ls android/app/libs/*.jar >/dev/null 2>&1; then
  echo "ERROR: no jar found in android/app/libs/"
  echo "Download the Amazon In-App Purchasing SDK jar first, then re-run."
  exit 1
fi

cp android_overlay/amazon_iap/AmazonIapBridge.kt \
   android/app/src/main/kotlin/com/itschool/toddler_coloring/MainActivity.kt

python3 - <<'PY'
import re

path = "android/app/src/main/AndroidManifest.xml"
with open(path, encoding="utf-8") as handle:
    text = handle.read()

receiver = """
        <receiver
            android:name="com.amazon.device.iap.ResponseReceiver"
            android:permission="com.amazon.inapp.purchasing.Permission.NOTIFY"
            android:exported="true">
            <intent-filter>
                <action android:name="com.amazon.inapp.purchasing.NOTIFY" />
            </intent-filter>
        </receiver>
"""

if "com.amazon.device.iap.ResponseReceiver" in text:
    print("receiver already present")
else:
    text = text.replace("    </application>", receiver + "    </application>", 1)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)
    print("receiver added to AndroidManifest.xml")
PY

python3 tools/add_amazon_proguard.py

python3 tools/verify_android.py com.itschool.toddler_coloring

echo "Amazon IAP bridge enabled. Rebuild the APK to include it."
