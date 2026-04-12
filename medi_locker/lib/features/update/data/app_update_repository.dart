import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_release_config.dart';
import '../models/app_update_info.dart';

class AppUpdateRepository {
  static const _dismissedVersionKey = 'dismissed_update_version';
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<AppUpdateInfo?> checkForUpdate({
    bool includeDismissed = false,
  }) async {
    final currentVersion = await getCurrentVersion();
    final remoteUpdate = await _checkRemoteConfigUpdate(
      currentVersion: currentVersion,
      includeDismissed: includeDismissed,
    );
    if (remoteUpdate != null) {
      return remoteUpdate;
    }

    final response = await http.get(
      Uri.parse(AppReleaseConfig.latestReleaseApi),
      headers: const {
        'Accept': 'application/vnd.github+json',
      },
    );

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final latestVersion = _normalizeVersion(data['tag_name']?.toString() ?? '');
    if (latestVersion.isEmpty || !_isNewer(latestVersion, currentVersion)) {
      return null;
    }

    if (!includeDismissed) {
      final prefs = await SharedPreferences.getInstance();
      final dismissedVersion = prefs.getString(_dismissedVersionKey);
      if (dismissedVersion == latestVersion) {
        return null;
      }
    }

    final assets = (data['assets'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final apkAsset = assets.cast<Map<String, dynamic>?>().firstWhere(
          (asset) => (asset?['name']?.toString().toLowerCase().endsWith('.apk') ?? false),
          orElse: () => null,
        );

    final downloadUrl = apkAsset?['browser_download_url']?.toString() ??
        data['html_url']?.toString() ??
        '';
    if (downloadUrl.isEmpty) {
      return null;
    }

    return AppUpdateInfo(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      downloadUrl: downloadUrl,
      releaseNotes: data['body']?.toString().trim() ?? '',
      releasePageUrl: data['html_url']?.toString() ?? downloadUrl,
    );
  }

  Future<void> dismissVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersionKey, version);
  }

  Future<bool> openDownload(AppUpdateInfo update) async {
    final uri = Uri.parse(update.downloadUrl);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> openDirectUrl(String url) async {
    if (url.trim().isEmpty) return false;
    final uri = Uri.parse(url);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<AppUpdateInfo?> _checkRemoteConfigUpdate({
    required String currentVersion,
    required bool includeDismissed,
  }) async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (_) {
      return null;
    }

    final latestVersion = _normalizeVersion(
      _remoteConfig.getString('latest_version'),
    );
    final downloadUrl = _remoteConfig.getString('latest_apk_url').trim();

    if (latestVersion.isEmpty ||
        downloadUrl.isEmpty ||
        !_isNewer(latestVersion, currentVersion)) {
      return null;
    }

    if (!includeDismissed) {
      final prefs = await SharedPreferences.getInstance();
      final dismissedVersion = prefs.getString(_dismissedVersionKey);
      if (dismissedVersion == latestVersion) {
        return null;
      }
    }

    return AppUpdateInfo(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      downloadUrl: downloadUrl,
      releaseNotes: '',
      releasePageUrl: downloadUrl,
    );
  }

  bool _isNewer(String latest, String current) {
    final latestParts = _parseVersion(latest);
    final currentParts = _parseVersion(current);
    final maxLength =
        latestParts.length > currentParts.length ? latestParts.length : currentParts.length;

    for (var index = 0; index < maxLength; index++) {
      final latestPart = index < latestParts.length ? latestParts[index] : 0;
      final currentPart = index < currentParts.length ? currentParts[index] : 0;
      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }
    return false;
  }

  List<int> _parseVersion(String version) {
    return _normalizeVersion(version)
        .split('.')
        .where((part) => part.isNotEmpty)
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }

  String _normalizeVersion(String version) {
    var normalized = version.trim();
    if (normalized.startsWith('v') || normalized.startsWith('V')) {
      normalized = normalized.substring(1);
    }
    return normalized.split('+').first;
  }
}
