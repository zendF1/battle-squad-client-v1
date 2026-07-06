import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/ws/ws_events.dart';
import '../../shared/models/room_models.dart';

class LobbyState {
  final List<RoomListItem> rooms;
  final int page;
  final int totalPages;
  final int total;
  final bool isLoading;
  final String? error;

  const LobbyState({
    this.rooms = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.isLoading = false,
    this.error,
  });

  LobbyState copyWith({
    List<RoomListItem>? rooms,
    int? page,
    int? totalPages,
    int? total,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return LobbyState(
      rooms: rooms ?? this.rooms,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LobbyNotifier extends StateNotifier<LobbyState> {
  final Ref _ref;
  StreamSubscription<WsEvent>? _wsSub;
  Timer? _refreshTimer;

  LobbyNotifier(this._ref) : super(const LobbyState(isLoading: true)) {
    fetchRooms();
    _listenForRoomChanges();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchRooms(silent: true);
    });
  }

  void _listenForRoomChanges() {
    _wsSub = _ref.read(wsManagerProvider).eventStream.listen((event) {
      if (event is RoomUpdatedEvent) {
        // A room was updated, refresh list
        fetchRooms(silent: true);
      }
    });
  }

  Future<void> fetchRooms({int? page, bool silent = false}) async {
    final targetPage = page ?? state.page;
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final client = _ref.read(apiClientProvider);
      final data = await client.get('/rooms?page=$targetPage&limit=10');
      final rawList = data['rooms'] as List<dynamic>? ?? [];
      final rooms = rawList
          .map((e) => RoomListItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        rooms: rooms,
        page: data['page'] as int? ?? targetPage,
        totalPages: data['totalPages'] as int? ?? 1,
        total: data['total'] as int? ?? rooms.length,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void nextPage() {
    if (state.page < state.totalPages) {
      fetchRooms(page: state.page + 1);
    }
  }

  void prevPage() {
    if (state.page > 1) {
      fetchRooms(page: state.page - 1);
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final lobbyProvider = StateNotifierProvider<LobbyNotifier, LobbyState>(
  (ref) => LobbyNotifier(ref),
);
