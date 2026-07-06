import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/rank_models.dart';
import 'ranking_provider.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonAsync = ref.watch(currentSeasonProvider);
    final myRankAsync = ref.watch(myRankProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider(1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(currentSeasonProvider);
              ref.invalidate(myRankProvider);
              ref.invalidate(leaderboardProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Season card
            seasonAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => const _ErrorText('Failed to load season info'),
              data: (season) => _SeasonCard(season: season),
            ),

            const SizedBox(height: 16),

            // My rank card
            Text('My Rank',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            myRankAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  const _ErrorText('Failed to load your rank'),
              data: (rank) => _MyRankCard(rank: rank),
            ),

            const SizedBox(height: 20),

            // Leaderboard
            Text('Leaderboard',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            leaderboardAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  const _ErrorText('Failed to load leaderboard'),
              data: (players) => players.isEmpty
                  ? const Center(
                      child: Text(
                        'No players yet',
                        style:
                            TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : _LeaderboardList(players: players),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonCard extends StatelessWidget {
  final Season season;

  const _SeasonCard({required this.season});

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM d, y').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: AppColors.warning, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    season.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ends: ${_formatDate(season.endsAt)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                season.status.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyRankCard extends StatelessWidget {
  final PlayerRank rank;

  const _MyRankCard({required this.rank});

  Color get _tierColor {
    return switch (rank.tier.toLowerCase()) {
      'rookie' => AppColors.rookie,
      'tanko' => AppColors.tanko,
      'spark' => AppColors.spark,
      'flora' => AppColors.flora,
      _ => AppColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Tier badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _tierColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: _tierColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      rank.tier.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: _tierColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rank.displayName,
                        style:
                            Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${rank.tier} ${rank.division}  •  ${rank.rating} RP',
                        style: TextStyle(
                            color: _tierColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (rank.rankPos != null)
                  Text(
                    '#${rank.rankPos}',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.primary),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                    label: 'W', value: '${rank.wins}', color: AppColors.success),
                _StatChip(
                    label: 'L',
                    value: '${rank.losses}',
                    color: AppColors.error),
                _StatChip(
                    label: 'D',
                    value: '${rank.draws}',
                    color: AppColors.warning),
                _StatChip(
                    label: 'Streak',
                    value: '${rank.winStreak}',
                    color: AppColors.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<PlayerRank> players;

  const _LeaderboardList({required this.players});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        return _LeaderboardRow(rank: players[index], position: index + 1);
      },
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final PlayerRank rank;
  final int position;

  const _LeaderboardRow({required this.rank, required this.position});

  bool get _isTopThree => position <= 3;

  Color get _tierColor {
    return switch (rank.tier.toLowerCase()) {
      'rookie' => AppColors.rookie,
      'tanko' => AppColors.tanko,
      'spark' => AppColors.spark,
      'flora' => AppColors.flora,
      _ => AppColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _isTopThree
            ? AppColors.warning.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: _isTopThree
            ? Border.all(color: AppColors.warning.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '#$position',
              style: TextStyle(
                color: _isTopThree
                    ? AppColors.warning
                    : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor:
                _isTopThree ? AppColors.warning : AppColors.primary,
            child: Text(
              rank.displayName.isNotEmpty
                  ? rank.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color:
                    _isTopThree ? AppColors.background : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name + tier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank.displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${rank.tier} ${rank.division}',
                  style:
                      TextStyle(color: _tierColor, fontSize: 12),
                ),
              ],
            ),
          ),
          // Rating
          Text(
            '${rank.rating} RP',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;

  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message,
          style: const TextStyle(color: AppColors.error)),
    );
  }
}
