import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ws/ws_events.dart';
import '../../shared/models/room_models.dart';
import '../../shared/widgets/app_card.dart';
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

    final completer = Completer<String?>();
    _wsSub?.cancel();
    _wsSub = ws.eventStream.listen((event) {
      if (event is RoomUpdatedEvent && !completer.isCompleted) {
        completer.complete(event.room.roomId);
      } else if (event is RoomErrorEvent && !completer.isCompleted) {
        completer.completeError(event.message);
      }
    });

    ws.send('JoinRoom', {
      'room_id': roomId,
      if (password != null) 'password': password,
    });

    try {
      final joinedRoomId = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Join room timed out'),
      );
      if (mounted && joinedRoomId != null) {
        context.push('/room/$joinedRoomId');
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
    final completer = Completer<String?>();

    _wsSub?.cancel();
    _wsSub = ws.eventStream.listen((event) {
      if (event is RoomUpdatedEvent && !completer.isCompleted) {
        completer.complete(event.room.roomId);
      } else if (event is RoomErrorEvent && !completer.isCompleted) {
        completer.completeError(event.message);
      }
    });

    ws.send('CreateRoom', {
      'mode': result.mode,
      'map_id': result.mapId,
      if (result.password != null) 'password': result.password,
    });

    try {
      final roomId = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Create room timed out'),
      );
      if (mounted && roomId != null) {
        context.push('/room/$roomId');
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
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: lobbyState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load rooms',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => ref.read(lobbyProvider.notifier).fetchRooms(),
              ),
            ],
          ),
        ),
        data: (rooms) => RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () => ref.read(lobbyProvider.notifier).fetchRooms(),
          child: rooms.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
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
                              'Create a room to start playing',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RoomCard(
                        room: room,
                        onTap: _joining
                            ? null
                            : () => _joinRoom(room.roomId),
                      ),
                    );
                  },
                ),
        ),
      ),
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
