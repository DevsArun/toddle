# Permanent Amazon release signing

Amazon rejected version 1 because Flutter's generated `app-release.apk` was
still signed with Android's shared debug certificate. Version 2 fixes that.

## One-time GitHub setup

Download and safely archive `release-signing-kit.zip`. Never commit any file
from that kit to GitHub. In the repository open **Settings → Secrets and
variables → Actions → New repository secret** and create:

- `SIGNING_KEYSTORE_BASE64`
- `SIGNING_STORE_PASSWORD`
- `SIGNING_KEY_PASSWORD`
- `SIGNING_KEY_ALIAS`

Copy each value from the matching text file in the kit.

## Which artifact goes where

The workflow deliberately creates separate artifacts:

- `AMAZON-UPLOAD-signed-release` — upload its `app-release.apk` to Amazon.
- `APPETIZE-ONLY-debug` — only for Appetize/emulator testing; Amazon will reject it.

Before uploading the release artifact, CI runs Android SDK `apksigner`, checks
that the APK verifies, rejects any certificate containing `Android Debug`, and
includes `certificate-report.txt` beside the APK.

Keep the release kit forever. Every future version of this existing Amazon app
must use the same certificate.
