import 'package:battle_squad_v1/core/theme/app_theme.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlayerComponent extends PositionComponent {
  final String playerId;
  String displayName;
  final String characterId;
  final int teamId;
  int hp;
  final int maxHp;
  bool isAlive;

  PlayerComponent({
    required this.playerId,
    required this.displayName,
    required this.characterId,
    required this.teamId,
    required this.hp,
    required this.maxHp,
    required this.isAlive,
    required Vector2 initialPosition,
  }) : super(
          size: Vector2(32, 48),
          anchor: Anchor.bottomCenter,
          position: initialPosition,
        );

  Color get _bodyColor => AppTheme.characterColor(characterId);

  @override
  void render(Canvas canvas) {
    if (!isAlive) return;

    // Body
    final bodyPaint = Paint()..color = _bodyColor;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 8, 32, 36),
      const Radius.circular(6),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Head circle
    canvas.drawCircle(
      const Offset(16, 6),
      8,
      Paint()..color = _bodyColor,
    );

    // Name label (truncated to 6 chars)
    final name = displayName.length > 6
        ? displayName.substring(0, 6)
        : displayName;
    final namePainter = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    namePainter.layout();
    namePainter.paint(
      canvas,
      Offset((32 - namePainter.width) / 2, -14),
    );

    // HP bar background
    final hpBarBg = Paint()..color = Colors.black54;
    canvas.drawRect(Rect.fromLTWH(0, -8, 32, 4), hpBarBg);

    // HP bar fill
    final ratio = (hp / maxHp).clamp(0.0, 1.0);
    final hpColor = ratio > 0.5
        ? Colors.green
        : ratio > 0.25
            ? Colors.orange
            : Colors.red;
    final hpPaint = Paint()..color = hpColor;
    canvas.drawRect(Rect.fromLTWH(0, -8, 32 * ratio, 4), hpPaint);
  }

  void updateFromState({
    required int newHp,
    required bool alive,
    Vector2? newPos,
  }) {
    hp = newHp;
    isAlive = alive;
    if (newPos != null) {
      position = newPos;
    }
  }
}
