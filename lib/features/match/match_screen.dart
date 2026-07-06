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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Game canvas
          GameWidget(game: _game!),

          // HUD overlay
          SafeArea(
            child: MatchHud(
              matchData: matchData,
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
        ],
      ),
    );
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
