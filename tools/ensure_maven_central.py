"""Make sure Gradle can reach Maven Central.

The Amazon Appstore SDK (com.amazon.device:amazon-appstore-sdk) is published on
Maven Central. Flutter's generated Android project normally already declares
mavenCentral(), but the exact file and syntax have changed between Flutter
versions. Rather than assume, this script checks every place a repository can
be declared and adds mavenCentral() only where it is genuinely missing.

Without this the build fails with a confusing
"Could not find com.amazon.device:amazon-appstore-sdk" message.
"""
import os
import re

CANDIDATES = [
    "android/settings.gradle.kts",
    "android/settings.gradle",
    "android/build.gradle.kts",
    "android/build.gradle",
]

found_anywhere = False
report = []

for path in CANDIDATES:
    if not os.path.exists(path):
        continue
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()
    if "mavenCentral()" in text:
        found_anywhere = True
        report.append("  ok      : " + path + " already has mavenCentral()")
        continue

    # Add mavenCentral() right after any google() inside a repositories block.
    if re.search(r"repositories\s*\{", text) and "google()" in text:
        new_text, count = re.subn(
            r"([ \t]*)google\(\)",
            lambda m: m.group(0) + "\n" + m.group(1) + "mavenCentral()",
            text,
        )
        if count:
            with open(path, "w", encoding="utf-8") as handle:
                handle.write(new_text)
            found_anywhere = True
            report.append(
                "  patched : " + path + " (added mavenCentral() x" + str(count) + ")"
            )
            continue
    report.append("  skipped : " + path + " (no repositories block to patch)")

for line in report:
    print(line)

if not found_anywhere:
    print("ERROR: mavenCentral() is not declared anywhere in the Android project.")
    print("The Amazon Appstore SDK could not be resolved from Maven Central.")
    raise SystemExit(1)

print("maven central available")
