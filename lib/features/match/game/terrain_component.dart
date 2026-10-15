import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:battle_squad_v1/shared/models/match_models.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// TerrainData — pure Dart, no Flame dependency
// ---------------------------------------------------------------------------

/// Pixel terrain built from the server's [TerrainSnapshot]. The server is the
/// source of truth; the client only replays explosions on top of a snapshot.
class TerrainData {
  final int width;
  final int height;
  final String mapId;

  late Uint8List _solid;
  late Uint8List _destructible;
  int _baseVersion = 0;
  final Set<int> _appliedVersions = {};
  bool _needsRepaint = true;

  TerrainData.fromSnapshot(TerrainSnapshot snapshot, {required this.mapId})
    : width = snapshot.width,
      height = snapshot.height {
    loadSnapshot(snapshot);
  }

  /// Replace the terrain with a newer server snapshot. Explosions with a
  /// version at or below the snapshot's are already included and get skipped.
  void loadSnapshot(TerrainSnapshot snapshot) {
    if (snapshot.width != width || snapshot.height != height) {
      throw ArgumentError(
        'snapshot ${snapshot.width}x${snapshot.height} does not match terrain ${width}x$height',
      );
    }
    _solid = decodeMaskRle(snapshot.solid, width * height);
    _destructible = decodeMaskRle(snapshot.destructible, width * height);
    _baseVersion = snapshot.version;
    _appliedVersions.clear();
    markDirty();
  }

  bool isSolid(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return _solid[y * width + x] == 1;
  }

  bool isDestructible(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return _destructible[y * width + x] == 1;
  }

  /// Mirrors server Terrain.DestroyCircle: clears solid pixels inside the
  /// circle unless they are indestructible. [version] is the server terrain
  /// version of this explosion; each version is applied at most once.
  /// Operations commute, so out-of-order application gives the same result.
  void destroyCircle(double cx, double cy, double radius, {int version = 0}) {
    if (version > 0) {
      if (version <= _baseVersion || !_appliedVersions.add(version)) return;
    }

    final icx = cx.round();
    final icy = cy.round();
    final ir = radius.round();
    final r2 = radius * radius;

    for (int y = icy - ir; y <= icy + ir; y++) {
      if (y < 0 || y >= height) continue;
      for (int x = icx - ir; x <= icx + ir; x++) {
        if (x < 0 || x >= width) continue;
        final dx = (x - icx).toDouble();
        final dy = (y - icy).toDouble();
        final i = y * width + x;
        if (dx * dx + dy * dy <= r2 && _destructible[i] == 1) {
          _solid[i] = 0;
        }
      }
    }
    markDirty();
  }

  /// Find the first solid Y scanning downward from [startY] at column [x].
  /// Returns [height] if no solid pixel is found (fell off map).
  int getLandingY(int x, int startY) {
    if (x < 0 || x >= width) return height;
    if (startY < 0) startY = 0;
    for (int y = startY; y < height; y++) {
      if (_solid[y * width + x] == 1) return y;
    }
    return height;
  }

  bool get isDirty => _needsRepaint;

  void markClean() => _needsRepaint = false;

  void markDirty() => _needsRepaint = true;
}

/// Decodes a server terrain mask: base64 of alternating air/solid run lengths
/// (starting with air) as unsigned LEB128 varints. Returns 1 for solid pixels.
Uint8List decodeMaskRle(String encoded, int length) {
  final bytes = base64Decode(encoded);
  final mask = Uint8List(length);
  var pos = 0;
  var solid = false;
  var i = 0;
  while (i < bytes.length) {
    var run = 0;
    var shift = 0;
    while (true) {
      if (i >= bytes.length) throw const FormatException('truncated varint');
      final b = bytes[i++];
      run |= (b & 0x7f) << shift;
      if (b & 0x80 == 0) break;
      shift += 7;
    }
    if (pos + run > length) {
      throw const FormatException('mask overflows terrain');
    }
    if (solid) mask.fillRange(pos, pos + run, 1);
    pos += run;
    solid = !solid;
  }
  if (pos != length) throw const FormatException('mask shorter than terrain');
  return mask;
}

// ---------------------------------------------------------------------------
// TerrainComponent — Flame rendering component
// ---------------------------------------------------------------------------

class TerrainComponent extends PositionComponent {
  final TerrainData terrainData;
  ui.Image? _cachedImage;
  bool _rebuilding = false;

  TerrainComponent(this.terrainData)
      : super(
          size: Vector2(
            terrainData.width.toDouble(),
            terrainData.height.toDouble(),
          ),
        );

  @override
  Future<void> onLoad() async {
    await _rebuildImage();
  }

  Future<void> _rebuildImage() async {
    // Mark clean before the async work so changes made meanwhile trigger another rebuild.
    terrainData.markClean();
    _rebuilding = true;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final w = terrainData.width.toDouble();
    final h = terrainData.height.toDouble();

    // Sky background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = _skyColor,
    );

    // Terrain pixels — draw contiguous segments per column; indestructible
    // pixels get a darker shade so players can tell them apart.
    final paints = [
      null,
      Paint()..color = _terrainColor,
      Paint()..color = Color.lerp(_terrainColor, Colors.black, 0.45)!,
    ];
    for (int x = 0; x < terrainData.width; x++) {
      int segStart = 0;
      int segKind = 0;
      for (int y = 0; y <= terrainData.height; y++) {
        final kind = y == terrainData.height
            ? 0
            : !terrainData.isSolid(x, y)
            ? 0
            : terrainData.isDestructible(x, y)
            ? 1
            : 2;
        if (kind == segKind) continue;
        final paint = paints[segKind];
        if (paint != null) {
          canvas.drawRect(
            Rect.fromLTWH(
              x.toDouble(),
              segStart.toDouble(),
              1,
              (y - segStart).toDouble(),
            ),
            paint,
          );
        }
        segStart = y;
        segKind = kind;
      }
    }

    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(
        terrainData.width,
        terrainData.height,
      );
      _cachedImage?.dispose();
      _cachedImage = image;
    } finally {
      picture.dispose();
      _rebuilding = false;
    }
  }

  Color get _skyColor {
    switch (terrainData.mapId) {
      case 'grassland_valley':
        return const Color(0xFF87CEEB); // sky blue
      case 'frozen_peak':
        return const Color(0xFFB0C4DE); // light steel blue / white-ish
      case 'steel_base':
        return const Color(0xFF708090); // slate grey
      default:
        return const Color(0xFF87CEEB);
    }
  }

  Color get _terrainColor {
    switch (terrainData.mapId) {
      case 'grassland_valley':
        return const Color(0xFF228B22); // forest green
      case 'frozen_peak':
        return const Color(0xFF00008B); // dark blue
      case 'steel_base':
        return const Color(0xFF2F4F4F); // dark slate grey
      default:
        return const Color(0xFF228B22);
    }
  }

  @override
  void onRemove() {
    _cachedImage?.dispose();
    _cachedImage = null;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (_cachedImage != null) {
      canvas.drawImage(_cachedImage!, Offset.zero, Paint());
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (terrainData.isDirty && !_rebuilding) {
      _rebuildImage();
    }
  }
}
