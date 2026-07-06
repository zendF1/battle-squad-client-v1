import 'package:battle_squad_v1/core/theme/app_theme.dart';
import 'package:battle_squad_v1/shared/models/match_models.dart';
import 'package:flutter/material.dart';

class MatchResultDialog extends StatelessWidget {
  final MatchEndedData endedData;
  final String? myPlayerId;
  final Map<String, BattlePlayerState> players;
  final VoidCallback onBackToLobby;

  const MatchResultDialog({
    super.key,
    required this.endedData,
    required this.myPlayerId,
    required this.players,
    required this.onBackToLobby,
  });

  String get _resultLabel {
    final result = endedData.result;
    if (result != null) {
      switch (result) {
        case 'no_contest':
          return 'NO CONTEST';
        case 'draw':
          return 'DRAW';
        case 'win':
          return 'VICTORY';
        case 'loss':
          return 'DEFEAT';
      }
    }
    // Derive from winningTeam
    final myPlayer = myPlayerId != null ? players[myPlayerId] : null;
    if (endedData.winningTeam == 0) return 'DRAW';
    if (myPlayer == null) return 'MATCH ENDED';
    return myPlayer.teamId == endedData.winningTeam ? 'VICTORY' : 'DEFEAT';
  }

  Color get _resultColor {
    final label = _resultLabel;
    return switch (label) {
      'VICTORY' => AppColors.success,
      'DEFEAT' => AppColors.error,
      'NO CONTEST' => AppColors.textSecondary,
      _ => AppColors.warning,
    };
  }

  MatchReward? get _myReward {
    if (myPlayerId == null) return null;
    return endedData.rewards?[myPlayerId];
  }

  BattlePlayerState? get _myStats {
    if (myPlayerId == null) return null;
    return players[myPlayerId];
  }

  @override
  Widget build(BuildContext context) {
    final reward = _myReward;
    final myStats = _myStats;
    final resultLabel = _resultLabel;
    final resultColor = _resultColor;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Result header
            Text(
              resultLabel,
              style: TextStyle(
                color: resultColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            if (endedData.message != null) ...[
              const SizedBox(height: 6),
              Text(
                endedData.message!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            const Divider(color: AppColors.primary),
            const SizedBox(height: 12),

            // Rewards
            if (reward != null) ...[
              const Text(
                'REWARDS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RewardTile(
                    icon: Icons.star,
                    color: AppColors.warning,
                    label: 'EXP',
                    value: '+${reward.exp}',
                  ),
                  _RewardTile(
                    icon: Icons.monetization_on,
                    color: AppColors.coin,
                    label: 'Coins',
                    value: '+${reward.coins}',
                  ),
                  if (reward.gemReward != null)
                    _RewardTile(
                      icon: Icons.diamond,
                      color: AppColors.gem,
                      label: 'Gems',
                      value: '+${reward.gemReward}',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.primary),
              const SizedBox(height: 12),
            ],

            // Player stats
            if (myStats != null) ...[
              const Text(
                'STATS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              _StatRow(label: 'Damage Dealt', value: '${myStats.damageDealt}'),
              _StatRow(label: 'Kills', value: '${myStats.killCount}'),
              _StatRow(
                label: 'Accuracy',
                value: myStats.shotsFired == 0
                    ? '0%'
                    : '${(myStats.shotsHit / myStats.shotsFired * 100).round()}%',
              ),
              const SizedBox(height: 16),
            ],

            // Back to lobby button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBackToLobby,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Back to Lobby',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _RewardTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
