import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// TerrainData — pure Dart, no Flame dependency
// ---------------------------------------------------------------------------

class TerrainData {
  final int width;
  final int height;
  final String mapId;

  late final Uint8List _mask;
  bool _needsRepaint = true;

  TerrainData({
    required this.width,
    required this.height,
    required this.mapId,
  }) {
    _mask = Uint8List(width * height);
    _generate();
  }

  void _generate() {
    for (int x = 0; x < width; x++) {
      final terrainHeight = getTerrainHeight(x).round();
      for (int y = terrainHeight; y < height; y++) {
        _mask[y * width + x] = 1;
      }
    }
  }

  double getTerrainHeight(int x) {
    switch (mapId) {
      case 'grassland_valley':
        return 550 + 100 * sin(x * 0.003) + 40 * sin(x * 0.01);
      case 'frozen_peak':
        return 500 + 120 * sin(x * 0.005) + 60 * cos(x * 0.015);
      case 'steel_base':
        if ((x > 300 && x < 600) || (x > 1000 && x < 1300)) {
          return 400;
        }
        return 600;
      default:
        return 550 + 100 * sin(x * 0.003) + 40 * sin(x * 0.01);
    }
  }

  bool isSolid(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return _mask[y * width + x] == 1;
  }

  void destroyCircle(double cx, double cy, double radius) {
    // Round center to match server-side DestroyCircle behavior
    final icx = cx.round();
    final icy = cy.round();
    final ir = radius.round();
    final r2 = radius * radius;

    for (int y = icy - ir; y <= icy + ir; y++) {
      for (int x = icx - ir; x <= icx + ir; x++) {
        if (x < 0 || x >= width || y < 0 || y >= height) continue;
        final dx = (x - icx).toDouble();
        final dy = (y - icy).toDouble();
        if (dx * dx + dy * dy <= r2) {
          _mask[y * width + x] = 0;
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
      if (_mask[y * width + x] == 1) return y;
    }
    return height;
  }

  bool get isDirty => _needsRepaint;

  void markClean() => _needsRepaint = false;

  void markDirty() => _needsRepaint = true;
}

// ---------------------------------------------------------------------------
// TerrainComponent — Flame rendering component
// ---------------------------------------------------------------------------

class TerrainComponent extends PositionComponent {
  final TerrainData terrainData;
  ui.Image? _cachedImage;

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
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final w = terrainData.width.toDouble();
    final h = terrainData.height.toDouble();

    // Sky background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = _skyColor,
    );

    // Terrain pixels — draw contiguous solid segments per column
    final terrainPaint = Paint()..color = _terrainColor;
    for (int x = 0; x < terrainData.width; x++) {
      int? segStart;
      for (int y = 0; y < terrainData.height; y++) {
        if (terrainData.isSolid(x, y)) {
          segStart ??= y;
        } else if (segStart != null) {
          canvas.drawRect(
            Rect.fromLTWH(
              x.toDouble(),
              segStart.toDouble(),
              1,
              (y - segStart).toDouble(),
            ),
            terrainPaint,
          );
          segStart = null;
        }
      }
      // Close segment that extends to bottom
      if (segStart != null) {
        canvas.drawRect(
          Rect.fromLTWH(
            x.toDouble(),
            segStart.toDouble(),
            1,
            (terrainData.height - segStart).toDouble(),
          ),
          terrainPaint,
        );
      }
    }

    final picture = recorder.endRecording();
    _cachedImage = await picture.toImage(terrainData.width, terrainData.height);
    terrainData.markClean();
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
  void render(Canvas canvas) {
    if (_cachedImage != null) {
      canvas.drawImage(_cachedImage!, Offset.zero, Paint());
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (terrainData.isDirty) {
      _rebuildImage();
    }
  }

  void onTerrainDestroyed(double cx, double cy, double radius) {
    terrainData.destroyCircle(cx, cy, radius);
  }
}
