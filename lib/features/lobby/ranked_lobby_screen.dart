import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ws/ws_events.dart';
import '../../shared/models/lobby_models.dart';
import '../match/match_provider.dart';
import '../room/character_select.dart';
import '../room/item_select.dart';
import 'ranked_lobby_provider.dart';

class RankedLobbyScreen extends ConsumerStatefulWidget {
  const RankedLobbyScreen({super.key});

  @override
  ConsumerState<RankedLobbyScreen> createState() => _RankedLobbyScreenState();
}

class _RankedLobbyScreenState extends ConsumerState<RankedLobbyScreen> {
  StreamSubscription<WsEvent>? _matchSub;
  bool _created = false;

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

  void _createOrJoinLobby() {
    if (_created) return;
    _created = true;
    ref.read(rankedLobbyProvider.notifier).createLobby();
  }

  void _leaveLobby() {
    ref.read(rankedLobbyProvider.notifier).leaveLobby();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(rankedLobbyProvider);
    final authState = ref.watch(authProvider);
    final myPlayerId = authState.playerId;

    // Auto-create lobby when screen first opens
    if (data.status == RankedLobbyStatus.idle && !_created) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _createOrJoinLobby();
      });
    }

    // Handle disbanded state
    if (data.status == RankedLobbyStatus.disbanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data.errorMessage ?? 'Lobby disbanded'),
              backgroundColor: AppColors.warning,
            ),
          );
          ref.read(rankedLobbyProvider.notifier).reset();
          context.go('/home');
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leaveLobby();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _leaveLobby),
          title: const Text(
            'Ranked 2v2',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: _buildBody(data, myPlayerId),
      ),
    );
  }

  Widget _buildBody(RankedLobbyData data, String? myPlayerId) {
    if (data.status == RankedLobbyStatus.idle) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (data.lobby == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            if (data.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                data.errorMessage!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    final lobby = data.lobby!;
    final isHost = lobby.hostPlayerId == myPlayerId;
    final myMember = lobby.members
        .where((m) => m.playerId == myPlayerId)
        .firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          _StatusBanner(status: data.status),
          const SizedBox(height: 20),

          // Error message
          if (data.errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data.errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Members
          const Text(
            'Team Members',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          ...lobby.members.map(
            (m) => _MemberCard(
              member: m,
              isMe: m.playerId == myPlayerId,
              isHost: m.playerId == lobby.hostPlayerId,
            ),
          ),
          if (lobby.members.length < 2)
            _EmptySlot(),
          const SizedBox(height: 20),

          // Loadout selection (only when preparing)
          if (data.status == RankedLobbyStatus.preparing) ...[
            const Text(
              'Character',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            CharacterSelect(
              selectedId: myMember?.characterId,
              onSelect: (characterId) {
                ref.read(rankedLobbyProvider.notifier)
                    .updateLoadout(characterId: characterId);
              },
            ),
            const SizedBox(height: 20),
            ItemSelect(
              availableItems: const [],
              selectedItems: myMember?.items ?? [],
              onChanged: (items) {
                ref.read(rankedLobbyProvider.notifier)
                    .updateLoadout(items: items);
              },
            ),
            const SizedBox(height: 32),
          ],

          // Action buttons
          if (data.status == RankedLobbyStatus.preparing && isHost)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Find Match'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  ref.read(rankedLobbyProvider.notifier).startQueue();
                },
              ),
            ),

          if (data.status == RankedLobbyStatus.preparing && !isHost)
            const Center(
              child: Text(
                'Waiting for host to start queue...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),

          if (data.status == RankedLobbyStatus.inQueue) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel Queue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isHost
                    ? () {
                        ref.read(rankedLobbyProvider.notifier).cancelQueue();
                      }
                    : null,
              ),
            ),
          ],

          if (data.status == RankedLobbyStatus.inMatch)
            const Center(
              child: Text(
                'Match starting...',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final RankedLobbyStatus status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      RankedLobbyStatus.preparing => ('Preparing', AppColors.accent, Icons.group),
      RankedLobbyStatus.inQueue => ('Searching for match...', AppColors.warning, Icons.hourglass_top),
      RankedLobbyStatus.inMatch => ('Match Found!', AppColors.success, Icons.sports_esports),
      _ => ('Lobby', AppColors.textSecondary, Icons.group),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (status == RankedLobbyStatus.inQueue)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(icon, color: color, size: 22),
            ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final LobbyMember member;
  final bool isMe;
  final bool isHost;

  const _MemberCard({
    required this.member,
    required this.isMe,
    required this.isHost,
  });

  String get _tierLabel => switch (member.tier) {
        'bronze' => 'Bronze',
        'silver' => 'Silver',
        'gold' => 'Gold',
        'platinum' => 'Platinum',
        'diamond' => 'Diamond',
        'master' => 'Master',
        _ => member.tier,
      };

  String get _charLabel => switch (member.characterId) {
        'rookie' => 'Rookie',
        'tanko' => 'Tanko',
        'spark' => 'Spark',
        'flora' => 'Flora',
        _ => member.characterId.isEmpty ? 'None' : member.characterId,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.team1.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.team1.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.team1,
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
                      member.displayName,
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
                    if (isHost) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star, color: AppColors.coin, size: 14),
                    ],
                  ],
                ),
                Text(
                  '$_charLabel  •  $_tierLabel ${member.rating}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: const Center(
        child: Text(
          'Waiting for teammate...',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
