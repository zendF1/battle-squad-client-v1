import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ReportPlayerDialog extends StatefulWidget {
  final List<String> opponentPlayerIds;
  final Map<String, String> playerNames;
  final String matchId;

  const ReportPlayerDialog({
    super.key,
    required this.opponentPlayerIds,
    required this.playerNames,
    required this.matchId,
  });

  @override
  State<ReportPlayerDialog> createState() => _ReportPlayerDialogState();
}

class _ReportPlayerDialogState extends State<ReportPlayerDialog> {
  String? _selectedPlayerId;
  String _category = 'cheat';
  final _descriptionController = TextEditingController();

  static const _categories = {
    'cheat': 'Cheating',
    'abuse': 'Abusive Behavior',
    'afk': 'AFK / Idle',
    'payment_fraud': 'Payment Fraud',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    if (widget.opponentPlayerIds.length == 1) {
      _selectedPlayerId = widget.opponentPlayerIds.first;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Report Player',
          style: TextStyle(color: AppColors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player selection
            if (widget.opponentPlayerIds.length > 1) ...[
              const Text('Select Player',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _selectedPlayerId,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: widget.opponentPlayerIds.map((id) {
                  return DropdownMenuItem(
                    value: id,
                    child: Text(widget.playerNames[id] ?? id.substring(0, 8)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedPlayerId = v),
              ),
              const SizedBox(height: 16),
            ],

            // Category
            const Text('Reason',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _category,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _categories.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 16),

            // Description
            const Text('Description (optional)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 4),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 200,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Describe the issue...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _selectedPlayerId != null
              ? () {
                  Navigator.pop(context, {
                    'targetPlayerId': _selectedPlayerId,
                    'matchId': widget.matchId,
                    'category': _category,
                    'description': _descriptionController.text.trim(),
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Report'),
        ),
      ],
    );
  }
}
