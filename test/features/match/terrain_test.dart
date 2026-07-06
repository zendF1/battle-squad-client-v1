import 'package:flutter_test/flutter_test.dart';
import 'package:battle_squad_v1/features/match/game/terrain_component.dart';

void main() {
  group('TerrainData', () {
    test('generates grassland_valley terrain correctly', () {
      final terrain = TerrainData(width: 1600, height: 900, mapId: 'grassland_valley');
      expect(terrain.getTerrainHeight(0), closeTo(550, 1));
      expect(terrain.isSolid(0, 560), true);
      expect(terrain.isSolid(0, 540), false);
    });
    test('generates frozen_peak terrain correctly', () {
      final terrain = TerrainData(width: 1600, height: 900, mapId: 'frozen_peak');
      expect(terrain.getTerrainHeight(0), closeTo(560, 1));
    });
    test('generates steel_base terrain correctly', () {
      final terrain = TerrainData(width: 1600, height: 900, mapId: 'steel_base');
      expect(terrain.getTerrainHeight(500), closeTo(400, 1));
      expect(terrain.getTerrainHeight(0), closeTo(600, 1));
    });
    test('destroyCircle clears terrain', () {
      final terrain = TerrainData(width: 1600, height: 900, mapId: 'grassland_valley');
      expect(terrain.isSolid(100, 560), true);
      terrain.destroyCircle(100, 560, 20);
      expect(terrain.isSolid(100, 560), false);
    });
  });
}
