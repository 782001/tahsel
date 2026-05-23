import 'package:tahsel/features/update/data/models/app_version_model.dart';

abstract class UpdateRepository {
  Future<AppVersionModel?> checkForUpdate();
  Future<void> downloadAndInstall({
    required String url,
    required String fileName,
    required Function(double) onProgress,
  });
  Future<void> openDownloadLink(String url);
}
