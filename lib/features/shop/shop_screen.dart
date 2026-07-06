import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/shop_models.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/error_snackbar.dart';
import 'shop_provider.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(shopOffersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(shopOffersProvider),
          ),
        ],
      ),
      body: offersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Failed to load offers',
                style: TextStyle(color: AppColors.textPrimary),
              ),
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
                child: Text(
                  'No offers available',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: offers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _ShopOfferCard(offer: offers[index]);
                },
              ),
      ),
    );
  }
}

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
      final service = ref.read(shopPurchaseServiceProvider);
      await service.purchase(widget.offer.offerId);
      if (mounted) {
        showSuccessSnackbar(context, 'Purchase successful!');
        ref.invalidate(shopOffersProvider);
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
            // Item icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            // Name + price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.itemId,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
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
            // Buy button
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
