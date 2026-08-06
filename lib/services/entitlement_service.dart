import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Purchase state for the one time \$3.99 full library unlock.
///
/// The Dart side never trusts itself alone: on every launch it asks the native
/// Amazon In-App Purchasing bridge for the current entitlement. When the tablet
/// is offline the last verified answer is reused, so a paying family never
/// loses access on a plane or in the car.
class EntitlementService extends ChangeNotifier {
  EntitlementService._();

  static final EntitlementService instance = EntitlementService._();

  static const MethodChannel _channel =
      MethodChannel('toddler_coloring/iap');

  static const String sku = 'full_library_unlock';
  static const String priceLabel = '\$3.99';

  static const String _keyPremium = 'premium_unlocked';
  static const String _keyVerifiedAt = 'premium_verified_at';

  bool _isPremium = false;
  bool _busy = false;
  String? _lastError;
  String? _lastStatus;

  bool get isPremium => _isPremium;
  bool get busy => _busy;
  String? get lastError => _lastError;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_keyPremium) ?? false;
    notifyListeners();
    // Refresh in the background; failure keeps the cached value.
    unawaited(refresh());
  }

  Future<void> _persist(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPremium, value);
    await prefs.setInt(_keyVerifiedAt, DateTime.now().millisecondsSinceEpoch);
  }

  /// Asks the native side whether this Amazon account owns the unlock.
  Future<void> refresh() async {
    try {
      final bool? owned = await _channel.invokeMethod<bool>('getPurchaseUpdates');
      if (owned == null) return;
      if (owned != _isPremium) {
        _isPremium = owned;
        await _persist(owned);
        notifyListeners();
      } else if (owned) {
        await _persist(true);
      }
    } on MissingPluginException {
      // Running on a plain Android phone, an emulator or Appetize: keep cache.
      debugPrint('IAP bridge unavailable, using cached entitlement.');
    } catch (e) {
      debugPrint('IAP refresh failed: $e');
    }
  }

  /// Starts the Amazon purchase flow. Must only be called behind the
  /// parental gate.
  Future<bool> purchase() async {
    if (_busy) return false;
    _busy = true;
    _lastError = null;
    notifyListeners();

    try {
      final String? status =
          await _channel.invokeMethod<String>('purchase', <String, String>{'sku': sku});
      switch (status) {
        case 'FULFILLED':
          _isPremium = true;
          await _persist(true);
          break;
        case 'ALREADY_PURCHASED':
          _isPremium = true;
          await _persist(true);
          break;
        case 'PENDING':
          _lastError = 'Your purchase is still being confirmed by Amazon.';
          break;
        case 'CANCELLED':
          _lastError = null;
          break;
        case 'INVALID_SKU':
          // Amazon does not know this product for this account. Almost always
          // a store setup issue, never something the parent can fix by
          // retrying, so say so plainly instead of asking them to try again.
          _lastError = 'This app is not set up for purchases yet '
              '(unknown item: $sku). Nothing was charged.';
          break;
        case 'UNAVAILABLE':
          _lastError = 'Amazon purchasing is not ready on this device yet. '
              'Nothing was charged. Please check the tablet is signed in to '
              'an Amazon account and try again in a moment.';
          break;
        case 'FAILED':
          _lastError = 'Amazon could not complete the purchase. '
              'Nothing was charged. Please try again.';
          break;
        default:
          _lastError = 'The purchase could not be completed '
              '(status: ${status ?? 'no response'}). Nothing was charged.';
      }
      _lastStatus = status;
    } on MissingPluginException {
      _lastError =
          'Purchases are only available on Amazon devices from the Appstore.';
    } catch (e) {
      _lastError = 'Something went wrong: $e';
    } finally {
      _busy = false;
      notifyListeners();
    }
    return _isPremium;
  }

  /// Restore for a family that reinstalled or switched Fire tablets.
  Future<bool> restore() async {
    _busy = true;
    notifyListeners();
    await refresh();
    _busy = false;
    if (!_isPremium) {
      _lastError = 'No previous purchase was found on this Amazon account.';
    }
    notifyListeners();
    return _isPremium;
  }

  /// The raw status string Amazon last returned. Shown on the Parents screen
  /// so a support question can be answered without guessing.
  String? get lastStatus => _lastStatus;

  /// Debug only helper so the app can be tested without Amazon services.
  @visibleForTesting
  Future<void> debugSetPremium(bool value) async {
    _isPremium = value;
    await _persist(value);
    notifyListeners();
  }
}
