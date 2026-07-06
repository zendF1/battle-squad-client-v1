import 'package:battle_squad_v1/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ItemSkillBar extends StatelessWidget {
  final List<String> items;
  final int skillCooldown;
  final String? activeItemId;
  final String actionMode; // 'weapon' | 'skill' | item id
  final ValueChanged<String> onActionModeChanged;
  final ValueChanged<String?> onActiveItemChanged;

  const ItemSkillBar({
    super.key,
    required this.items,
    required this.skillCooldown,
    required this.activeItemId,
    required this.actionMode,
    required this.onActionModeChanged,
    required this.onActiveItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Weapon button
          _ActionButton(
            icon: Icons.rocket_launch,
            label: 'Weapon',
            isActive: actionMode == 'weapon',
            onTap: () {
              onActionModeChanged('weapon');
              onActiveItemChanged(null);
            },
          ),
          const SizedBox(width: 6),
          // Skill button
          _ActionButton(
            icon: Icons.bolt,
            label: skillCooldown > 0 ? 'CD:$skillCooldown' : 'Skill',
            isActive: actionMode == 'skill',
            isDisabled: skillCooldown > 0,
            onTap: skillCooldown > 0
                ? null
                : () {
                    onActionModeChanged('skill');
                    onActiveItemChanged(null);
                  },
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(width: 6),
            const VerticalDivider(
              color: AppColors.primary,
              thickness: 1,
              width: 12,
            ),
            ...items.take(3).map((itemId) {
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _ActionButton(
                  icon: _iconForItem(itemId),
                  label: _labelForItem(itemId),
                  isActive: activeItemId == itemId,
                  onTap: () {
                    if (activeItemId == itemId) {
                      onActiveItemChanged(null);
                      onActionModeChanged('weapon');
                    } else {
                      onActiveItemChanged(itemId);
                      onActionModeChanged('item');
                    }
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  IconData _iconForItem(String itemId) {
    return switch (itemId) {
      'shield' => Icons.shield,
      'heal' || 'potion' => Icons.favorite,
      'bomb' => Icons.local_fire_department,
      'rope' => Icons.cable,
      _ => Icons.inventory_2,
    };
  }

  String _labelForItem(String itemId) {
    // Capitalize first letter, truncate to 5 chars
    final name = itemId.length > 5 ? itemId.substring(0, 5) : itemId;
    return name[0].toUpperCase() + name.substring(1);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive ? AppColors.accent : AppColors.primary;
    final bgColor = isActive
        ? AppColors.accent.withValues(alpha: 0.25)
        : Colors.transparent;
    final textColor = isDisabled
        ? AppColors.textSecondary
        : isActive
            ? AppColors.accent
            : AppColors.textPrimary;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
