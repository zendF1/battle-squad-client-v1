import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class _CharacterInfo {
  final String id;
  final String name;
  final String role;
  final int hp;
  final int dmg;
  final int def;

  const _CharacterInfo({
    required this.id,
    required this.name,
    required this.role,
    required this.hp,
    required this.dmg,
    required this.def,
  });
}

const _characters = [
  _CharacterInfo(id: 'rookie', name: 'Rookie', role: 'Balanced', hp: 100, dmg: 50, def: 50),
  _CharacterInfo(id: 'tanko', name: 'Tanko', role: 'Tank', hp: 150, dmg: 35, def: 80),
  _CharacterInfo(id: 'spark', name: 'Spark', role: 'DPS', hp: 80, dmg: 80, def: 30),
  _CharacterInfo(id: 'flora', name: 'Flora', role: 'Support', hp: 90, dmg: 40, def: 60),
];

class CharacterSelect extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const CharacterSelect({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: _characters
          .map((c) => _CharacterCard(
                character: c,
                isSelected: selectedId == c.id,
                onTap: () => onSelect(c.id),
              ))
          .toList(),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final _CharacterInfo character;
  final bool isSelected;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.character,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.characterColor(character.id);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.primary,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  character.name,
                  style: TextStyle(
                    color: isSelected ? color : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle, color: color, size: 14),
              ],
            ),
            Text(
              character.role,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            _StatRow(label: 'HP', value: character.hp, color: AppColors.success),
            const SizedBox(height: 2),
            _StatRow(label: 'DMG', value: character.dmg, color: AppColors.error),
            const SizedBox(height: 2),
            _StatRow(label: 'DEF', value: character.def, color: AppColors.primary.withValues(alpha: 2.0)),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value / 150,
              minHeight: 4,
              backgroundColor: AppColors.primary.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 24,
          child: Text(
            '$value',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
