import 'dart:io';

import '../../domain/services/app_version_comparator.dart';

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
        buildNumber: AppVersionComparator.parseBuildNumber(
          p['buildNumber'] ?? p['build_number'],
        ),
        versionName: p['versionName']?.toString() ??
            p['version_name']?.toString() ??
            p['version']?.toString() ??
            '',
        downloadUrl:
            p['downloadUrl']?.toString() ?? p['storeUrl']?.toString() ?? '',
        forceUpdate: p['forceUpdate'] == true || p['force_update'] == true,
        updateTitle: p['updateTitle']?.toString() ?? '',
        updateMessage: p['updateMessage']?.toString() ?? '',
        releaseNotes: p['releaseNotes']?.toString() ?? '',
      );
    }

    // ── Fallback: legacy flat structure ───────────────────────────────────
    String legacyUrl = '';
    if (Platform.isAndroid) {
      legacyUrl = json['android_download_url']?.toString() ?? '';
    } else if (Platform.isWindows) {
      legacyUrl = json['windows_download_url']?.toString() ?? '';
    } else if (Platform.isIOS) {
      legacyUrl = json['ios_download_url']?.toString() ?? '';
    }

    return AppVersionModel(
      buildNumber: AppVersionComparator.parseBuildNumber(
        json['latest_version'] ?? json['buildNumber'],
      ),
      versionName: json['version_name']?.toString() ??
          json['versionName']?.toString() ??
          '',
      downloadUrl: legacyUrl,
      forceUpdate: json['force_update'] == true || json['forceUpdate'] == true,
      updateTitle: '',
      updateMessage: json['update_message']?.toString() ?? '',
      releaseNotes: '',
    );
  }

  /// Convenience getter kept for backward-compat with legacy call-sites
  /// that used the old field name.
  int get latestVersion => buildNumber;
}
