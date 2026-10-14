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
  bool _redeemingCode = false;
  String? _deletionStatus; // null = not checked, 'active', 'pending_deletion'
  bool _cancellingDeletion = false;

  @override
  void initState() {
    super.initState();
    _checkDeletionStatus();
  }

  Future<void> _checkDeletionStatus() async {
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.get('/account/deletion/status');
      if (mounted) {
        setState(() => _deletionStatus = data['status'] as String? ?? 'active');
      }
    } catch (_) {
      // Ignore - just don't show cancel button
    }
  }

  Future<void> _onCancelDeletion() async {
    setState(() => _cancellingDeletion = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.post('/account/deletion/cancel');
      if (mounted) {
        showSuccessSnackbar(context, 'Account deletion cancelled');
        setState(() => _deletionStatus = 'active');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Failed to cancel deletion: $e');
      }
    } finally {
      if (mounted) setState(() => _cancellingDeletion = false);
    }
  }

  Future<void> _onRedeemGiftCode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Redeem Gift Code',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter gift code',
            hintStyle: TextStyle(color: AppColors.textSecondary),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.of(ctx).pop(text);
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (code == null || code.isEmpty || !mounted) return;

    setState(() => _redeemingCode = true);
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.post('/giftcode/redeem', data: {'code': code});
      if (mounted) {
        final coins = data['rewardCoin'] as int? ?? 0;
        final gems = data['rewardGem'] as int? ?? 0;
        final items = (data['rewardItems'] as List<dynamic>?)?.length ?? 0;
        final parts = <String>[];
        if (coins > 0) parts.add('$coins coins');
        if (gems > 0) parts.add('$gems gems');
        if (items > 0) parts.add('$items items');
        showSuccessSnackbar(
            context, 'Redeemed! Received: ${parts.join(", ")}');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Failed to redeem: $e');
      }
    } finally {
      if (mounted) setState(() => _redeemingCode = false);
    }
  }

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

          // Gift code
          Card(
            child: ListTile(
              leading: const Icon(Icons.card_giftcard, color: AppColors.warning),
              title: const Text(
                'Redeem Gift Code',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: const Text(
                'Enter a gift code to receive rewards',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              trailing: _redeemingCode
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
              onTap: _redeemingCode ? null : _onRedeemGiftCode,
            ),
          ),

          const SizedBox(height: 16),

          // Linked accounts
          Text(
            'Linked Accounts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.g_mobiledata, color: AppColors.textPrimary),
                  title: const Text('Google Account',
                      style: TextStyle(color: AppColors.textPrimary)),
                  trailing: OutlinedButton(
                    onPressed: () async {
                      // TODO: Integrate google_sign_in
                      // final idToken = ...;
                      // try {
                      //   await ref.read(authProvider.notifier).linkProvider(
                      //     provider: 'google', idToken: idToken);
                      //   showSuccessSnackbar(context, 'Google linked!');
                      // } catch (e) {
                      //   showErrorSnackbar(context, 'Failed: $e');
                      // }
                    },
                    child: const Text('Link'),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.apple, color: AppColors.textPrimary),
                  title: const Text('Apple Account',
                      style: TextStyle(color: AppColors.textPrimary)),
                  trailing: OutlinedButton(
                    onPressed: () async {
                      // TODO: Integrate sign_in_with_apple
                    },
                    child: const Text('Link'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Account section
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          // Cancel pending deletion
          if (_deletionStatus == 'pending_deletion') ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.restore, color: AppColors.warning),
                title: const Text(
                  'Cancel Account Deletion',
                  style: TextStyle(color: AppColors.warning),
                ),
                subtitle: const Text(
                  'Your account is scheduled for deletion. Tap to cancel.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                trailing: _cancellingDeletion
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary),
                onTap: _cancellingDeletion ? null : _onCancelDeletion,
              ),
            ),
            const SizedBox(height: 8),
          ],

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
