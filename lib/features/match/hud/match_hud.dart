import 'package:battle_squad_v1/core/auth/auth_provider.dart';
import 'package:battle_squad_v1/core/theme/app_theme.dart';
import 'package:battle_squad_v1/features/match/hud/angle_power_control.dart';
import 'package:battle_squad_v1/features/match/hud/item_skill_bar.dart';
import 'package:battle_squad_v1/features/match/hud/wind_indicator.dart';
import 'package:battle_squad_v1/features/match/match_provider.dart';
import 'package:battle_squad_v1/shared/models/match_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MatchHud extends ConsumerStatefulWidget {
  final MatchData matchData;
  final void Function(double angle, int power, String mode, String? itemId)
      onShoot;
  final void Function(String direction, double? targetX) onMove;
  final VoidCallback onEndTurn;

  const MatchHud({
    super.key,
    required this.matchData,
    required this.onShoot,
    required this.onMove,
    required this.onEndTurn,
  });

  @override
  ConsumerState<MatchHud> createState() => _MatchHudState();
}

class _MatchHudState extends ConsumerState<MatchHud> {
  double _angle = 45;
  int _power = 50;
  String _actionMode = 'weapon';
  String? _activeItemId;

  @override
  Widget build(BuildContext context) {
    final matchData = widget.matchData;
    final myPlayerId = ref.watch(authProvider).playerId;
    final isMyTurn = matchData.state.currentPlayerId == myPlayerId;
    final currentPlayer =
        matchData.state.players[matchData.state.currentPlayerId];

    final myPlayer = myPlayerId != null
        ? matchData.state.players[myPlayerId]
        : null;
    final myItems = myPlayer?.items ?? [];
    final mySkillCooldown = myPlayer?.skillCooldown ?? 0;
    final timeLeft = matchData.turnTimeLeft;

    return Column(
      children: [
        // ---- Top bar ----
        _TopBar(
          isMyTurn: isMyTurn,
          currentPlayerName: currentPlayer?.displayName ?? '...',
          timeLeft: timeLeft,
          wind: matchData.state.wind,
        ),

        const Spacer(),

        // ---- Bottom controls ----
        if (isMyTurn)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Item / Skill bar
                ItemSkillBar(
                  items: myItems,
                  skillCooldown: mySkillCooldown,
                  activeItemId: _activeItemId,
                  actionMode: _actionMode,
                  onActionModeChanged: (mode) =>
                      setState(() => _actionMode = mode),
                  onActiveItemChanged: (id) =>
                      setState(() => _activeItemId = id),
                ),
                const SizedBox(height: 8),
                // Main controls row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Move left button
                    _MoveButton(
                      icon: Icons.arrow_back_ios,
                      label: 'Move',
                      onTap: () => widget.onMove('left', null),
                    ),
                    const SizedBox(width: 8),
                    // Angle / power / fire
                    Expanded(
                      child: AnglePowerControl(
                        enabled: isMyTurn,
                        angle: _angle,
                        power: _power,
                        onAngleChanged: (v) => setState(() => _angle = v),
                        onPowerChanged: (v) => setState(() => _power = v),
                        onShoot: () => widget.onShoot(
                          _angle,
                          _power,
                          _actionMode,
                          _activeItemId,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Move right button
                    _MoveButton(
                      icon: Icons.arrow_forward_ios,
                      label: 'Move',
                      onTap: () => widget.onMove('right', null),
                    ),
                    const SizedBox(width: 8),
                    // End turn button
                    _EndTurnButton(onTap: widget.onEndTurn),
                  ],
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Waiting for ${currentPlayer?.displayName ?? "opponent"}...',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar widget
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  final bool isMyTurn;
  final String currentPlayerName;
  final int timeLeft;
  final WindState wind;

  const _TopBar({
    required this.isMyTurn,
    required this.currentPlayerName,
    required this.timeLeft,
    required this.wind,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMyTurn ? AppColors.accent : AppColors.primary,
        ),
      ),
      child: Row(
        children: [
          // Turn indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMyTurn ? 'YOUR TURN' : "Opponent's Turn",
                  style: TextStyle(
                    color: isMyTurn ? AppColors.accent : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentPlayerName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Timer
          _TimerBadge(timeLeft: timeLeft, isMyTurn: isMyTurn),

          const SizedBox(width: 12),

          // Wind indicator
          WindIndicator(wind: wind),
        ],
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  final int timeLeft;
  final bool isMyTurn;

  const _TimerBadge({required this.timeLeft, required this.isMyTurn});

  Color get _color {
    if (timeLeft > 10) return AppColors.success;
    if (timeLeft > 5) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color),
      ),
      child: Text(
        '$timeLeft',
        style: TextStyle(
          color: _color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Move button
// ---------------------------------------------------------------------------

class _MoveButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoveButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// End Turn button
// ---------------------------------------------------------------------------

class _EndTurnButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EndTurnButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warning),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.skip_next, color: AppColors.warning, size: 22),
            Text(
              'End',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
