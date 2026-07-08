import 'dart:math';

import 'package:battle_squad_v1/core/auth/auth_provider.dart';
import 'package:battle_squad_v1/core/providers/core_providers.dart';
import 'package:battle_squad_v1/core/theme/app_theme.dart';
import 'package:battle_squad_v1/features/match/game/battle_game.dart';
import 'package:battle_squad_v1/features/match/hud/match_hud.dart';
import 'package:battle_squad_v1/features/match/match_provider.dart';
import 'package:battle_squad_v1/features/match/match_result_dialog.dart';
import 'package:battle_squad_v1/shared/widgets/error_snackbar.dart';
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
  String _actionMode = 'weapon';
  String? _activeItemId;
  bool _isInCancelZone = false;

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
    if (_game == null) {
      final myId = ref.read(authProvider).playerId;
      final localTeamId = matchData.state.players[myId]?.teamId ?? 1;
      _game = BattleGame(
        mapId: matchData.state.mapId,
        initialPlayers: matchData.state.players,
        localTeamId: localTeamId,
      );
    }

    // Animate new projectile if available
    _handleProjectile(matchData);

    // Sync player states (X, HP, isAlive immediately; Y stored for gravity anti-desync)
    _syncPlayersToGame(matchData);

    // Show result dialog (deferred to after build)
    if (matchData.endedData != null && !_resultShown) {
      _resultShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResultDialog(matchData);
      });
    }

    final notifier = ref.read(matchProvider.notifier);
    final myPlayerId = ref.watch(authProvider).playerId;

    // Reset action mode if active item was consumed
    if (_activeItemId != null && myPlayerId != null) {
      final myPlayer = matchData.state.players[myPlayerId];
      if (myPlayer != null && !myPlayer.items.contains(_activeItemId)) {
        _actionMode = 'weapon';
        _activeItemId = null;
      }
    }

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
              actionMode: _actionMode,
              activeItemId: _activeItemId,
              onActionModeChanged: (mode) => setState(() => _actionMode = mode),
              onActiveItemChanged: (id) => setState(() => _activeItemId = id),
              onShoot: (angle, power, mode, itemId) {
                notifier.shoot(angle: angle, power: power, actionMode: mode, itemId: itemId);
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
    setState(() {
      _isDragging = true;
      _isInCancelZone = false;
    });
    final myPlayerId = ref.read(authProvider).playerId;
    if (myPlayerId != null) {
      _game?.showCancelZone(myPlayerId);
    }
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

    // Check cancel zone
    final game = _game;
    if (game != null) {
      final worldPoint = game.screenToWorld(details.localPosition);
      final inZone = game.isInCancelZone(worldPoint);
      game.setCancelZoneHighlight(inZone);
      _isInCancelZone = inZone;
    }
  }

  void _onDragEnd(
      MatchData matchData, MatchNotifier notifier, String? myPlayerId) {
    _game?.hideCancelZone();

    if (!_isDragging || _dragPower < 5 || _isInCancelZone) {
      _game?.hideTrajectory();
      setState(() {
        _isDragging = false;
        _isInCancelZone = false;
      });
      return;
    }

    notifier.shoot(
      angle: _dragAngle,
      power: _dragPower,
      actionMode: _actionMode,
      itemId: _activeItemId,
    );

    _game?.hideTrajectory();
    setState(() {
      _isDragging = false;
      _dragStart = null;
      _isInCancelZone = false;
      if (_actionMode == 'item') {
        _actionMode = 'weapon';
        _activeItemId = null;
      }
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
        x: ps.position.x,
        serverY: ps.position.y,
      );
    }
  }

  void _handleProjectile(MatchData matchData) {
    final proj = matchData.lastProjectile;
    if (proj == null) return;
    if (proj.projectileId == _lastProjectileId) return;

    _lastProjectileId = proj.projectileId;
    _game?.animateProjectile(proj);
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
        matchId: matchData.state.matchId,
        players: matchData.state.players,
        onBackToLobby: () {
          ref.read(matchProvider.notifier).leave();
          if (mounted) context.go('/home');
        },
        onReport: (reportData) async {
          try {
            final client = ref.read(apiClientProvider);
            await client.post('/report/player', data: reportData);
            if (mounted) {
              showSuccessSnackbar(context, 'Report submitted. Thank you!');
            }
          } catch (e) {
            if (mounted) {
              showErrorSnackbar(context, 'Failed to submit report: $e');
            }
          }
        },
      ),
    );
  }
}
