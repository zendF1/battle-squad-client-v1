import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CancelZoneComponent extends PositionComponent {
  static const double radius = 24;
  bool isHighlighted = false;

  CancelZoneComponent()
      : super(
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  @override
  bool containsPoint(Vector2 point) {
    return position.distanceTo(point) <= radius;
  }

  void show(Vector2 playerPos) {
    position = playerPos + Vector2(0, -60);
    isHighlighted = false;
  }

  void hide() {
    position = Vector2(-200, -200);
    isHighlighted = false;
  }

  @override
  void render(Canvas canvas) {
    final bgColor = isHighlighted
        ? const Color(0xCCFF1744)
        : const Color(0x88000000);

    final bgPaint = Paint()..color = bgColor;
    canvas.drawCircle(Offset(radius, radius), radius, bgPaint);

    final borderPaint = Paint()
      ..color = isHighlighted ? const Color(0xFFFF1744) : const Color(0xAAFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(radius, radius), radius, borderPaint);

    final xPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const inset = 10.0;
    canvas.drawLine(
      const Offset(inset, inset),
      Offset(radius * 2 - inset, radius * 2 - inset),
      xPaint,
    );
    canvas.drawLine(
      Offset(radius * 2 - inset, inset),
      Offset(inset, radius * 2 - inset),
      xPaint,
    );
  }
}
