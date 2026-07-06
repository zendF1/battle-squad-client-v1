import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/error_snackbar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _soundEnabled = true;
  bool _deletingAccount = false;

  Future<void> _onDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppColors.error),
        ),
        content: const Text(
          'Are you sure you want to request account deletion? '
          'This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.post('/account/deletion/request');
      if (mounted) {
        showSuccessSnackbar(
            context, 'Account deletion requested. You will be logged out.');
        await ref.read(authProvider.notifier).logout();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Failed to request deletion: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  Future<void> _onLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Logout',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sound toggle
          Card(
            child: SwitchListTile(
              value: _soundEnabled,
              onChanged: (v) => setState(() => _soundEnabled = v),
              title: const Text(
                'Sound',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: const Text(
                'Enable / disable in-game sound effects',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              activeThumbColor: AppColors.accent,
              secondary: const Icon(Icons.volume_up,
                  color: AppColors.textSecondary),
            ),
          ),

          const SizedBox(height: 16),

          // Account section
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          // Delete account
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: AppColors.error),
              title: const Text(
                'Delete Account',
                style: TextStyle(color: AppColors.error),
              ),
              subtitle: const Text(
                'Permanently delete your account and all data',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              trailing: _deletingAccount
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
              onTap: _deletingAccount ? null : _onDeleteAccount,
            ),
          ),

          const SizedBox(height: 24),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Version text
          const Center(
            child: Text(
              'Battle Squad v1.0.0',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
