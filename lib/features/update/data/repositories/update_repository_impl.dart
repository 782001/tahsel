import '../../domain/repositories/update_repository.dart';
import '../datasources/update_remote_data_source.dart';
import '../models/app_version_model.dart';

class UpdateRepositoryImpl implements UpdateRepository {
  final UpdateRemoteDataSource remoteDataSource;

  UpdateRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AppVersionModel?> checkForUpdate() {
    return remoteDataSource.checkForUpdate();
  }

  @override
  Future<void> downloadAndInstall({
    required String url,
    required String fileName,
    required Function(double) onProgress,
  }) {
    return remoteDataSource.downloadAndInstall(
      url: url,
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  @override
  Future<void> openDownloadLink(String url) {
    return remoteDataSource.openDownloadLink(url);
  }
}
