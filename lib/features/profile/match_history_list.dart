import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/player_models.dart';

class MatchHistoryList extends StatelessWidget {
  final List<MatchHistoryEntry> entries;

  const MatchHistoryList({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No match history yet',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _MatchHistoryCard(entry: entries[index]);
      },
    );
  }
}

class _MatchHistoryCard extends StatelessWidget {
  final MatchHistoryEntry entry;

  const _MatchHistoryCard({required this.entry});

  Color get _resultColor {
    return switch (entry.result.toUpperCase()) {
      'W' || 'WIN' => AppColors.success,
      'L' || 'LOSS' => AppColors.error,
      _ => AppColors.warning,
    };
  }

  String get _resultLabel {
    return switch (entry.result.toUpperCase()) {
      'W' || 'WIN' => 'W',
      'L' || 'LOSS' => 'L',
      _ => 'D',
    };
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM d, y  HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Result circle
          CircleAvatar(
            radius: 20,
            backgroundColor: _resultColor.withValues(alpha: 0.2),
            child: Text(
              _resultLabel,
              style: TextStyle(
                color: _resultColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Mode + map
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.mode}  •  ${entry.mapId}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(entry.playedAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Rewards
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.warning, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    '+${entry.expGained} EXP',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.monetization_on,
                      color: AppColors.coin, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    '+${entry.coinGained}',
                    style: const TextStyle(
                      color: AppColors.coin,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
