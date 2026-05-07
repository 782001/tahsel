import '../repositories/update_repository.dart';
import '../../data/models/app_version_model.dart';

class CheckUpdateUseCase {
  final UpdateRepository repository;

  CheckUpdateUseCase(this.repository);

  Future<AppVersionModel?> call() {
    return repository.checkForUpdate();
  }
}
