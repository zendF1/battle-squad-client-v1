import 'package:battle_squad_v1/shared/models/match_models.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ProjectileComponent extends PositionComponent {
  final List<ProjectileStep> path;
  final VoidCallback onComplete;

  double _elapsed = 0;
  int _currentIndex = 0;
  bool _done = false;

  ProjectileComponent({
    required this.path,
    required this.onComplete,
  }) : super(size: Vector2(12, 12), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);

    if (_done || path.isEmpty) return;

    _elapsed += dt;

    if (path.length == 1) {
      position = Vector2(path[0].position.x, path[0].position.y);
      _complete();
      return;
    }

    // Find current segment based on elapsed time
    while (_currentIndex < path.length - 2 &&
        _elapsed >= path[_currentIndex + 1].time) {
      _currentIndex++;
    }

    final current = path[_currentIndex];
    final next = _currentIndex + 1 < path.length
        ? path[_currentIndex + 1]
        : null;

    if (next == null || _elapsed >= path.last.time) {
      position = Vector2(path.last.position.x, path.last.position.y);
      _complete();
      return;
    }

    // Interpolate between current and next
    final segStart = current.time;
    final segEnd = next.time;
    final segDuration = segEnd - segStart;

    final t = segDuration <= 0
        ? 1.0
        : ((_elapsed - segStart) / segDuration).clamp(0.0, 1.0);

    final x = current.position.x + (next.position.x - current.position.x) * t;
    final y = current.position.y + (next.position.y - current.position.y) * t;
    position = Vector2(x, y);
  }

  void _complete() {
    if (!_done) {
      _done = true;
      onComplete();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Orange trail (larger, semi-transparent)
    final trailPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 6, trailPaint);

    // White projectile core
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 4, corePaint);
  }
}
