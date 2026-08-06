"""Declare the Amazon In-App Purchasing response receiver in the manifest.

Amazon delivers purchase results to the app through a broadcast receiver named
com.amazon.device.iap.ResponseReceiver. If it is not declared, purchases appear
to start and then nothing ever comes back, which looks exactly like a hang.

The class lives inside the Appstore SDK, which is now always on the classpath
(pulled from Maven Central by patch_gradle.py), so declaring the receiver is
always safe. It is only ever used on Amazon devices.

This script is idempotent: running it twice does not add the receiver twice.
"""
import sys

PATH = "android/app/src/main/AndroidManifest.xml"
CLASS_NAME = "com.amazon.device.iap.ResponseReceiver"

RECEIVER = """
        <!-- Amazon In-App Purchasing result receiver. The class ships inside
             the Appstore SDK, which is always on the classpath. -->
        <receiver
            android:name="com.amazon.device.iap.ResponseReceiver"
            android:permission="com.amazon.inapp.purchasing.Permission.NOTIFY"
            android:exported="true">
            <intent-filter>
                <action android:name="com.amazon.inapp.purchasing.NOTIFY" />
            </intent-filter>
        </receiver>
"""

try:
    with open(PATH, "r", encoding="utf-8") as handle:
        text = handle.read()
except FileNotFoundError:
    print("ERROR: " + PATH + " not found. Run prepare_android.sh first.")
    sys.exit(1)

if CLASS_NAME in text:
    print("receiver already declared")
    sys.exit(0)

if "</application>" not in text:
    print("ERROR: no </application> tag found in " + PATH)
    sys.exit(1)

index = text.rindex("</application>")
# Keep whatever indentation the closing tag already uses.
line_start = text.rfind("\n", 0, index) + 1
indent = text[line_start:index]
text = text[:line_start] + RECEIVER.lstrip("\n") + indent + text[index:]

with open(PATH, "w", encoding="utf-8") as handle:
    handle.write(text)

print("receiver declared in " + PATH)
