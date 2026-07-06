import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class CreateRoomResult {
  final String mode;
  final String mapId;
  final String? password;

  const CreateRoomResult({
    required this.mode,
    required this.mapId,
    this.password,
  });
}

class CreateRoomDialog extends StatefulWidget {
  const CreateRoomDialog({super.key});

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  String _mode = 'pvp_1v1';
  String _mapId = 'grassland_valley';
  final _passwordController = TextEditingController();

  static const _maps = [
    ('grassland_valley', 'Grassland Valley'),
    ('frozen_peak', 'Frozen Peak'),
    ('steel_base', 'Steel Base'),
  ];

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Create Room',
        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game Mode',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pvp_1v1', label: Text('1v1')),
                ButtonSegment(value: 'pvp_2v2', label: Text('2v2')),
              ],
              selected: {_mode},
              onSelectionChanged: (val) => setState(() => _mode = val.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.accent,
                selectedForegroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Map',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _mapId,
              dropdownColor: AppColors.surface,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.primary.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              items: _maps
                  .map(
                    (m) => DropdownMenuItem(
                      value: m.$1,
                      child: Text(m.$2),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _mapId = v ?? _mapId),
            ),
            const SizedBox(height: 16),
            const Text(
              'Password (optional)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Leave blank for public room',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.primary.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textPrimary,
          ),
          onPressed: () {
            final password = _passwordController.text.trim();
            Navigator.of(context).pop(
              CreateRoomResult(
                mode: _mode,
                mapId: _mapId,
                password: password.isEmpty ? null : password,
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
