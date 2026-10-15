import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/api_client.dart';
import '../../core/providers/core_providers.dart';
import '../profile/character_provider.dart';
import '../profile/profile_provider.dart';
import '../../shared/models/iap_models.dart';
import '../../shared/models/shop_models.dart';

final shopOffersProvider = FutureProvider<List<ShopOffer>>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get('/shop/offers');
  final rawList =
      data['offers'] as List<dynamic>? ?? data['data'] as List<dynamic>? ?? [];
  return rawList
      .map((e) => ShopOffer.fromJson(e as Map<String, dynamic>))
      .toList();
});

class ShopPurchaseService {
  final Ref _ref;
  static const _uuid = Uuid();

  // Idempotency key of the unfinished attempt per offer. It outlives the
  // widget and is reused on retry until the server gives a definite answer,
  // so a request that timed out after the server charged cannot charge again.
  final Map<String, String> _pendingKeys = {};

  ShopPurchaseService(this._ref);

  Future<PurchaseResponse> purchase(String offerId) async {
    final idempotencyKey = _pendingKeys.putIfAbsent(offerId, _uuid.v4);
    final client = _ref.read(apiClientProvider);
    try {
      final data = await client.post(
        '/shop/purchase',
        data: {
          'offerId': offerId,
          'idempotencyKey': idempotencyKey,
        },
      );
      final purchase = PurchaseResponse.fromJson(data);
      _pendingKeys.remove(offerId);
      _refreshAfterPurchase(_ref);
      return purchase;
    } on ApiException catch (e) {
      if (e.isRejected) _pendingKeys.remove(offerId);
      rethrow;
    }
  }
}

final shopPurchaseServiceProvider = Provider<ShopPurchaseService>(
  (ref) => ShopPurchaseService(ref),
);

final iapProductsProvider = FutureProvider<List<IAPProduct>>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get('/iap/products');
  final rawList =
      data['products'] as List<dynamic>? ?? data['data'] as List<dynamic>? ?? [];
  return rawList
      .map((e) => IAPProduct.fromJson(e as Map<String, dynamic>))
      .toList();
});

class IAPService {
  final Ref _ref;

  // Mock purchase token of the unfinished attempt per product, reused on retry
  // like a real store token would be, so a timed-out request cannot credit twice.
  final Map<String, String> _pendingMockTokens = {};

  IAPService(this._ref);

  Future<void> verifyReceipt({
    required String productId,
    required String platform,
    required String purchaseToken,
  }) async {
    final client = _ref.read(apiClientProvider);
    await client.post('/iap/verify', data: {
      'productId': productId,
      'platform': platform,
      'purchaseToken': purchaseToken,
    });
    _refreshAfterPurchase(_ref);
  }

  // TODO: Replace with the in_app_purchase plugin; the store then supplies
  // the purchase token and redelivers unfinished purchases.
  Future<void> mockPurchase({
    required String productId,
    required String platform,
  }) async {
    final token = _pendingMockTokens.putIfAbsent(
      productId,
      () => 'mock_token_${DateTime.now().microsecondsSinceEpoch}',
    );
    try {
      await verifyReceipt(
        productId: productId,
        platform: platform,
        purchaseToken: token,
      );
      _pendingMockTokens.remove(productId);
    } on ApiException catch (e) {
      if (e.isRejected) _pendingMockTokens.remove(productId);
      rethrow;
    }
  }
}

final iapServiceProvider = Provider<IAPService>(
  (ref) => IAPService(ref),
);

final shopPurchaseHistoryProvider =
    FutureProvider<List<PurchaseResponse>>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get('/shop/purchases');
  final rawList =
      data['purchases'] as List<dynamic>? ?? data['data'] as List<dynamic>? ?? [];
  return rawList
      .map((e) => PurchaseResponse.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Reloads everything a shop or IAP purchase can change: balance, inventory,
/// owned characters and purchase history. Runs from the services, not the
/// widgets, so it still happens when the player has left the shop.
void _refreshAfterPurchase(Ref ref) {
  ref.read(profileProvider.notifier).fetch(silent: true);
  ref.invalidate(inventoryProvider);
  ref.invalidate(playerCharactersProvider);
  ref.invalidate(shopPurchaseHistoryProvider);
  ref.invalidate(shopOffersProvider);
}
