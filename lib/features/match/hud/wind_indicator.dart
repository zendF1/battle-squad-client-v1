import 'package:battle_squad_v1/core/theme/app_theme.dart';
import 'package:battle_squad_v1/shared/models/match_models.dart';
import 'package:flutter/material.dart';

class WindIndicator extends StatelessWidget {
  final WindState wind;

  const WindIndicator({super.key, required this.wind});

  @override
  Widget build(BuildContext context) {
    final isLeft = wind.direction < 0;
    final arrowIcon = isLeft ? Icons.arrow_back : Icons.arrow_forward;
    final dirLabel = wind.power == 0 ? '—' : (isLeft ? '←' : '→');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Wind',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          if (wind.power == 0)
            const Text(
              '—',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            )
          else ...[
            Icon(arrowIcon, color: AppColors.accent, size: 16),
            const SizedBox(width: 4),
            Text(
              '${wind.power}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          // Accessible text fallback
          Semantics(
            label: 'Wind: $dirLabel ${wind.power}',
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
