import 'dart:io';

class AppVersionModel {
  final int buildNumber;
  final String versionName;
  final String downloadUrl;
  final bool forceUpdate;
  final String updateTitle;
  final String updateMessage;
  final String releaseNotes;

  AppVersionModel({
    required this.buildNumber,
    required this.versionName,
    required this.downloadUrl,
    required this.forceUpdate,
    required this.updateTitle,
    required this.updateMessage,
    required this.releaseNotes,
  });

  /// Parses the Firestore document at `app_config/version_control`.
  ///
  /// Supports two document shapes:
  ///
  /// **New (platform-specific)** — written by the dashboard's
  /// `updatePlatformRelease`:
  /// ```json
  /// {
  ///   "android": { "versionName": "2.0.0", "buildNumber": 20, ... },
  ///   "ios":     { "versionName": "1.5.0", "buildNumber": 15, ... },
  ///   "windows": { "versionName": "1.0.0", "buildNumber": 10, ... }
  /// }
  /// ```
  ///
  /// **Legacy (flat)** — older documents still in Firestore:
  /// ```json
  /// {
  ///   "latest_version": 12, "version_name": "1.2.0",
  ///   "android_download_url": "...", "force_update": false,
  ///   "update_message": "..."
  /// }
  /// ```
  factory AppVersionModel.fromFirestore(Map<String, dynamic> json) {
    // ── Detect new platform-specific structure ────────────────────────────
    final String platformKey = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
            ? 'ios'
            : 'windows';

    if (json[platformKey] is Map) {
      final Map<String, dynamic> p =
          Map<String, dynamic>.from(json[platformKey] as Map);
      return AppVersionModel(
        buildNumber: (p['buildNumber'] as num?)?.toInt() ?? 0,
        versionName: p['versionName'] as String? ?? '',
        downloadUrl:
            p['downloadUrl'] as String? ?? p['storeUrl'] as String? ?? '',
        forceUpdate: p['forceUpdate'] as bool? ?? false,
        updateTitle: p['updateTitle'] as String? ?? '',
        updateMessage: p['updateMessage'] as String? ?? '',
        releaseNotes: p['releaseNotes'] as String? ?? '',
      );
    }

    // ── Fallback: legacy flat structure ───────────────────────────────────
    String legacyUrl = '';
    if (Platform.isAndroid) {
      legacyUrl = json['android_download_url'] as String? ?? '';
    } else if (Platform.isWindows) {
      legacyUrl = json['windows_download_url'] as String? ?? '';
    } else if (Platform.isIOS) {
      legacyUrl = json['ios_download_url'] as String? ?? '';
    }

    return AppVersionModel(
      buildNumber: (json['latest_version'] as num?)?.toInt() ?? 0,
      versionName: json['version_name'] as String? ?? '',
      downloadUrl: legacyUrl,
      forceUpdate: json['force_update'] as bool? ?? false,
      updateTitle: '',
      updateMessage: json['update_message'] as String? ?? '',
      releaseNotes: '',
    );
  }

  /// Convenience getter kept for backward-compat with legacy call-sites
  /// that used the old field name.
  int get latestVersion => buildNumber;
}
