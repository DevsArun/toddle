#!/usr/bin/env python3
"""Make Flutter's generated Android release build use our private keystore.

The keystore and passwords are supplied only at CI runtime through
android/key.properties. They are never stored in the repository.
"""
from pathlib import Path
import sys

if len(sys.argv) != 3 or sys.argv[2] not in {"kts", "groovy"}:
    raise SystemExit("usage: add_release_signing.py <gradle-file> <kts|groovy>")

path = Path(sys.argv[1])
flavour = sys.argv[2]
text = path.read_text(encoding="utf-8")
marker = "toddler-coloring: release signing"

if marker in text:
    print(f"release signing already configured in {path}")
    raise SystemExit(0)

android_marker = "android {"
if android_marker not in text:
    raise SystemExit("ERROR: android { block not found")

if flavour == "kts":
    # Imports may precede Gradle's plugins block; ordinary declarations may not,
    # so all keystore variables live inside android { }.
    header = "import java.util.Properties\nimport java.io.FileInputStream\n\n"
    signing = '''
    // toddler-coloring: release signing
    val toddlerKeystoreProperties = Properties()
    val toddlerKeystorePropertiesFile = rootProject.file("key.properties")
    if (!toddlerKeystorePropertiesFile.exists()) {
        throw GradleException("Missing android/key.properties for release signing")
    }
    toddlerKeystoreProperties.load(FileInputStream(toddlerKeystorePropertiesFile))

    signingConfigs {
        create("release") {
            keyAlias = toddlerKeystoreProperties["keyAlias"] as String
            keyPassword = toddlerKeystoreProperties["keyPassword"] as String
            storeFile = toddlerKeystoreProperties["storeFile"]?.let { file(it) }
            storePassword = toddlerKeystoreProperties["storePassword"] as String
        }
    }
'''
    text = header + text
    text = text.replace(android_marker, android_marker + signing, 1)
    old = 'signingConfig = signingConfigs.getByName("debug")'
    new = 'signingConfig = signingConfigs.getByName("release")'
    if old not in text:
        raise SystemExit("ERROR: Flutter debug signing line not found in KTS Gradle file")
    text = text.replace(old, new, 1)
else:
    signing = '''
    // toddler-coloring: release signing
    def toddlerKeystoreProperties = new Properties()
    def toddlerKeystorePropertiesFile = rootProject.file('key.properties')
    if (!toddlerKeystorePropertiesFile.exists()) {
        throw new GradleException('Missing android/key.properties for release signing')
    }
    toddlerKeystoreProperties.load(new FileInputStream(toddlerKeystorePropertiesFile))

    signingConfigs {
        release {
            keyAlias toddlerKeystoreProperties['keyAlias']
            keyPassword toddlerKeystoreProperties['keyPassword']
            storeFile toddlerKeystoreProperties['storeFile'] ? file(toddlerKeystoreProperties['storeFile']) : null
            storePassword toddlerKeystoreProperties['storePassword']
        }
    }
'''
    text = text.replace(android_marker, android_marker + signing, 1)
    old = "signingConfig signingConfigs.debug"
    new = "signingConfig signingConfigs.release"
    if old not in text:
        raise SystemExit("ERROR: Flutter debug signing line not found in Groovy Gradle file")
    text = text.replace(old, new, 1)

path.write_text(text, encoding="utf-8")
print(f"release signing configured in {path}")
