import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ExplosionComponent extends PositionComponent {
  final double radius;
  final VoidCallback onComplete;

  static const double _duration = 0.5;
  double _elapsed = 0;
  bool _done = false;

  ExplosionComponent({
    required Vector2 center,
    required this.radius,
    required this.onComplete,
  }) : super(
          position: center,
          anchor: Anchor.center,
          size: Vector2.all(0),
        );

  double get _progress => (_elapsed / _duration).clamp(0.0, 1.0);
  double get _currentRadius => radius * _progress;

  @override
  void update(double dt) {
    super.update(dt);
    if (_done) return;

    _elapsed += dt;
    if (_elapsed >= _duration) {
      _done = true;
      onComplete();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_done) return;

    final currentR = _currentRadius;
    final alpha = (1.0 - _progress).clamp(0.0, 1.0);

    // Outer orange ring
    final outerPaint = Paint()
      ..color = Colors.orange.withValues(alpha: alpha * 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, currentR, outerPaint);

    // Inner yellow core (smaller)
    if (currentR > 4) {
      final innerPaint = Paint()
        ..color = Colors.yellow.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, currentR * 0.5, innerPaint);
    }
  }
}
