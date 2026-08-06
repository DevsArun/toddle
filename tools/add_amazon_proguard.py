"""Add ProGuard/R8 keep rules for the Amazon Appstore SDK.

Flutter release builds run R8, which renames or strips the Amazon IAP classes.
That breaks purchasing at runtime (and the CI dex check). Amazon's docs require
keeping the whole com.amazon.** tree untouched.

This script:
  1. writes android/app/proguard-rules.pro with the Amazon keep rules
  2. wires proguardFiles into the release buildType of build.gradle(.kts)
"""
import os
import re
import sys

RULES = """# Amazon Appstore SDK (In-App Purchasing) — required keep rules.
# R8 must not rename or remove these classes or IAP breaks at runtime.
-dontwarn com.amazon.**
-keep class com.amazon.** { *; }
-keepattributes *Annotation*
"""

PRO_PATH = "android/app/proguard-rules.pro"

os.makedirs(os.path.dirname(PRO_PATH), exist_ok=True)
existing = ""
if os.path.exists(PRO_PATH):
    with open(PRO_PATH, encoding="utf-8") as handle:
        existing = handle.read()
if "com.amazon." not in existing:
    with open(PRO_PATH, "a", encoding="utf-8") as handle:
        if existing and not existing.endswith("\n"):
            handle.write("\n")
        handle.write(RULES)
    print("wrote Amazon keep rules to " + PRO_PATH)
else:
    print("Amazon keep rules already present in " + PRO_PATH)

gradle = "android/app/build.gradle.kts"
kts = True
if not os.path.exists(gradle):
    gradle = "android/app/build.gradle"
    kts = False

with open(gradle, encoding="utf-8") as handle:
    text = handle.read()

if "proguard-rules.pro" in text:
    print("proguardFiles already wired in " + gradle)
    sys.exit(0)

if kts:
    line = ('            proguardFiles(\n'
            '                getDefaultProguardFile("proguard-android-optimize.txt"),\n'
            '                "proguard-rules.pro",\n'
            '            )\n')
    # insert right after `release {` inside buildTypes
    pattern = r"(buildTypes\s*\{[^{]*release\s*\{\n)"
else:
    line = ("            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'\n")
    pattern = r"(buildTypes\s*\{[^{]*release\s*\{\n)"

new_text, count = re.subn(pattern, r"\1" + line, text, count=1)
if count != 1:
    print("ERROR: could not find release buildType in " + gradle)
    sys.exit(1)

with open(gradle, "w", encoding="utf-8") as handle:
    handle.write(new_text)
print("wired proguardFiles into " + gradle)
