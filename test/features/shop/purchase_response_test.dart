import 'package:battle_squad_v1/shared/models/shop_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the /shop/purchase response body', () {
    // Shape of shop.ShopPurchase as encoded by the Go API.
    final json = {
      'purchaseId': '9f2c',
      'playerId': 'p1',
      'offerId': 'medkit_x1',
      'priceCurrency': 'coin',
      'priceAmount': 100,
      'quantityGranted': 1,
      'status': 'completed',
      'createdAt': '2026-10-15T08:30:00.123456Z',
    };

    final purchase = PurchaseResponse.fromJson(json);

    expect(purchase.purchaseId, '9f2c');
    expect(purchase.quantityGranted, 1);
    expect(purchase.status, 'completed');
  });
}
