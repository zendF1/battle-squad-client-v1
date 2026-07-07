import 'package:battle_squad_v1/core/theme/app_theme.dart';
import 'package:battle_squad_v1/features/match/game/terrain_component.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlayerComponent extends PositionComponent {
  final String playerId;
  final TerrainData terrainData;
  String displayName;
  final String characterId;
  final int teamId;
  int hp;
  final int maxHp;
  bool isAlive;

  // Gravity state
  static const double _gravity = 800.0; // px/s²
  double _fallVelocity = 0;
  bool _isFalling = false;

  // Server Y for anti-desync correction after landing
  double? _serverTargetY;

  PlayerComponent({
    required this.playerId,
    required this.terrainData,
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
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;

    final ix = position.x.round();
    final iy = position.y.round();
    final hasGround = terrainData.isSolid(ix, iy);

    if (hasGround && !_isFalling) {
      // Standing on solid ground — anti-desync snap to server Y
      if (_serverTargetY != null &&
          (_serverTargetY! - position.y).abs() > 1) {
        position.y = _serverTargetY!;
        _serverTargetY = null;
      }
      return;
    }

    // Lost ground support — start falling
    if (!_isFalling) {
      _isFalling = true;
      _fallVelocity = 0;
    }

    // Apply gravity
    _fallVelocity += _gravity * dt;
    final prevY = position.y;
    position.y += _fallVelocity * dt;

    // Scan from prevY to newY for the first solid pixel (prevents tunneling)
    final scanStart = prevY.round();
    final scanEnd = position.y.round();
    for (int y = scanStart; y <= scanEnd; y++) {
      if (terrainData.isSolid(ix, y)) {
        position.y = y.toDouble();
        _fallVelocity = 0;
        _isFalling = false;

        // Snap to server Y if close enough
        if (_serverTargetY != null &&
            (_serverTargetY! - position.y).abs() <= 2) {
          position.y = _serverTargetY!;
          _serverTargetY = null;
        }
        return;
      }
    }

    // Fell off map bottom
    if (position.y >= terrainData.height) {
      position.y = terrainData.height.toDouble();
      _fallVelocity = 0;
      _isFalling = false;
    }
  }

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

  /// Update from server state. X, HP, isAlive applied immediately.
  /// Y is stored as server target — gravity handles the actual fall.
  void updateFromState({
    required int newHp,
    required bool alive,
    double? newX,
    double? serverY,
  }) {
    hp = newHp;
    isAlive = alive;
    if (newX != null) {
      position.x = newX;
    }
    if (serverY != null) {
      _serverTargetY = serverY;
      // If moving UP or same level (e.g. teleport, move), snap immediately
      if (serverY <= position.y) {
        position.y = serverY;
        _serverTargetY = null;
        _isFalling = false;
        _fallVelocity = 0;
      }
    }
  }
}
