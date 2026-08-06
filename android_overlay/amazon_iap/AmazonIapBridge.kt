package com.itschool.toddler_coloring

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.amazon.device.iap.PurchasingListener
import com.amazon.device.iap.PurchasingService
import com.amazon.device.iap.model.FulfillmentResult
import com.amazon.device.iap.model.ProductDataResponse
import com.amazon.device.iap.model.PurchaseResponse
import com.amazon.device.iap.model.PurchaseUpdatesResponse
import com.amazon.device.iap.model.Receipt
import com.amazon.device.iap.model.UserDataResponse
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Amazon In-App Purchasing bridge for the one time full library unlock.
 *
 * Amazon rejected version 1.0.1 because the reviewer saw an error message when
 * tapping the unlock button. This version removes every reason for the app to
 * refuse a purchase on its own:
 *
 *  1. The listener is registered on every lifecycle start, not only once in
 *     onCreate. A single early failure can no longer disable purchasing for
 *     the whole session.
 *  2. `purchase` never short circuits with UNAVAILABLE any more. The request is
 *     always handed to Amazon, and only Amazon's real answer is reported. The
 *     previous build could answer UNAVAILABLE without ever asking the store.
 *  3. Product data is requested at startup, which is what warms up the
 *     purchasing service and confirms the SKU is recognised for this account.
 *  4. Every pending call has a watchdog, so a silent store never leaves the
 *     buy button spinning forever.
 *
 * Two rules are enforced everywhere in this file, because breaking either one
 * takes the whole app down:
 *
 *  1. A MethodChannel result must be replied to EXACTLY once. Replying twice
 *     throws IllegalStateException.
 *  2. A MethodChannel result must never be dropped. A dropped result leaves the
 *     Dart future hanging forever, which looks like a frozen buy button.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val TAG = "ToddlerIap"
        const val CHANNEL = "toddler_coloring/iap"
        const val SKU = "full_library_unlock"

        /** Amazon shows its own dialog, so this only guards against silence. */
        const val PURCHASE_TIMEOUT_MS = 120_000L
        const val UPDATES_TIMEOUT_MS = 20_000L
    }

    private val main = Handler(Looper.getMainLooper())

    private var pendingPurchase: MethodChannel.Result? = null
    private var pendingUpdates: MethodChannel.Result? = null

    private var purchaseWatchdog: Runnable? = null
    private var updatesWatchdog: Runnable? = null

    /** True once the Amazon purchasing service accepted our listener. */
    private var listenerRegistered = false

    /** True once a valid, non-cancelled receipt for our SKU has been seen. */
    private var owned = false

    /** Last raw signal from the store, surfaced for support questions. */
    private var lastProductStatus = "UNKNOWN"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ensureListener()
    }

    override fun onStart() {
        super.onStart()
        // Registering again is safe and repairs a failed first attempt.
        ensureListener()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPurchaseUpdates" -> handleGetPurchaseUpdates(result)
                    "purchase" -> handlePurchase(result)
                    "diagnostics" -> result.success(diagnostics())
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        // Pick up a purchase completed elsewhere, for example on another Fire
        // tablet signed in to the same Amazon account, and warm up the service.
        try {
            PurchasingService.getUserData()
            PurchasingService.getProductData(setOf(SKU))
            PurchasingService.getPurchaseUpdates(false)
        } catch (t: Throwable) {
            Log.w(TAG, "Background entitlement refresh failed.", t)
        }
    }

    override fun onDestroy() {
        // Never leave Dart waiting on a dead activity.
        settlePurchase("CANCELLED")
        settleUpdates(owned)
        main.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    private fun ensureListener() {
        if (listenerRegistered) return
        listenerRegistered = try {
            PurchasingService.registerListener(applicationContext, listener)
            true
        } catch (t: Throwable) {
            Log.i(TAG, "Amazon purchasing service not reachable yet.", t)
            false
        }
    }

    private fun diagnostics(): String =
        "listener=$listenerRegistered product=$lastProductStatus owned=$owned"

    // ---------------------------------------------------------------- calls

    private fun handleGetPurchaseUpdates(result: MethodChannel.Result) {
        ensureListener()
        settleUpdates(owned)
        pendingUpdates = result
        armUpdatesWatchdog()
        try {
            PurchasingService.getPurchaseUpdates(true)
        } catch (t: Throwable) {
            Log.w(TAG, "getPurchaseUpdates failed.", t)
            settleUpdates(owned)
        }
    }

    private fun handlePurchase(result: MethodChannel.Result) {
        ensureListener()

        if (owned) {
            // Already paid for. Never charge a family twice.
            result.success("ALREADY_PURCHASED")
            return
        }

        settlePurchase("CANCELLED")
        pendingPurchase = result
        armPurchaseWatchdog()

        // Always ask Amazon. The app must never decide on its own that
        // purchasing is impossible: that is exactly what failed review.
        try {
            PurchasingService.purchase(SKU)
        } catch (t: Throwable) {
            Log.w(TAG, "purchase failed to start.", t)
            settlePurchase("UNAVAILABLE")
        }
    }

    // --------------------------------------------------------------- replies

    private fun armPurchaseWatchdog() {
        purchaseWatchdog?.let { main.removeCallbacks(it) }
        val task = Runnable {
            if (pendingPurchase != null) {
                Log.w(TAG, "No purchase response from Amazon within timeout.")
                settlePurchase("FAILED")
            }
        }
        purchaseWatchdog = task
        main.postDelayed(task, PURCHASE_TIMEOUT_MS)
    }

    private fun armUpdatesWatchdog() {
        updatesWatchdog?.let { main.removeCallbacks(it) }
        val task = Runnable {
            if (pendingUpdates != null) settleUpdates(owned)
        }
        updatesWatchdog = task
        main.postDelayed(task, UPDATES_TIMEOUT_MS)
    }

    /** Replies to a pending purchase call, at most once. */
    private fun settlePurchase(status: String) {
        purchaseWatchdog?.let { main.removeCallbacks(it) }
        purchaseWatchdog = null
        val target = pendingPurchase ?: return
        pendingPurchase = null
        try {
            target.success(status)
        } catch (t: Throwable) {
            Log.w(TAG, "Could not deliver purchase result.", t)
        }
    }

    /** Replies to a pending entitlement call, at most once. */
    private fun settleUpdates(value: Boolean) {
        updatesWatchdog?.let { main.removeCallbacks(it) }
        updatesWatchdog = null
        val target = pendingUpdates ?: return
        pendingUpdates = null
        try {
            target.success(value)
        } catch (t: Throwable) {
            Log.w(TAG, "Could not deliver entitlement result.", t)
        }
    }

    /**
     * Records ownership and tells Amazon the item was delivered.
     *
     * Fulfilment must be reported or Amazon keeps re-sending the receipt and,
     * for some item types, eventually refunds the customer.
     */
    private fun grant(receipt: Receipt?) {
        if (receipt == null) return
        if (receipt.sku != SKU) return
        if (receipt.isCanceled) return
        owned = true
        try {
            PurchasingService.notifyFulfillment(
                receipt.receiptId,
                FulfillmentResult.FULFILLED
            )
        } catch (t: Throwable) {
            Log.w(TAG, "notifyFulfillment failed.", t)
        }
    }

    // -------------------------------------------------------------- listener

    private val listener = object : PurchasingListener {

        override fun onUserDataResponse(response: UserDataResponse) = Unit

        override fun onProductDataResponse(response: ProductDataResponse) {
            lastProductStatus = try {
                when {
                    response.requestStatus !=
                        ProductDataResponse.RequestStatus.SUCCESSFUL -> "LOOKUP_FAILED"
                    response.productData?.containsKey(SKU) == true -> "AVAILABLE"
                    else -> "NOT_IN_CATALOG"
                }
            } catch (t: Throwable) {
                Log.w(TAG, "Product data handling failed.", t)
                "LOOKUP_FAILED"
            }
            Log.i(TAG, "Product data for $SKU: $lastProductStatus")
        }

        override fun onPurchaseResponse(response: PurchaseResponse) {
            val status = try {
                when (response.requestStatus) {
                    PurchaseResponse.RequestStatus.SUCCESSFUL -> {
                        grant(response.receipt)
                        if (owned) "FULFILLED" else "FAILED"
                    }
                    PurchaseResponse.RequestStatus.ALREADY_PURCHASED -> {
                        owned = true
                        "ALREADY_PURCHASED"
                    }
                    PurchaseResponse.RequestStatus.INVALID_SKU -> "INVALID_SKU"
                    PurchaseResponse.RequestStatus.NOT_SUPPORTED -> "UNAVAILABLE"
                    else -> "FAILED"
                }
            } catch (t: Throwable) {
                Log.w(TAG, "Purchase response handling failed.", t)
                "FAILED"
            }
            Log.i(TAG, "Purchase response: $status")
            settlePurchase(status)
            // A purchase also settles any entitlement question in flight.
            settleUpdates(owned)
        }

        override fun onPurchaseUpdatesResponse(response: PurchaseUpdatesResponse) {
            try {
                if (response.requestStatus ==
                    PurchaseUpdatesResponse.RequestStatus.SUCCESSFUL
                ) {
                    response.receipts?.forEach { grant(it) }
                    if (response.hasMore()) {
                        // More pages of receipts: keep the pending call open.
                        PurchasingService.getPurchaseUpdates(false)
                        return
                    }
                }
            } catch (t: Throwable) {
                Log.w(TAG, "Purchase updates handling failed.", t)
            }
            settleUpdates(owned)
        }
    }
}
