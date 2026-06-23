import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_version_model.dart';

abstract class UpdateRemoteDataSource {
  Future<AppVersionModel?> checkForUpdate();
  Future<void> downloadAndInstall({
    required String url,
    required String fileName,
    required Function(double) onProgress,
  });
  Future<void> openDownloadLink(String url);
}

class UpdateRemoteDataSourceImpl implements UpdateRemoteDataSource {
  final FirebaseFirestore firestore;
  final Dio dio;

  UpdateRemoteDataSourceImpl({required this.firestore, required this.dio});

  // Matches AdminConstants.systemSettingsCollection / appVersionDoc in the
  // dashboard — both apps must point to the same Firestore path.
  static const _collection = 'app_config';
  static const _document = 'version_control';

  @override
  Future<AppVersionModel?> checkForUpdate() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

    AppLogger.printMessage('DEBUG: Checking for update...');
    AppLogger.printMessage('DEBUG: Current Build Number: $currentBuildNumber');

    final doc = await firestore.collection(_collection).doc(_document).get();

    if (!doc.exists) {
      AppLogger.printMessage(
        "DEBUG: Firestore document '$_collection/$_document' does not exist.",
      );
      return null;
    }

    final data = doc.data();
    if (data == null) {
      AppLogger.printMessage('DEBUG: Firestore document data is null.');
      return null;
    }

    final latestAppVersion = AppVersionModel.fromFirestore(data);
    AppLogger.printMessage(
      'DEBUG: Latest Build Number from Firestore: ${latestAppVersion.buildNumber}',
    );

    if (latestAppVersion.buildNumber > currentBuildNumber) {
      AppLogger.printMessage('DEBUG: Update available!');
      return latestAppVersion;
    }

    AppLogger.printMessage('DEBUG: No update available.');
    return null;
  }

  /// Downloads and installs the update — **Windows only**.
  /// Android and iOS redirect to the store via [openDownloadLink] instead.
  @override
  Future<void> downloadAndInstall({
    required String url,
    required String fileName,
    required Function(double) onProgress,
  }) async {
    // Safety guard: this method should only be reached on Windows.
    if (!Platform.isWindows) {
      await openDownloadLink(url);
      return;
    }

    final directory = await getDownloadsDirectory();
    final filePath = '${directory!.path}/$fileName';

    await dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          onProgress(received / total);
        }
      },
    );

    // Open the folder in Explorer and highlight the downloaded file.
    await Process.run('explorer.exe', [
      '/select,',
      filePath.replaceAll('/', '\\'),
    ]);
  }

  /// Opens [url] in the system browser / store app.
  /// Used for Android (Google Play) and iOS (App Store) update links.
  @override
  Future<void> openDownloadLink(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
