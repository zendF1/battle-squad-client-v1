import 'dart:async';

import 'package:battle_squad_v1/core/auth/auth_provider.dart';
import 'package:battle_squad_v1/core/theme/app_theme.dart';
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
  final double? dragAngle;
  final int? dragPower;

  const MatchHud({
    super.key,
    required this.matchData,
    required this.onShoot,
    required this.onMove,
    required this.onEndTurn,
    this.dragAngle,
    this.dragPower,
  });

  @override
  ConsumerState<MatchHud> createState() => _MatchHudState();
}

class _MatchHudState extends ConsumerState<MatchHud> {
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
                // Controls row: hold-to-move + drag hint + end turn
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Move left (hold)
                    _HoldMoveButton(
                      icon: Icons.arrow_back_ios,
                      onMove: () {
                        final pos = myPlayer?.position;
                        if (pos == null) return;
                        widget.onMove('left', pos.x - 10);
                      },
                    ),
                    const SizedBox(width: 8),
                    // Drag-to-shoot hint
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Center(
                          child: Text(
                            widget.dragAngle != null
                                ? '${widget.dragAngle!.round()}°  PWR: ${widget.dragPower}'
                                : 'Drag on screen to aim & shoot',
                            style: TextStyle(
                              color: widget.dragAngle != null
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: widget.dragAngle != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Move right (hold)
                    _HoldMoveButton(
                      icon: Icons.arrow_forward_ios,
                      onMove: () {
                        final pos = myPlayer?.position;
                        if (pos == null) return;
                        widget.onMove('right', pos.x + 10);
                      },
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
          _TimerBadge(timeLeft: timeLeft, isMyTurn: isMyTurn),
          const SizedBox(width: 12),
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
// Hold-to-move button — fires repeatedly while held
// ---------------------------------------------------------------------------

class _HoldMoveButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onMove;

  const _HoldMoveButton({required this.icon, required this.onMove});

  @override
  State<_HoldMoveButton> createState() => _HoldMoveButtonState();
}

class _HoldMoveButtonState extends State<_HoldMoveButton> {
  Timer? _timer;

  void _startMoving() {
    widget.onMove();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      widget.onMove();
    });
  }

  void _stopMoving() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startMoving(),
      onTapUp: (_) => _stopMoving(),
      onTapCancel: _stopMoving,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary),
        ),
        child: Icon(widget.icon, color: AppColors.textPrimary, size: 22),
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
