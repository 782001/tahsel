import 'package:dartz/dartz.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/debt_repository.dart';

class RecordReminderSentUseCase
    implements BaseUseCase<void, RecordReminderSentParams> {
  final DebtRepository repository;

  RecordReminderSentUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(RecordReminderSentParams params) async {
    return await repository.recordReminderSent(
      uid: params.uid,
      customerName: params.customerName,
      debtIds: params.debtIds,
    );
  }
}

class RecordReminderSentParams {
  final String uid;
  final String customerName;
  final List<String>? debtIds;

  RecordReminderSentParams({
    required this.uid,
    required this.customerName,
    this.debtIds,
  });
}
