import 'package:battle_squad_v1/core/api/api_client.dart';
import 'package:battle_squad_v1/core/providers/core_providers.dart';
import 'package:battle_squad_v1/features/profile/profile_provider.dart';
import 'package:battle_squad_v1/features/shop/shop_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the idempotency key of each purchase and answers with the next
/// queued outcome (an ApiException to throw, or null for success).
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.outcomes) : super(baseUrl: 'http://test');

  final List<ApiException?> outcomes;
  final List<String> keys = [];
  final List<String> gets = [];

  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParams}) async {
    gets.add(path);
    return {};
  }

  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    keys.add(data!['idempotencyKey'] as String? ?? data['purchaseToken'] as String);
    final outcome = outcomes.removeAt(0);
    if (outcome != null) throw outcome;
    return {
      'purchaseId': 'p-${keys.length}',
      'playerId': 'p1',
      'offerId': data['offerId'],
      'priceCurrency': 'coin',
      'priceAmount': 100,
      'quantityGranted': 1,
      'status': 'completed',
      'createdAt': '2026-10-15T08:30:00Z',
    };
  }
}

const _network = ApiException(code: 'NETWORK_ERROR', message: 'timeout', statusCode: 0);
const _rejected = ApiException(code: 'SHOP_INSUFFICIENT_BALANCE', message: 'poor', statusCode: 400);

void main() {
  ProviderContainer containerWith(_FakeApiClient api) {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    return container;
  }

  ShopPurchaseService serviceWith(_FakeApiClient api) =>
      containerWith(api).read(shopPurchaseServiceProvider);

  test('retry after a network error reuses the key', () async {
    final api = _FakeApiClient([_network, null]);
    final service = serviceWith(api);

    await expectLater(service.purchase('medkit'), throwsA(isA<ApiException>()));
    await service.purchase('medkit');

    expect(api.keys[1], api.keys[0]);
  });

  test('a rejected or successful purchase starts a new key next time', () async {
    final api = _FakeApiClient([_rejected, null, null]);
    final service = serviceWith(api);

    await expectLater(service.purchase('medkit'), throwsA(isA<ApiException>()));
    await service.purchase('medkit');
    await service.purchase('medkit');

    expect(api.keys.toSet().length, 3);
  });

  test('keys are tracked per offer', () async {
    final api = _FakeApiClient([_network, null]);
    final service = serviceWith(api);

    await expectLater(service.purchase('medkit'), throwsA(isA<ApiException>()));
    await service.purchase('shield');

    expect(api.keys[1], isNot(api.keys[0]));
  });

  // No widget is involved: the refresh must not depend on the shop screen
  // still being mounted when the response arrives.
  test('a successful purchase reloads inventory and profile', () async {
    final api = _FakeApiClient([null]);
    final container = containerWith(api);
    container.listen(inventoryProvider, (_, __) {});
    await container.read(inventoryProvider.future);

    await container.read(shopPurchaseServiceProvider).purchase('medkit');
    await container.read(inventoryProvider.future);

    expect(api.gets.where((p) => p == '/player/inventory').length, 2);
    expect(api.gets, contains('/player/profile'));
  });

  test('a failed purchase does not reload', () async {
    final api = _FakeApiClient([_rejected]);
    final container = containerWith(api);

    await expectLater(
      container.read(shopPurchaseServiceProvider).purchase('medkit'),
      throwsA(isA<ApiException>()),
    );

    expect(api.gets, isEmpty);
  });

  test('a verified gem purchase reloads the profile', () async {
    final api = _FakeApiClient([null]);
    final container = containerWith(api);

    await container
        .read(iapServiceProvider)
        .mockPurchase(productId: 'gems_small', platform: 'ios');

    expect(api.gets, contains('/player/profile'));
  });
}
