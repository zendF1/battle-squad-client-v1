import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ws/ws_events.dart';
import '../../shared/models/room_models.dart';
import '../match/match_provider.dart';
import 'character_select.dart';
import 'item_select.dart';
import 'room_provider.dart';

class RoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  StreamSubscription<WsEvent>? _matchSub;

  @override
  void initState() {
    super.initState();
    _listenForMatch();
  }

  void _listenForMatch() {
    final ws = ref.read(wsManagerProvider);
    _matchSub = ws.eventStream.listen((event) {
      if (event is MatchStartedEvent && mounted) {
        ref.read(matchProvider.notifier).setInitialState(event.state);
        context.go('/match');
      }
    });
  }

  @override
  void dispose() {
    _matchSub?.cancel();
    super.dispose();
  }

  void _leave() {
    ref.read(roomProvider.notifier).leave();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final authState = ref.watch(authProvider);
    final myPlayerId = authState.playerId;

    if (roomState == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _leave),
          title: Text('Room ${widget.roomId.substring(0, 8)}...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final me = roomState.players.where((p) => p.playerId == myPlayerId).firstOrNull;
    final isHost = me?.isHost ?? false;
    final allReady = roomState.players.isNotEmpty &&
        roomState.players.every((p) => p.isReady || p.isHost);
    final isFull = roomState.players.length >= roomState.maxPlayers;
    final canStart = isHost && allReady && isFull;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _leave),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _modeLabel(roomState.mode),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _mapLabel(roomState.mapId),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          if (roomState.isLocked)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.lock, color: AppColors.warning, size: 20),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player list
            _SectionHeader(title: 'Players (${roomState.players.length}/${roomState.maxPlayers})'),
            const SizedBox(height: 8),
            ...roomState.players.map(
              (p) => _PlayerRow(
                player: p,
                isMe: p.playerId == myPlayerId,
              ),
            ),
            const SizedBox(height: 20),

            // Character select
            const _SectionHeader(title: 'Character'),
            const SizedBox(height: 8),
            CharacterSelect(
              selectedId: me?.characterId,
              onSelect: ref.read(roomProvider.notifier).selectCharacter,
            ),
            const SizedBox(height: 20),

            // Item select
            ItemSelect(
              availableItems: const [],
              selectedItems: me?.items ?? [],
              onChanged: ref.read(roomProvider.notifier).selectItems,
            ),
            const SizedBox(height: 32),

            // Action button
            SizedBox(
              width: double.infinity,
              child: isHost
                  ? ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Match'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canStart
                            ? AppColors.success
                            : AppColors.textSecondary,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: canStart
                          ? ref.read(roomProvider.notifier).startMatch
                          : null,
                    )
                  : ElevatedButton.icon(
                      icon: Icon(
                        me?.isReady == true
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                      ),
                      label: Text(
                          me?.isReady == true ? 'Ready!' : 'Mark as Ready'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: me?.isReady == true
                            ? AppColors.success
                            : AppColors.accent,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: ref.read(roomProvider.notifier).toggleReady,
                    ),
            ),

            if (isHost && !canStart) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  isFull
                      ? 'Waiting for all players to be ready...'
                      : 'Waiting for more players (${roomState.players.length}/${roomState.maxPlayers})...',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _modeLabel(String mode) => switch (mode) {
        'pvp_1v1' => '1v1 Battle',
        'pvp_2v2' => '2v2 Battle',
        _ => mode,
      };

  String _mapLabel(String mapId) => switch (mapId) {
        'grassland_valley' => 'Grassland Valley',
        'frozen_peak' => 'Frozen Peak',
        'steel_base' => 'Steel Base',
        _ => mapId,
      };
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final RoomPlayer player;
  final bool isMe;

  const _PlayerRow({required this.player, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final teamColor = AppTheme.teamColor(player.teamId);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: teamColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: teamColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Team color indicator
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: teamColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player.displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (player.isHost) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star, color: AppColors.coin, size: 14),
                    ],
                  ],
                ),
                Text(
                  'Team ${player.teamId}  •  ${_charLabel(player.characterId)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Ready status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (player.isReady || player.isHost)
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              player.isHost
                  ? 'Host'
                  : player.isReady
                      ? 'Ready'
                      : 'Waiting',
              style: TextStyle(
                color: player.isHost
                    ? AppColors.coin
                    : player.isReady
                        ? AppColors.success
                        : AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _charLabel(String characterId) => switch (characterId) {
        'rookie' => 'Rookie',
        'tanko' => 'Tanko',
        'spark' => 'Spark',
        'flora' => 'Flora',
        _ => characterId.isEmpty ? 'None' : characterId,
      };
}
