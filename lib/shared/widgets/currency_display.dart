import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CurrencyDisplay extends StatelessWidget {
  final int coins;
  final int gems;
  const CurrencyDisplay({super.key, required this.coins, required this.gems});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.monetization_on, color: AppColors.coin, size: 18),
        const SizedBox(width: 4),
        Text('$coins', style: const TextStyle(color: AppColors.coin)),
        const SizedBox(width: 12),
        const Icon(Icons.diamond, color: AppColors.gem, size: 18),
        const SizedBox(width: 4),
        Text('$gems', style: const TextStyle(color: AppColors.gem)),
      ],
    );
  }
}
