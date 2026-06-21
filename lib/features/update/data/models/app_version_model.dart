import 'dart:io';

class AppVersionModel {
  final int latestVersion;
  final String versionName;
  final String downloadUrl;
  final bool forceUpdate;
  final String updateMessage;

  AppVersionModel({
    required this.latestVersion,
    required this.versionName,
    required this.downloadUrl,
    required this.forceUpdate,
    required this.updateMessage,
  });

  factory AppVersionModel.fromFirestore(Map<String, dynamic> json) {
    String url = '';
    if (Platform.isAndroid) {
      url = json['android_download_url'] as String? ?? '';
    } else if (Platform.isWindows) {
      url = json['windows_download_url'] as String? ?? '';
    } else if (Platform.isIOS) {
      url = json['ios_download_url'] as String? ?? '';
    }

    return AppVersionModel(
      latestVersion: (json['latest_version'] as num?)?.toInt() ?? 0,
      versionName: json['version_name'] as String? ?? '',
      downloadUrl: url,
      forceUpdate: json['force_update'] as bool? ?? false,
      updateMessage: json['update_message'] as String? ?? '',
    );
  }
}
