import 'package:flutter_test/flutter_test.dart';
import 'package:battle_squad_v1/core/ws/ws_events.dart';

void main() {
  group('WsEnvelope', () {
    test('parses from JSON', () {
      final json = {'event': 'TurnTimerTick', 'data': {'timeLeft': 15}};
      final envelope = WsEnvelope.fromJson(json);
      expect(envelope.event, 'TurnTimerTick');
      expect(envelope.data['timeLeft'], 15);
    });
    test('serializes to JSON', () {
      final envelope = WsEnvelope(event: 'Shoot', data: {'angle': 45.0});
      final json = envelope.toJson();
      expect(json['event'], 'Shoot');
      expect((json['data'] as Map)['angle'], 45.0);
    });
  });

  group('parseWsEvent', () {
    test('parses TurnTimerTick', () {
      final envelope = WsEnvelope(event: 'TurnTimerTick', data: {'timeLeft': 10});
      final event = parseWsEvent(envelope);
      expect(event, isA<TurnTimerTickEvent>());
      expect((event as TurnTimerTickEvent).timeLeft, 10);
    });
    test('parses SkillUsed', () {
      final envelope = WsEnvelope(event: 'SkillUsed', data: {'playerId': 'p1', 'skillId': 'healing_bloom', 'hp': 95});
      final event = parseWsEvent(envelope);
      expect(event, isA<SkillUsedEvent>());
      final skill = event as SkillUsedEvent;
      expect(skill.playerId, 'p1');
      expect(skill.skillId, 'healing_bloom');
      expect(skill.hp, 95);
    });
    test('returns null for unknown event', () {
      final envelope = WsEnvelope(event: 'Unknown', data: {});
      expect(parseWsEvent(envelope), isNull);
    });
  });
}
