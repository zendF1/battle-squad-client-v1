import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Renders a dotted trajectory arc using the same physics as the server.
class TrajectoryComponent extends PositionComponent {
  // Physics constants matching server (shooting.go)
  static const double _gravity = 200.0;
  static const double _windScale = 30.0;
  static const double _timeStep = 0.05;
  static const int _maxSteps = 80; // 4 seconds of flight

  Vector2 _origin = Vector2.zero();
  double _angleDeg = 45;
  double _power = 50;
  int _windDirection = 0;
  int _windPower = 0;
  bool _visible = false;

  void update2({
    required Vector2 origin,
    required double angleDeg,
    required double power,
    required int windDirection,
    required int windPower,
  }) {
    _origin = origin;
    _angleDeg = angleDeg;
    _power = power;
    _windDirection = windDirection;
    _windPower = windPower;
    _visible = true;
  }

  void hide() {
    _visible = false;
  }

  List<Vector2> _computePath() {
    final angleRad = _angleDeg * pi / 180.0;
    final speed = _power * 6.0;
    var vx = speed * cos(angleRad);
    var vy = -speed * sin(angleRad);
    var px = _origin.x;
    var py = _origin.y;

    final windForceX = _windDirection * _windPower * _windScale;

    final points = <Vector2>[Vector2(px, py)];
    for (var i = 0; i < _maxSteps; i++) {
      vx += windForceX * _timeStep;
      vy += _gravity * _timeStep;
      px += vx * _timeStep;
      py += vy * _timeStep;

      points.add(Vector2(px, py));

      // Stop if out of bounds
      if (px < -50 || px > 1650 || py > 950) break;
    }
    return points;
  }

  @override
  void render(Canvas canvas) {
    if (!_visible) return;

    final points = _computePath();
    if (points.length < 2) return;

    final dotPaint = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.fill;

    final fadePaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.fill;

    for (var i = 1; i < points.length; i++) {
      // Draw every other point for dotted effect
      if (i % 2 == 0) continue;
      final p = points[i];
      final t = i / points.length;
      canvas.drawCircle(
        Offset(p.x, p.y),
        t < 0.5 ? 3 : 2,
        t < 0.7 ? dotPaint : fadePaint,
      );
    }
  }
}
