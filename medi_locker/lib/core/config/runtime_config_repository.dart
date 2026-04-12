import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'app_runtime_config.dart';

class RuntimeConfigRepository {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<AppRuntimeConfig> initialize() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    await _remoteConfig.setDefaults(const {
      'maintenance_enabled': false,
      'maintenance_title': 'Scheduled Maintenance',
      'maintenance_message':
          'Medi Locker is temporarily unavailable. Please try again shortly.',
      'min_supported_version': '',
      'latest_version': '',
      'latest_apk_url': '',
      'force_update_enabled': false,
    });

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (_) {
      // Fall back to defaults if remote fetch fails.
    }

    return AppRuntimeConfig.fromRemoteValues(
      maintenanceEnabled: _remoteConfig.getBool('maintenance_enabled'),
      maintenanceTitle: _remoteConfig.getString('maintenance_title'),
      maintenanceMessage: _remoteConfig.getString('maintenance_message'),
      minSupportedVersion: _remoteConfig.getString('min_supported_version'),
      latestVersion: _remoteConfig.getString('latest_version'),
      latestApkUrl: _remoteConfig.getString('latest_apk_url'),
      forceUpdateEnabled: _remoteConfig.getBool('force_update_enabled'),
    );
  }
}
