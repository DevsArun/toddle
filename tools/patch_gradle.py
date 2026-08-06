"""Patch the generated Gradle file for Amazon Fire tablets.

What this pins and why:

* namespace / applicationId - must match the Kotlin package declared at the top
  of MainActivity.kt. If they drift apart Android cannot find the activity and
  the app crashes the instant it launches.
* compileSdk 36 - shared_preferences_android requires 36 or later
  and fail with a confusing "requires a higher compileSdk" message.
* ndkVersion 28.2.13676358 - jni, jni_flutter and shared_preferences_android
  now require this version. Android NDK versions are backward compatible, so
  pinning the highest requested version also supports the other dependencies.
* targetSdk 34 - required by the Amazon Appstore.
* minSdk 22 - keeps older Fire HD tablets supported.

It also adds the Amazon Appstore SDK from Maven Central, which provides the
In-App Purchasing API. Amazon publishes it as com.amazon.device:amazon-appstore-sdk
so no jar has to be downloaded by hand any more. android/app/libs stays on the
dependency list as a fallback for anyone who prefers the manual jar.
"""
import re
import sys

path, flavour, app_id = sys.argv[1], sys.argv[2], sys.argv[3]

MARKER = "// toddler-coloring: amazon iap libs"
AMAZON_SDK = "com.amazon.device:amazon-appstore-sdk:3.0.9"
NDK_VERSION = "28.2.13676358"
COMPILE_SDK = "36"
TARGET_SDK = "34"
MIN_SDK = "22"

NAMESPACE_KTS = r'namespace\s*=\s*"[^"]*"'
NAMESPACE_GROOVY = r'namespace\s+"[^"]*"'
REST_OF_LINE = r"[^\n]+"


def pin_ndk(text, kts):
    """Pin ndkVersion, inserting it after the namespace line when missing."""
    if kts:
        line = '    ndkVersion = "' + NDK_VERSION + '"'
        if re.search(r"ndkVersion\s*=", text):
            return re.sub(r"[ \t]*ndkVersion\s*=\s*" + REST_OF_LINE, line, text)
        return re.sub("(" + NAMESPACE_KTS + ")", r"\1" + "\n" + line, text, count=1)
    line = '    ndkVersion "' + NDK_VERSION + '"'
    if re.search(r"ndkVersion\s+", text):
        return re.sub(r"[ \t]*ndkVersion\s+" + REST_OF_LINE, line, text)
    return re.sub("(" + NAMESPACE_GROOVY + ")", r"\1" + "\n" + line, text, count=1)


with open(path, "r", encoding="utf-8") as handle:
    text = handle.read()

if flavour == "kts":
    text = re.sub(NAMESPACE_KTS, 'namespace = "' + app_id + '"', text)
    text = re.sub(r'applicationId\s*=\s*"[^"]*"', 'applicationId = "' + app_id + '"', text)
    text = re.sub(r"compileSdk\s*=\s*" + REST_OF_LINE, "compileSdk = " + COMPILE_SDK, text)
    text = re.sub(r"minSdk\s*=\s*" + REST_OF_LINE, "minSdk = " + MIN_SDK, text)
    text = re.sub(r"targetSdk\s*=\s*" + REST_OF_LINE, "targetSdk = " + TARGET_SDK, text)
    text = pin_ndk(text, True)
    deps = (
        "\n" + MARKER + "\ndependencies {\n"
        '    implementation("' + AMAZON_SDK + '")\n'
        "    // NOTE: no fileTree(libs) here on purpose. The SDK comes from Maven\n"
        "    // Central only; a stray jar in libs/ would cause Duplicate class errors.\n"
        "}\n"
    )
else:
    text = re.sub(NAMESPACE_GROOVY, 'namespace "' + app_id + '"', text)
    text = re.sub(r'applicationId\s+"[^"]*"', 'applicationId "' + app_id + '"', text)
    text = re.sub(r"compileSdkVersion\s+" + REST_OF_LINE, "compileSdkVersion " + COMPILE_SDK, text)
    text = re.sub(r"compileSdk\s+" + REST_OF_LINE, "compileSdk " + COMPILE_SDK, text)
    text = re.sub(r"minSdkVersion\s+" + REST_OF_LINE, "minSdkVersion " + MIN_SDK, text)
    text = re.sub(r"minSdk\s+" + REST_OF_LINE, "minSdk " + MIN_SDK, text)
    text = re.sub(r"targetSdkVersion\s+" + REST_OF_LINE, "targetSdkVersion " + TARGET_SDK, text)
    text = re.sub(r"targetSdk\s+" + REST_OF_LINE, "targetSdk " + TARGET_SDK, text)
    text = pin_ndk(text, False)
    deps = (
        "\n" + MARKER + "\ndependencies {\n"
        "    implementation '" + AMAZON_SDK + "'\n"
        "    // NOTE: no fileTree(libs) here on purpose (avoids Duplicate class errors).\n"
        "}\n"
    )

if MARKER not in text:
    text += deps

with open(path, "w", encoding="utf-8") as handle:
    handle.write(text)

print("patched " + path)
print("  namespace/applicationId : " + app_id)
print("  compileSdk              : " + COMPILE_SDK)
print("  targetSdk               : " + TARGET_SDK)
print("  minSdk                  : " + MIN_SDK)
print("  ndkVersion              : " + NDK_VERSION)
print("  amazon appstore sdk     : " + AMAZON_SDK)
