import 'dart:async';

import 'package:battle_squad_v1/core/ws/ws_events.dart';
import 'package:battle_squad_v1/core/ws/ws_manager.dart';
import 'package:battle_squad_v1/features/match/match_provider.dart';
import 'package:battle_squad_v1/shared/models/match_models.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeWsManager extends WsManager {
  FakeWsManager() : super('ws://test');

  final controller = StreamController<WsEvent>.broadcast();
  final sent = <String>[];

  @override
  Stream<WsEvent> get eventStream => controller.stream;

  @override
  void send(String event, Map<String, dynamic> data) => sent.add(event);
}

MatchState matchState(String matchId) => MatchState(
  matchId: matchId,
  roomId: 'r',
  mode: 'pvp',
  mapId: 'm',
  turnIndex: 0,
  currentPlayerId: 'p1',
  wind: WindState.fromJson({'direction': 0, 'power': 0}),
  players: const {},
  status: 'in_progress',
  turnOrder: const ['p1'],
  turnTimeLeft: 20,
  activeEffects: const [],
);

TerrainSnapshot terrain(int version) => TerrainSnapshot(
  width: 1,
  height: 1,
  version: version,
  solid: 'AQ==',
  destructible: 'AQ==',
);

ProjectileResult explosion(int version) => ProjectileResult(
  projectileId: 'shot$version',
  ownerPlayerId: 'p1',
  path: const [],
  explosionPoint: Vector2Model(x: 0, y: 0),
  explosionRadius: 10,
  terrainDestroyed: true,
  terrainVersion: version,
);

void main() {
  late FakeWsManager ws;
  late MatchNotifier notifier;

  setUp(() {
    ws = FakeWsManager();
    notifier = MatchNotifier(ws);
  });

  Future<void> emit(WsEvent e) async {
    ws.controller.add(e);
    await Future<void>.delayed(Duration.zero);
  }

  test('a version gap requests a resync', () async {
    await emit(MatchStartedEvent(matchState('a'), terrain(0)));
    await emit(ProjectileResultEvent(explosion(1)));
    expect(ws.sent, isEmpty);
    await emit(ProjectileResultEvent(explosion(3)));
    expect(ws.sent, ['Reconnect']);
    expect(notifier.state!.terrainOps.length, 2);
  });

  test(
    'sync for the same match keeps result and pending projectiles',
    () async {
      await emit(MatchStartedEvent(matchState('a'), terrain(0)));
      await emit(ProjectileResultEvent(explosion(1)));
      await emit(MatchEndedEvent(MatchEndedData(winningTeam: 1)));
      final synced = terrain(1);
      await emit(MatchStateSyncEvent(matchState('a'), synced));

      final data = notifier.state!;
      expect(data.endedData?.winningTeam, 1);
      expect(data.projectileQueue.length, 1);
      expect(data.terrain, same(synced));
      expect(data.terrainOps, isEmpty);
      expect(data.terrainVersion, 1);
    },
  );

  test('a new match starts clean', () async {
    await emit(MatchStartedEvent(matchState('a'), terrain(0)));
    await emit(MatchEndedEvent(MatchEndedData(winningTeam: 1)));
    await emit(MatchStartedEvent(matchState('b'), terrain(0)));
    expect(notifier.state!.endedData, isNull);
    expect(notifier.state!.projectileQueue, isEmpty);
  });
}
