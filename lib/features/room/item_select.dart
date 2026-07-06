import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class _ItemInfo {
  final String id;
  final String label;
  final IconData icon;

  const _ItemInfo({required this.id, required this.label, required this.icon});
}

const _itemCatalog = [
  _ItemInfo(id: 'medkit', label: 'Med Kit', icon: Icons.healing),
  _ItemInfo(id: 'teleport', label: 'Teleport', icon: Icons.swap_horiz),
  _ItemInfo(id: 'power_shot', label: 'Power Shot', icon: Icons.bolt),
  _ItemInfo(id: 'drill_bomb', label: 'Drill Bomb', icon: Icons.hardware),
  _ItemInfo(id: 'spider_net', label: 'Spider Net', icon: Icons.grid_on),
  _ItemInfo(id: 'freeze_bomb', label: 'Freeze Bomb', icon: Icons.ac_unit),
  _ItemInfo(id: 'air_strike', label: 'Air Strike', icon: Icons.flight),
  _ItemInfo(id: 'wind_stopper', label: 'Wind Stop', icon: Icons.air),
];

const _maxItems = 3;

class ItemSelect extends StatelessWidget {
  final List<String> availableItems;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;

  const ItemSelect({
    super.key,
    required this.availableItems,
    required this.selectedItems,
    required this.onChanged,
  });

  List<_ItemInfo> get _available {
    if (availableItems.isEmpty) return _itemCatalog;
    return _itemCatalog.where((i) => availableItems.contains(i.id)).toList();
  }

  void _toggle(String id) {
    final updated = List<String>.from(selectedItems);
    if (updated.contains(id)) {
      updated.remove(id);
    } else if (updated.length < _maxItems) {
      updated.add(id);
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final items = _available;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Items',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${selectedItems.length}/$_maxItems selected',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = selectedItems.contains(item.id);
            final isFull = selectedItems.length >= _maxItems && !isSelected;
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 14,
                    color: isSelected
                        ? AppColors.textPrimary
                        : isFull
                            ? AppColors.textSecondary.withValues(alpha: 0.4)
                            : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(item.label),
                ],
              ),
              selected: isSelected,
              onSelected: isFull ? null : (_) => _toggle(item.id),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.accent.withValues(alpha: 0.3),
              checkmarkColor: AppColors.accent,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.textPrimary
                    : isFull
                        ? AppColors.textSecondary.withValues(alpha: 0.4)
                        : AppColors.textSecondary,
                fontSize: 12,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppColors.accent
                    : isFull
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.primary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
