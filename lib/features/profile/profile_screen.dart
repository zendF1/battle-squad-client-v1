import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/error_snackbar.dart';
import 'inventory_grid.dart';
import 'match_history_list.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(profileProvider.notifier).fetch(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load profile',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.read(profileProvider.notifier).fetch(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => _ProfileBody(profile: profile),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final dynamic profile;

  const _ProfileBody({required this.profile});

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Display Name',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: AppColors.textSecondary),
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              await ref
                  .read(profileProvider.notifier)
                  .updateDisplayName(name);
              if (context.mounted) {
                final state = ref.read(profileProvider);
                state.whenOrNull(
                  error: (e, _) =>
                      showErrorSnackbar(context, 'Failed to update name'),
                  data: (_) =>
                      showSuccessSnackbar(context, 'Display name updated'),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final historyAsync = ref.watch(matchHistoryProvider(1));

    // EXP needed per level — simple formula: level * 100
    final expNeeded = profile.level * 100;
    final expProgress = (profile.exp / expNeeded).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar + name row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _showEditNameDialog(
                                  context, ref, profile.displayName),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      profile.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.edit,
                                      size: 16,
                                      color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Level ${profile.level}',
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // EXP bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EXP: ${profile.exp} / $expNeeded',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                          Text(
                            '${(expProgress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: expProgress,
                          backgroundColor: AppColors.primary,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.accent),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Currency display
                  CurrencyDisplay(coins: profile.coin, gems: profile.gem),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Inventory section
          Text('Inventory',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          inventoryAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              'Failed to load inventory',
              style:
                  const TextStyle(color: AppColors.error),
            ),
            data: (items) => InventoryGrid(items: items),
          ),

          const SizedBox(height: 24),

          // Match history section
          Text('Match History',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          historyAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Text(
              'Failed to load match history',
              style: TextStyle(color: AppColors.error),
            ),
            data: (entries) => MatchHistoryList(entries: entries),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
