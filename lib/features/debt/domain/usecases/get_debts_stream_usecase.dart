import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

class GetDebtsStreamUseCase {
  final DebtRepository repository;

  GetDebtsStreamUseCase(this.repository);

  Stream<List<DebtEntity>> call(String uid) {
    return repository.getDebtsStream(uid);
  }
}
