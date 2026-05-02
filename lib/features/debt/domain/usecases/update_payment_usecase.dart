import 'package:dartz/dartz.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/debt_repository.dart';

class UpdatePaymentParams {
  final String uid;
  final String debtId;
  final String paymentId;
  final double newAmount;
  final double minAmount;
  final String? note;

  UpdatePaymentParams({
    required this.uid,
    required this.debtId,
    required this.paymentId,
    required this.newAmount,
    required this.minAmount,
    this.note,
  });
}

class UpdatePaymentUseCase implements BaseUseCase<void, UpdatePaymentParams> {
  final DebtRepository repository;

  UpdatePaymentUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(UpdatePaymentParams params) {
    final newAmountRounded = double.parse(params.newAmount.toStringAsFixed(2));
    final minAmountRounded = double.parse(params.minAmount.toStringAsFixed(2));

    if (newAmountRounded < minAmountRounded) {
      return Future.value(Left(ServerFailure(AppStrings.minValueError)));
    }

    return repository.updatePayment(
      uid: params.uid,
      debtId: params.debtId,
      paymentId: params.paymentId,
      newAmount: params.newAmount,
      note: params.note,
    );
  }
}
