import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/update/providers/app_update_provider.dart';
import '../config/runtime_config_provider.dart';
import '../constants/app_colors.dart';

class AppRuntimeGate extends ConsumerWidget {
  final Widget child;

  const AppRuntimeGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtimeConfig = ref.watch(runtimeConfigProvider);
    final currentVersion = ref.watch(appVersionProvider);

    return runtimeConfig.when(
      loading: () => child,
      error: (_, __) => child,
      data: (config) {
        final version = currentVersion.valueOrNull;

        if (config.maintenanceEnabled) {
          return _BlockingScreen(
            icon: Icons.build_circle_outlined,
            title: config.maintenanceTitle.isNotEmpty
                ? config.maintenanceTitle
                : 'Scheduled Maintenance',
            message: config.maintenanceMessage.isNotEmpty
                ? config.maintenanceMessage
                : 'Medi Locker is temporarily unavailable. Please try again shortly.',
          );
        }

        final shouldForceUpdate = version != null &&
            config.forceUpdateEnabled &&
            config.minSupportedVersion.isNotEmpty &&
            _isOlderVersion(version, config.minSupportedVersion);

        if (shouldForceUpdate) {
          final hasDownloadUrl = config.latestApkUrl.trim().isNotEmpty;
          return _BlockingScreen(
            icon: Icons.system_update_alt_outlined,
            title: 'Update Required',
            message: hasDownloadUrl
                ? 'Your app version is no longer supported. Please update to continue using Medi Locker.'
                : 'Your app version is no longer supported. Please contact support for the latest build.',
            primaryLabel: hasDownloadUrl ? 'Update Now' : null,
            onPrimaryPressed: hasDownloadUrl
                ? () async {
                    await ref.read(appUpdateRepositoryProvider).openDirectUrl(
                          config.latestApkUrl,
                        );
                  }
                : null,
          );
        }

        return child;
      },
    );
  }

  bool _isOlderVersion(String current, String minimum) {
    final currentParts = _parse(current);
    final minimumParts = _parse(minimum);
    final maxLength =
        currentParts.length > minimumParts.length ? currentParts.length : minimumParts.length;

    for (var i = 0; i < maxLength; i++) {
      final currentValue = i < currentParts.length ? currentParts[i] : 0;
      final minimumValue = i < minimumParts.length ? minimumParts[i] : 0;
      if (currentValue < minimumValue) return true;
      if (currentValue > minimumValue) return false;
    }
    return false;
  }

  List<int> _parse(String value) {
    return value
        .trim()
        .replaceFirst(RegExp(r'^[vV]'), '')
        .split('+')
        .first
        .split('.')
        .where((part) => part.isNotEmpty)
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }
}

class _BlockingScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? primaryLabel;
  final Future<void> Function()? onPrimaryPressed;

  const _BlockingScreen({
    required this.icon,
    required this.title,
    required this.message,
    this.primaryLabel,
    this.onPrimaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(icon, size: 42, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                if (primaryLabel != null && onPrimaryPressed != null) ...[
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: onPrimaryPressed,
                      child: Text(primaryLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
