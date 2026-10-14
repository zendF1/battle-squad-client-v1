import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/character_progression_models.dart';
import '../../shared/widgets/error_snackbar.dart';
import 'character_provider.dart';

class CharacterDetailScreen extends ConsumerWidget {
  const CharacterDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charsAsync = ref.watch(playerCharactersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Characters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(playerCharactersProvider),
          ),
        ],
      ),
      body: charsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load characters',
                  style: TextStyle(color: AppColors.error)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(playerCharactersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (chars) {
          if (chars.isEmpty) {
            return const Center(
              child: Text('No characters unlocked yet.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chars.length,
            itemBuilder: (context, index) => _CharacterCard(
              character: chars[index],
            ),
          );
        },
      ),
    );
  }
}

class _CharacterCard extends ConsumerStatefulWidget {
  final PlayerCharacter character;

  const _CharacterCard({required this.character});

  @override
  ConsumerState<_CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends ConsumerState<_CharacterCard> {
  bool _expanded = false;
  bool _loading = false;

  // Pending stat allocations
  int _pendingHp = 0;
  int _pendingDamage = 0;
  int _pendingMobility = 0;
  int _pendingDefense = 0;
  int _pendingSkillPower = 0;
  int _pendingTerrainDmg = 0;

  int get _totalPending =>
      _pendingHp + _pendingDamage + _pendingMobility +
      _pendingDefense + _pendingSkillPower + _pendingTerrainDmg;

  int get _availablePoints => widget.character.statPoints - _totalPending;

  void _resetPending() {
    _pendingHp = 0;
    _pendingDamage = 0;
    _pendingMobility = 0;
    _pendingDefense = 0;
    _pendingSkillPower = 0;
    _pendingTerrainDmg = 0;
  }

  Future<void> _allocate() async {
    if (_totalPending == 0) return;
    setState(() => _loading = true);
    try {
      await ref.read(characterProgressionServiceProvider).allocateStats(
            characterId: widget.character.characterId,
            hp: _pendingHp,
            damage: _pendingDamage,
            mobility: _pendingMobility,
            defense: _pendingDefense,
            skillPower: _pendingSkillPower,
            terrainDamage: _pendingTerrainDmg,
          );
      _resetPending();
      if (mounted) showSuccessSnackbar(context, 'Stats allocated!');
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Failed to allocate: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetStats() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reset Stats?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will refund all allocated stat points. A gem fee may apply.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await ref.read(characterProgressionServiceProvider).resetStats(
            characterId: widget.character.characterId,
          );
      _resetPending();
      if (mounted) showSuccessSnackbar(context, 'Stats reset!');
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Failed to reset: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.character;
    final charColor = AppTheme.characterColor(c.characterId);
    final charName = switch (c.characterId) {
      'rookie' => 'Rookie',
      'tanko' => 'Tanko',
      'spark' => 'Spark',
      'flora' => 'Flora',
      _ => c.characterId,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() {
          _expanded = !_expanded;
          if (!_expanded) _resetPending();
        }),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: charColor.withValues(alpha: 0.2),
                    child: Text(
                      charName[0],
                      style: TextStyle(
                        color: charColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          charName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Lv.${c.level}  •  EXP ${c.exp}${c.nextLevelExp != null ? "/${c.nextLevelExp}" : " (MAX)"}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (c.statPoints > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${c.statPoints} pts',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),

              // Expanded stats
              if (_expanded) ...[
                const SizedBox(height: 16),
                const Divider(color: AppColors.primary),
                const SizedBox(height: 12),

                if (c.statPoints > 0) ...[
                  Text(
                    'Available Points: $_availablePoints / ${c.statPoints}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                _StatRow(
                  label: 'HP',
                  current: c.bonusHp,
                  pending: _pendingHp,
                  canAdd: _availablePoints > 0,
                  onAdd: () => setState(() => _pendingHp++),
                  onRemove: _pendingHp > 0
                      ? () => setState(() => _pendingHp--)
                      : null,
                ),
                _StatRow(
                  label: 'Damage',
                  current: c.bonusDamage,
                  pending: _pendingDamage,
                  canAdd: _availablePoints > 0,
                  onAdd: () => setState(() => _pendingDamage++),
                  onRemove: _pendingDamage > 0
                      ? () => setState(() => _pendingDamage--)
                      : null,
                ),
                _StatRow(
                  label: 'Mobility',
                  current: c.bonusMobility,
                  pending: _pendingMobility,
                  canAdd: _availablePoints > 0,
                  onAdd: () => setState(() => _pendingMobility++),
                  onRemove: _pendingMobility > 0
                      ? () => setState(() => _pendingMobility--)
                      : null,
                ),
                _StatRow(
                  label: 'Defense',
                  current: c.bonusDefense,
                  pending: _pendingDefense,
                  canAdd: _availablePoints > 0,
                  onAdd: () => setState(() => _pendingDefense++),
                  onRemove: _pendingDefense > 0
                      ? () => setState(() => _pendingDefense--)
                      : null,
                ),
                _StatRow(
                  label: 'Skill Power',
                  current: c.bonusSkillPower,
                  pending: _pendingSkillPower,
                  canAdd: _availablePoints > 0,
                  onAdd: () => setState(() => _pendingSkillPower++),
                  onRemove: _pendingSkillPower > 0
                      ? () => setState(() => _pendingSkillPower--)
                      : null,
                ),
                _StatRow(
                  label: 'Terrain Dmg',
                  current: c.bonusTerrainDmg,
                  pending: _pendingTerrainDmg,
                  canAdd: _availablePoints > 0,
                  onAdd: () => setState(() => _pendingTerrainDmg++),
                  onRemove: _pendingTerrainDmg > 0
                      ? () => setState(() => _pendingTerrainDmg--)
                      : null,
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    if (c.totalBonusSpent > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading ? null : _resetStats,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          child: const Text('Reset Stats'),
                        ),
                      ),
                    if (c.totalBonusSpent > 0 && _totalPending > 0)
                      const SizedBox(width: 12),
                    if (_totalPending > 0)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loading ? null : _allocate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              : Text('Allocate ($_totalPending pts)'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int current;
  final int pending;
  final bool canAdd;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const _StatRow({
    required this.label,
    required this.current,
    required this.pending,
    required this.canAdd,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '+$current',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (pending > 0)
            Text(
              ' +$pending',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          const Spacer(),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline, size: 22),
            color: onRemove != null ? AppColors.error : AppColors.textSecondary,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            onPressed: canAdd ? onAdd : null,
            icon: const Icon(Icons.add_circle_outline, size: 22),
            color: canAdd ? AppColors.success : AppColors.textSecondary,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
