import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/mission_models.dart';
import '../../shared/widgets/error_snackbar.dart';
import 'mission_provider.dart';

class MissionScreen extends ConsumerWidget {
  const MissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Missions'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Daily'),
              Tab(text: 'Achievements'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MissionTab(type: _MissionTabType.daily),
            _MissionTab(type: _MissionTabType.achievements),
          ],
        ),
      ),
    );
  }
}

enum _MissionTabType { daily, achievements }

class _MissionTab extends ConsumerWidget {
  final _MissionTabType type;

  const _MissionTab({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = type == _MissionTabType.daily
        ? ref.watch(dailyMissionsProvider)
        : ref.watch(achievementsProvider);

    return missionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Failed to load missions',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                if (type == _MissionTabType.daily) {
                  ref.invalidate(dailyMissionsProvider);
                } else {
                  ref.invalidate(achievementsProvider);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (missions) => missions.isEmpty
          ? const Center(
              child: Text(
                'No missions available',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: missions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _MissionCard(mission: missions[index], tabType: type);
              },
            ),
    );
  }
}

class _MissionCard extends ConsumerStatefulWidget {
  final Mission mission;
  final _MissionTabType tabType;

  const _MissionCard({required this.mission, required this.tabType});

  @override
  ConsumerState<_MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends ConsumerState<_MissionCard> {
  bool _claiming = false;

  bool get _canClaim =>
      !widget.mission.isClaimed &&
      widget.mission.currentValue >= widget.mission.requiredValue;

  Future<void> _onClaim() async {
    setState(() => _claiming = true);
    try {
      final response = await claimMission(ref, widget.mission.missionId);
      if (mounted) {
        showSuccessSnackbar(
          context,
          'Claimed! +${response.rewardCoin} coins, +${response.rewardGem} gems',
        );
        if (widget.tabType == _MissionTabType.daily) {
          ref.invalidate(dailyMissionsProvider);
        } else {
          ref.invalidate(achievementsProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Failed to claim: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final progress =
        (mission.currentValue / mission.requiredValue).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${mission.type}: ${mission.target}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (mission.isClaimed)
                  const Icon(Icons.check_circle, color: AppColors.success)
                else
                  _ClaimButton(
                    canClaim: _canClaim,
                    claiming: _claiming,
                    onClaim: _onClaim,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${mission.currentValue} / ${mission.requiredValue}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.primary,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.accent),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Rewards row
            Row(
              children: [
                const Icon(Icons.monetization_on,
                    color: AppColors.coin, size: 16),
                const SizedBox(width: 4),
                Text(
                  '+${mission.rewardCoin}',
                  style: const TextStyle(color: AppColors.coin, fontSize: 13),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.diamond, color: AppColors.gem, size: 16),
                const SizedBox(width: 4),
                Text(
                  '+${mission.rewardGem}',
                  style: const TextStyle(color: AppColors.gem, fontSize: 13),
                ),
                if (mission.rewardItems.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.inventory_2_outlined,
                      color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${mission.rewardItems.length} item(s)',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  final bool canClaim;
  final bool claiming;
  final VoidCallback onClaim;

  const _ClaimButton({
    required this.canClaim,
    required this.claiming,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    if (claiming) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return ElevatedButton(
      onPressed: canClaim ? onClaim : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Claim', style: TextStyle(fontSize: 13)),
    );
  }
}
