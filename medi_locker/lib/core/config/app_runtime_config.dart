class AppRuntimeConfig {
  final bool maintenanceEnabled;
  final String maintenanceTitle;
  final String maintenanceMessage;
  final String minSupportedVersion;
  final String latestVersion;
  final String latestApkUrl;
  final bool forceUpdateEnabled;

  const AppRuntimeConfig({
    required this.maintenanceEnabled,
    required this.maintenanceTitle,
    required this.maintenanceMessage,
    required this.minSupportedVersion,
    required this.latestVersion,
    required this.latestApkUrl,
    required this.forceUpdateEnabled,
  });

  factory AppRuntimeConfig.fromRemoteValues({
    required bool maintenanceEnabled,
    required String maintenanceTitle,
    required String maintenanceMessage,
    required String minSupportedVersion,
    required String latestVersion,
    required String latestApkUrl,
    required bool forceUpdateEnabled,
  }) {
    return AppRuntimeConfig(
      maintenanceEnabled: maintenanceEnabled,
      maintenanceTitle: maintenanceTitle.trim(),
      maintenanceMessage: maintenanceMessage.trim(),
      minSupportedVersion: minSupportedVersion.trim(),
      latestVersion: latestVersion.trim(),
      latestApkUrl: latestApkUrl.trim(),
      forceUpdateEnabled: forceUpdateEnabled,
    );
  }
}
