import '../repositories/update_repository.dart';

class DownloadUpdateUseCase {
  final UpdateRepository repository;

  DownloadUpdateUseCase(this.repository);

  Future<void> downloadAndInstall({
    required String url,
    required String fileName,
    required Function(double) onProgress,
  }) {
    return repository.downloadAndInstall(
      url: url,
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  Future<void> openDownloadLink(String url) {
    return repository.openDownloadLink(url);
  }
}
