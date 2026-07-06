import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/core_providers.dart';
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

  ShopPurchaseService(this._ref);

  Future<PurchaseResponse> purchase(String offerId) async {
    final client = _ref.read(apiClientProvider);
    final idempotencyKey = _uuid.v4();
    final data = await client.post(
      '/shop/purchase',
      data: {
        'offer_id': offerId,
        'idempotency_key': idempotencyKey,
      },
    );
    return PurchaseResponse.fromJson(data);
  }
}

final shopPurchaseServiceProvider = Provider<ShopPurchaseService>(
  (ref) => ShopPurchaseService(ref),
);
