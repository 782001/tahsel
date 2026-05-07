import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
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

  @override
  Future<AppVersionModel?> checkForUpdate() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

    AppLogger.printMessage("DEBUG: Checking for update...");
    AppLogger.printMessage("DEBUG: Current Build Number: $currentBuildNumber");

    final doc = await firestore.collection('app_config').doc('version_control').get();

    if (!doc.exists) {
      AppLogger.printMessage("DEBUG: Firestore document 'app_config/version_control' does not exist.");
      return null;
    }

    final data = doc.data();
    if (data == null) {
      AppLogger.printMessage("DEBUG: Firestore document data is null.");
      return null;
    }

    final latestAppVersion = AppVersionModel.fromFirestore(data);
    AppLogger.printMessage("DEBUG: Latest Version from Firestore: ${latestAppVersion.latestVersion}");

    if (latestAppVersion.latestVersion > currentBuildNumber) {
      AppLogger.printMessage("DEBUG: Update available!");
      return latestAppVersion;
    }
    
    AppLogger.printMessage("DEBUG: No update available.");
    return null;
  }

  @override
  Future<void> downloadAndInstall({
    required String url,
    required String fileName,
    required Function(double) onProgress,
  }) async {
    final directory = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getDownloadsDirectory();
    final filePath = "${directory!.path}/$fileName";

    await dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          onProgress(received / total);
        }
      },
    );

    if (Platform.isAndroid) {
      await OpenFilex.open(filePath);
    } else if (Platform.isWindows) {
      // Open the folder and select the file
      await Process.run('explorer.exe', ['/select,', filePath.replaceAll('/', '\\')]);
    }
  }

  @override
  Future<void> openDownloadLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
