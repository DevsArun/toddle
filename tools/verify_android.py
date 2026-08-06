"""Fail the build early if the Android wiring is inconsistent.

These three values must agree or the app installs and then crashes instantly
with ClassNotFoundException:

  1. the `package` line in MainActivity.kt
  2. the `namespace` in android/app/build.gradle
  3. the activity name in AndroidManifest.xml

Catching this here is far cheaper than discovering it on a tablet.
"""
import os
import re
import sys

app_id = sys.argv[1]
problems = []

activity = os.path.join(
    "android/app/src/main/kotlin", *app_id.split("."), "MainActivity.kt"
)

if not os.path.exists(activity):
    problems.append(f"MainActivity.kt missing at {activity}")
else:
    with open(activity, encoding="utf-8") as handle:
        source = handle.read()
    match = re.search(r"^package\s+([\w.]+)", source, re.M)
    if not match:
        problems.append("MainActivity.kt has no package declaration")
    elif match.group(1) != app_id:
        problems.append(
            f"MainActivity package '{match.group(1)}' != expected '{app_id}'"
        )

gradle = "android/app/build.gradle.kts"
if not os.path.exists(gradle):
    gradle = "android/app/build.gradle"

with open(gradle, encoding="utf-8") as handle:
    gradle_text = handle.read()

match = re.search(r'namespace\s*=?\s*"([^"]+)"', gradle_text)
if not match:
    problems.append(f"no namespace found in {gradle}")
elif match.group(1) != app_id:
    problems.append(f"gradle namespace '{match.group(1)}' != expected '{app_id}'")

manifest = "android/app/src/main/AndroidManifest.xml"
with open(manifest, encoding="utf-8") as handle:
    manifest_text = handle.read()

if f"{app_id}.MainActivity" not in manifest_text:
    problems.append(f"AndroidManifest.xml does not reference {app_id}.MainActivity")

# The Amazon receiver may only be declared when the class is actually on the
# classpath, otherwise Android throws ClassNotFoundException at install time.
# The class arrives either from Maven Central or from a manually supplied jar.
libs_dir = "android/app/libs"
has_jar = os.path.isdir(libs_dir) and any(
    name.endswith(".jar") for name in os.listdir(libs_dir)
)
has_maven_sdk = "com.amazon.device:amazon-appstore-sdk" in gradle_text

if "com.amazon.device.iap.ResponseReceiver" in manifest_text and not (
    has_maven_sdk or has_jar
):
    problems.append(
        "Amazon receiver is declared but the Appstore SDK is not on the "
        "classpath (no Maven dependency and no jar in android/app/libs)"
    )

# The activity imports com.amazon.device.iap.*, so the SDK must be present and
# the receiver must be declared, or purchases would never come back.
if os.path.exists(activity):
    with open(activity, encoding="utf-8") as handle:
        activity_text = handle.read()
    if "com.amazon.device.iap" in activity_text:
        if not (has_maven_sdk or has_jar):
            problems.append(
                "MainActivity uses the Amazon IAP API but the Appstore SDK is "
                "not on the classpath"
            )
        if "com.amazon.device.iap.ResponseReceiver" not in manifest_text:
            problems.append(
                "MainActivity uses the Amazon IAP API but the ResponseReceiver "
                "is not declared in AndroidManifest.xml, so purchase results "
                "would never arrive"
            )

if problems:
    print("ANDROID WIRING CHECK FAILED")
    for problem in problems:
        print(f"  - {problem}")
    sys.exit(1)

print(f"android wiring OK ({app_id})")
