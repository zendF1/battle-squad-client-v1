import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ws/ws_events.dart';
import '../../shared/models/room_models.dart';
import '../../shared/widgets/app_card.dart';
import '../match/match_provider.dart';
import '../room/room_provider.dart';
import 'create_room_dialog.dart';
import 'lobby_provider.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  StreamSubscription<WsEvent>? _wsSub;
  bool _joining = false;

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _joinRoom(String roomId, {String? password}) async {
    if (_joining) return;
    setState(() => _joining = true);

    final ws = ref.read(wsManagerProvider);

    final completer = Completer<RoomState>();
    _wsSub?.cancel();
    _wsSub = ws.eventStream.listen((event) {
      if (event is RoomUpdatedEvent && !completer.isCompleted) {
        completer.complete(event.room);
      } else if (event is RoomErrorEvent && !completer.isCompleted) {
        completer.completeError(event.message);
      }
    });

    ws.send('JoinRoom', {
      'roomId': roomId,
      if (password != null) 'password': password,
    });

    try {
      final roomState = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Join room timed out'),
      );
      if (mounted) {
        ref.read(roomProvider.notifier).setInitialState(roomState);
        context.push('/room/${roomState.roomId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join room: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      _wsSub?.cancel();
      _wsSub = null;
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _createRoom() async {
    final result = await showDialog<CreateRoomResult>(
      context: context,
      builder: (_) => const CreateRoomDialog(),
    );
    if (result == null || !mounted) return;

    setState(() => _joining = true);

    final ws = ref.read(wsManagerProvider);
    final completer = Completer<RoomState>();

    _wsSub?.cancel();
    _wsSub = ws.eventStream.listen((event) {
      if (event is RoomUpdatedEvent && !completer.isCompleted) {
        completer.complete(event.room);
      } else if (event is RoomErrorEvent && !completer.isCompleted) {
        completer.completeError(event.message);
      }
    });

    ws.send('CreateRoom', {
      'mode': result.mode,
      'mapId': result.mapId,
      if (result.password != null) 'password': result.password,
    });

    try {
      final roomState = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Create room timed out'),
      );
      if (mounted) {
        ref.read(roomProvider.notifier).setInitialState(roomState);
        context.push('/room/${roomState.roomId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create room: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      _wsSub?.cancel();
      _wsSub = null;
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _quickPlay() async {
    if (_joining) return;
    setState(() => _joining = true);

    final ws = ref.read(wsManagerProvider);
    final completer = Completer<MatchStartedEvent>();

    _wsSub?.cancel();
    _wsSub = ws.eventStream.listen((event) {
      if (event is MatchStartedEvent && !completer.isCompleted) {
        completer.complete(event);
      } else if (event is RoomErrorEvent && !completer.isCompleted) {
        completer.completeError(event.message);
      }
    });

    ws.send('QuickPlay', {});

    try {
      final matchEvent = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Quick play timed out'),
      );
      if (mounted) {
        ref.read(matchProvider.notifier).setInitialState(matchEvent.state);
        context.go('/match');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start quick play: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      _wsSub?.cancel();
      _wsSub = null;
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lobbyState = ref.watch(lobbyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Battle Squad',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: () => ref.read(lobbyProvider.notifier).fetchRooms(),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: lobbyState.isLoading && lobbyState.rooms.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : lobbyState.error != null && lobbyState.rooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load rooms',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lobbyState.error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: () =>
                            ref.read(lobbyProvider.notifier).fetchRooms(),
                      ),
                    ],
                  ),
                )
              : _buildBody(context, lobbyState),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _joining ? null : _createRoom,
        backgroundColor: AppColors.accent,
        icon: _joining
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textPrimary,
                ),
              )
            : const Icon(Icons.add, color: AppColors.textPrimary),
        label: const Text(
          'Create Room',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LobbyState lobbyState) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => ref.read(lobbyProvider.notifier).fetchRooms(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick Play button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _joining ? null : _quickPlay,
              icon: const Icon(Icons.flash_on, color: AppColors.textPrimary),
              label: const Text(
                'Quick Play (Practice)',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Room list header
          if (lobbyState.rooms.isNotEmpty) ...[
            Text(
              'Rooms (${lobbyState.total})',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Room list
          if (lobbyState.rooms.isEmpty)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.meeting_room_outlined,
                      color: AppColors.textSecondary,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No rooms available',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a room or use Quick Play',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ...lobbyState.rooms.map(
              (room) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RoomCard(
                  room: room,
                  onTap: _joining ? null : () => _joinRoom(room.roomId),
                ),
              ),
            ),
            // Pagination
            if (lobbyState.totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      color: lobbyState.page > 1
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      onPressed: lobbyState.page > 1
                          ? () => ref.read(lobbyProvider.notifier).prevPage()
                          : null,
                    ),
                    Text(
                      '${lobbyState.page} / ${lobbyState.totalPages}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      color: lobbyState.page < lobbyState.totalPages
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      onPressed: lobbyState.page < lobbyState.totalPages
                          ? () => ref.read(lobbyProvider.notifier).nextPage()
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomListItem room;
  final VoidCallback? onTap;

  const _RoomCard({required this.room, this.onTap});

  String get _modeLabel {
    return switch (room.mode) {
      'pvp_1v1' => '1v1',
      'pvp_2v2' => '2v2',
      _ => room.mode,
    };
  }

  String get _mapLabel {
    return switch (room.mapId) {
      'grassland_valley' => 'Grassland Valley',
      'frozen_peak' => 'Frozen Peak',
      'steel_base' => 'Steel Base',
      _ => room.mapId,
    };
  }

  Color get _modeColor {
    return room.mode == 'pvp_1v1' ? AppColors.accent : AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          // Mode badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _modeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _modeColor, width: 1),
            ),
            child: Text(
              _modeLabel,
              style: TextStyle(
                color: _modeColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Map name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mapLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Room ${room.roomId.substring(0, 8)}...',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Player count
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 4),
              Text(
                '${room.playerCount}/${room.maxPlayers}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Lock icon
          if (room.isLocked)
            const Icon(Icons.lock, color: AppColors.warning, size: 18)
          else
            const Icon(Icons.lock_open, color: AppColors.textSecondary, size: 18),
        ],
      ),
    );
  }
}
