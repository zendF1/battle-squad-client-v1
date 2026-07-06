import 'dart:math';

import 'package:battle_squad_v1/core/auth/auth_provider.dart';
import 'package:battle_squad_v1/core/theme/app_theme.dart';
import 'package:battle_squad_v1/features/match/game/battle_game.dart';
import 'package:battle_squad_v1/features/match/hud/match_hud.dart';
import 'package:battle_squad_v1/features/match/match_provider.dart';
import 'package:battle_squad_v1/features/match/match_result_dialog.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key});

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  BattleGame? _game;
  String? _lastProjectileId;
  bool _resultShown = false;

  // Drag-to-shoot state
  Offset? _dragStart;
  double _dragAngle = 45;
  int _dragPower = 50;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final matchData = ref.watch(matchProvider);

    // No match data yet — show a loading screen
    if (matchData == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.accent),
              SizedBox(height: 16),
              Text(
                'Waiting for match...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Create BattleGame once when we first get state
    _game ??= BattleGame(
      mapId: matchData.state.mapId,
      initialPlayers: matchData.state.players,
    );

    // Sync player states from provider into game
    _syncPlayersToGame(matchData);

    // Animate new projectile if available
    _handleProjectile(matchData);

    // Show result dialog (deferred to after build)
    if (matchData.endedData != null && !_resultShown) {
      _resultShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResultDialog(matchData);
      });
    }

    final notifier = ref.read(matchProvider.notifier);
    final myPlayerId = ref.watch(authProvider).playerId;
    final isMyTurn = matchData.state.currentPlayerId == myPlayerId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Game canvas with drag-to-shoot gesture
          GestureDetector(
            onPanStart: isMyTurn ? _onDragStart : null,
            onPanUpdate: isMyTurn
                ? (details) => _onDragUpdate(details, matchData, myPlayerId)
                : null,
            onPanEnd: isMyTurn
                ? (details) => _onDragEnd(matchData, notifier, myPlayerId)
                : null,
            child: GameWidget(game: _game!),
          ),

          // HUD overlay
          SafeArea(
            child: MatchHud(
              matchData: matchData,
              dragAngle: _isDragging ? _dragAngle : null,
              dragPower: _isDragging ? _dragPower : null,
              onShoot: (angle, power, mode, itemId) {
                notifier.shoot(
                  angle: angle,
                  power: power,
                  actionMode: mode,
                  itemId: itemId,
                );
              },
              onMove: (direction, targetX) {
                notifier.move(direction: direction, targetX: targetX);
              },
              onEndTurn: notifier.endTurn,
            ),
          ),

          // Drag aim indicator overlay
          if (_isDragging)
            Positioned(
              bottom: 160,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Text(
                    'Angle: ${_dragAngle.round()}°  Power: $_dragPower',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onDragStart(DragStartDetails details) {
    _dragStart = details.localPosition;
    setState(() => _isDragging = true);
  }

  void _onDragUpdate(
      DragUpdateDetails details, MatchData matchData, String? myPlayerId) {
    if (_dragStart == null || myPlayerId == null) return;

    final dx = details.localPosition.dx - _dragStart!.dx;
    final dy = details.localPosition.dy - _dragStart!.dy;
    final distance = sqrt(dx * dx + dy * dy);

    // Angle: drag down-right = shoot up-left, Angry Birds style
    // atan2(-dy, -dx) gives the opposite direction of drag
    var angleDeg = atan2(-(-dy), -dx) * 180 / pi;
    angleDeg = angleDeg.clamp(0, 180);

    // Power: based on drag distance (max ~200px = 100 power)
    final power = (distance / 2).clamp(0, 100).round();

    setState(() {
      _dragAngle = angleDeg;
      _dragPower = power;
    });

    // Update trajectory preview
    _game?.showTrajectory(
      playerId: myPlayerId,
      angleDeg: angleDeg,
      power: power.toDouble(),
      windDirection: matchData.state.wind.direction,
      windPower: matchData.state.wind.power,
    );
  }

  void _onDragEnd(
      MatchData matchData, MatchNotifier notifier, String? myPlayerId) {
    if (!_isDragging || _dragPower < 5) {
      // Too weak, cancel
      _game?.hideTrajectory();
      setState(() => _isDragging = false);
      return;
    }

    // Fire with dragged angle/power
    notifier.shoot(
      angle: _dragAngle,
      power: _dragPower,
      actionMode: 'weapon',
    );

    _game?.hideTrajectory();
    setState(() {
      _isDragging = false;
      _dragStart = null;
    });
  }

  void _syncPlayersToGame(MatchData matchData) {
    final game = _game;
    if (game == null) return;

    for (final entry in matchData.state.players.entries) {
      final ps = entry.value;
      game.updatePlayer(
        entry.key,
        hp: ps.hp,
        isAlive: ps.isAlive,
        position: Vector2(ps.position.x, ps.position.y),
      );
    }
  }

  void _handleProjectile(MatchData matchData) {
    final proj = matchData.lastProjectile;
    if (proj == null) return;
    if (proj.projectileId == _lastProjectileId) return;

    _lastProjectileId = proj.projectileId;
    _game?.animateProjectile(proj, () {
      // Animation complete — state already reflects damage from PlayerDamagedEvent
    });
  }

  void _showResultDialog(MatchData matchData) {
    if (matchData.endedData == null) return;

    final myPlayerId = ref.read(authProvider).playerId;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MatchResultDialog(
        endedData: matchData.endedData!,
        myPlayerId: myPlayerId,
        players: matchData.state.players,
        onBackToLobby: () {
          ref.read(matchProvider.notifier).leave();
          if (mounted) context.go('/home');
        },
      ),
    );
  }
}
