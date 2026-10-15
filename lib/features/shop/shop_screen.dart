import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/iap_models.dart';
import '../../shared/models/shop_models.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/error_snackbar.dart';
import 'shop_provider.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shop'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(shopOffersProvider);
                ref.invalidate(iapProductsProvider);
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Items', icon: Icon(Icons.inventory_2_outlined)),
              Tab(text: 'Gems', icon: Icon(Icons.diamond)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ItemsTab(),
            _GemsTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Items tab (existing shop offers)
// ---------------------------------------------------------------------------

class _ItemsTab extends ConsumerWidget {
  const _ItemsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(shopOffersProvider);

    return offersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load offers',
                style: TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(shopOffersProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (offers) => offers.isEmpty
          ? const Center(
              child: Text('No offers available',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: offers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _ShopOfferCard(offer: offers[index]),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gems tab (IAP products)
// ---------------------------------------------------------------------------

class _GemsTab extends ConsumerWidget {
  const _GemsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(iapProductsProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load gem products',
                style: TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(iapProductsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (products) => products.isEmpty
          ? const Center(
              child: Text('No gem products available',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _GemProductCard(product: products[index]),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shop offer card (existing)
// ---------------------------------------------------------------------------

class _ShopOfferCard extends ConsumerStatefulWidget {
  final ShopOffer offer;

  const _ShopOfferCard({required this.offer});

  @override
  ConsumerState<_ShopOfferCard> createState() => _ShopOfferCardState();
}

class _ShopOfferCardState extends ConsumerState<_ShopOfferCard> {
  bool _purchasing = false;

  Future<void> _onBuyTap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirm Purchase',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Buy ${widget.offer.itemId} (x${widget.offer.quantity}) for '
          '${widget.offer.priceAmount} ${widget.offer.priceCurrency}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Buy'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _purchasing = true);
    try {
      await ref.read(shopPurchaseServiceProvider).purchase(widget.offer.offerId);
      if (mounted) {
        showSuccessSnackbar(context, 'Purchase successful!');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Purchase failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final isCoin = offer.priceCurrency.toLowerCase() == 'coin';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: AppColors.textSecondary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.itemId,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    'Qty: ${offer.quantity}${offer.limitPerPlayer != null ? '  •  Limit: ${offer.limitPerPlayer}' : ''}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isCoin ? Icons.monetization_on : Icons.diamond,
                        color: isCoin ? AppColors.coin : AppColors.gem,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${offer.priceAmount} ${offer.priceCurrency}',
                        style: TextStyle(
                          color: isCoin ? AppColors.coin : AppColors.gem,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppButton(
              label: 'Buy',
              loading: _purchasing,
              onPressed: offer.isActive ? _onBuyTap : null,
              icon: Icons.shopping_cart,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gem product card (IAP)
// ---------------------------------------------------------------------------

class _GemProductCard extends ConsumerStatefulWidget {
  final IAPProduct product;

  const _GemProductCard({required this.product});

  @override
  ConsumerState<_GemProductCard> createState() => _GemProductCardState();
}

class _GemProductCardState extends ConsumerState<_GemProductCard> {
  bool _purchasing = false;

  String get _platformName {
    try {
      return Platform.isIOS ? 'ios' : 'android';
    } catch (_) {
      return 'android';
    }
  }

  Future<void> _onBuyTap() async {
    final product = widget.product;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Buy Gems',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.diamond, color: AppColors.gem, size: 48),
            const SizedBox(height: 12),
            Text(
              '${product.gemAmount} Gems',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (product.bonusGemAmount > 0)
              Text(
                '+${product.bonusGemAmount} Bonus!',
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '\$${product.priceUsd.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Buy'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _purchasing = true);
    try {
      await ref.read(iapServiceProvider).mockPurchase(
            productId: product.productId,
            platform: _platformName,
          );

      if (mounted) {
        showSuccessSnackbar(context, 'Gems purchased successfully!');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Purchase failed: $e');
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.gem.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.diamond, color: AppColors.gem, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${product.gemAmount} Gems',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (product.bonusGemAmount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+${product.bonusGemAmount} bonus',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${product.totalGems} gems',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            AppButton(
              label: '\$${product.priceUsd.toStringAsFixed(2)}',
              loading: _purchasing,
              onPressed: product.isActive ? _onBuyTap : null,
              icon: Icons.shopping_cart,
            ),
          ],
        ),
      ),
    );
  }
}
