import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    await _checkVersionPolicy();
    if (mounted) {
      ref.read(authProvider.notifier).checkAuth();
    }
  }

  Future<void> _checkVersionPolicy() async {
    try {
      String platform;
      try {
        platform = Platform.isIOS ? 'ios' : 'android';
      } catch (_) {
        return; // Web or unsupported
      }

      final client = ref.read(apiClientProvider);
      final data = await client.get('/app/version-policy?platform=$platform');

      final minVersion = data['minVersion'] as String?;
      final recommendedVersion = data['recommendedVersion'] as String?;

      if (minVersion == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isVersionLower(currentVersion, minVersion)) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Update Required',
                  style: TextStyle(color: AppColors.error)),
              content: const Text(
                'A new version is required to continue playing. '
                'Please update the app.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    // TODO: Open store URL
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
          );
          return; // Block further loading
        }
      }

      if (recommendedVersion != null &&
          _isVersionLower(currentVersion, recommendedVersion)) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Update Available',
                  style: TextStyle(color: AppColors.warning)),
              content: const Text(
                'A new version is available. We recommend updating for the best experience.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Later',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    // TODO: Open store URL
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
          );
        }
      }
    } catch (_) {
      // Version check failed — proceed anyway
    }
  }

  bool _isVersionLower(String current, String target) {
    final curParts = current.split('.').map(int.tryParse).toList();
    final tarParts = target.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final c = i < curParts.length ? (curParts[i] ?? 0) : 0;
      final t = i < tarParts.length ? (tarParts[i] ?? 0) : 0;
      if (c < t) return true;
      if (c > t) return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
