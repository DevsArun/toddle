package com.itschool.toddler_coloring

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Host activity.
 *
 * IMPORTANT: this package name must stay identical to the `namespace` that
 * `flutter create` writes into android/app/build.gradle. A mismatch makes
 * Android fail to find the activity class and the app crashes the instant it
 * is opened.
 *
 * The Dart side always talks to the channel "toddler_coloring/iap".
 * Two implementations exist:
 *
 *  1. This safe stub, used until the Amazon In-App Purchasing SDK jar is added.
 *     It reports "not owned" and "unavailable", which lets the whole app be
 *     built and tested for free on a phone, an emulator or Appetize.
 *
 *  2. AmazonIapBridge, activated by tools/enable_amazon_iap.sh once the Amazon
 *     IAP jar is present in android/app/libs/. That version performs the real
 *     purchase and entitlement checks against the shopper's Amazon account.
 */
class MainActivity : FlutterActivity() {

    private val channelName = "toddler_coloring/iap"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPurchaseUpdates" -> result.success(false)
                    "purchase" -> result.success("UNAVAILABLE")
                    else -> result.notImplemented()
                }
            }
    }
}
