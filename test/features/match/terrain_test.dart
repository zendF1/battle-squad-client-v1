import 'dart:convert';
import 'dart:typed_data';

import 'package:battle_squad_v1/features/match/game/terrain_component.dart';
import 'package:battle_squad_v1/shared/models/match_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Encodes a 0/1 mask the same way the server does (see terrain_snapshot.go).
String encodeMaskRle(List<int> mask) {
  final out = <int>[];
  void writeVarint(int v) {
    while (v >= 0x80) {
      out.add((v & 0x7f) | 0x80);
      v >>= 7;
    }
    out.add(v);
  }

  var current = 0;
  var run = 0;
  for (final bit in mask) {
    if (bit != current) {
      writeVarint(run);
      current = bit;
      run = 0;
    }
    run++;
  }
  writeVarint(run);
  return base64Encode(Uint8List.fromList(out));
}

/// 200x100 terrain: solid from y >= 50; columns x >= 100 are indestructible.
TerrainSnapshot flatSnapshot({int version = 0}) {
  const w = 200, h = 100;
  final solid = List<int>.generate(w * h, (i) => i ~/ w >= 50 ? 1 : 0);
  final destructible = List<int>.generate(
    w * h,
    (i) => i ~/ w >= 50 && i % w < 100 ? 1 : 0,
  );
  return TerrainSnapshot(
    width: w,
    height: h,
    version: version,
    solid: encodeMaskRle(solid),
    destructible: encodeMaskRle(destructible),
  );
}

void main() {
  group('decodeMaskRle', () {
    test('decodes multi-byte varint runs', () {
      final mask = List<int>.generate(1000, (i) => i >= 300 && i < 700 ? 1 : 0);
      expect(decodeMaskRle(encodeMaskRle(mask), 1000), mask);
    });

    test('rejects a mask of the wrong length', () {
      final encoded = encodeMaskRle(List<int>.filled(10, 1));
      expect(() => decodeMaskRle(encoded, 11), throwsFormatException);
      expect(() => decodeMaskRle(encoded, 9), throwsFormatException);
    });

    test('decodes a snapshot produced by the Go server', () {
      // 4x3 grid of 16px cells: tiles {{0,0,0,0},{0,1,1,0},{2,2,1,1}},
      // brick 1 destructible, brick 2 indestructible.
      final terrain = TerrainData.fromSnapshot(
        TerrainSnapshot.fromJson(
          jsonDecode(
                '{"width":64,"height":48,"version":0,'
                '"solid":"kAggICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgEIAI",'
                '"destructible":"kAggICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgMCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA="}',
              )
              as Map<String, dynamic>,
        ),
        mapId: 'fixture',
      );
      expect(terrain.isSolid(8, 8), false);
      expect(terrain.isSolid(8, 20), false);
      expect(terrain.isSolid(20, 20), true);
      expect(terrain.isDestructible(20, 20), true);
      expect(terrain.isSolid(8, 40), true);
      expect(terrain.isDestructible(8, 40), false);
      expect(terrain.isDestructible(40, 40), true);
    });
  });

  group('TerrainData', () {
    test('takes size and masks from the snapshot', () {
      final terrain = TerrainData.fromSnapshot(
        flatSnapshot(),
        mapId: 'grassland_valley',
      );
      expect(terrain.width, 200);
      expect(terrain.height, 100);
      expect(terrain.isSolid(10, 49), false);
      expect(terrain.isSolid(10, 50), true);
      expect(terrain.getLandingY(10, 0), 50);
    });

    test('destroyCircle keeps indestructible pixels', () {
      final terrain = TerrainData.fromSnapshot(flatSnapshot(), mapId: 'm');
      terrain.destroyCircle(100, 60, 10);
      expect(terrain.isSolid(95, 60), false);
      expect(terrain.isSolid(105, 60), true);
    });

    test('skips explosions already in the snapshot or applied', () {
      final terrain = TerrainData.fromSnapshot(
        flatSnapshot(version: 3),
        mapId: 'm',
      );
      terrain.destroyCircle(20, 60, 5, version: 3);
      expect(terrain.isSolid(20, 60), true, reason: 'version 3 is in snapshot');

      terrain.destroyCircle(20, 60, 5, version: 5);
      expect(terrain.isSolid(20, 60), false, reason: 'out-of-order op applies');
      terrain.destroyCircle(40, 60, 5, version: 4);
      expect(terrain.isSolid(40, 60), false);
    });

    test('loadSnapshot restores terrain and resets applied versions', () {
      final terrain = TerrainData.fromSnapshot(flatSnapshot(), mapId: 'm');
      terrain.destroyCircle(20, 60, 5, version: 1);
      terrain.loadSnapshot(flatSnapshot());
      expect(terrain.isSolid(20, 60), true);
      terrain.destroyCircle(20, 60, 5, version: 1);
      expect(terrain.isSolid(20, 60), false);
    });
  });
}
