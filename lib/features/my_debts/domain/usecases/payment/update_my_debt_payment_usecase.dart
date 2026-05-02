import 'package:dartz/dartz.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

import 'package:tahsel/core/utils/app_strings.dart';

class UpdateMyDebtPaymentParams {
  final String uid;
  final String debtId;
  final String paymentId;
  final double newAmount;
  final double minAmount;
  final String? note;

  UpdateMyDebtPaymentParams({
    required this.uid,
    required this.debtId,
    required this.paymentId,
    required this.newAmount,
    required this.minAmount,
    this.note,
  });
}

class UpdateMyDebtPaymentUseCase
    implements BaseUseCase<void, UpdateMyDebtPaymentParams> {
  final MyDebtRepository repository;

  UpdateMyDebtPaymentUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(UpdateMyDebtPaymentParams params) {
    final newAmountRounded = double.parse(params.newAmount.toStringAsFixed(2));
    final minAmountRounded = double.parse(params.minAmount.toStringAsFixed(2));

    if (newAmountRounded < minAmountRounded) {
      return Future.value(Left(ServerFailure(AppStrings.minValueError)));
    }

    return repository.updateMyDebtPayment(
      uid: params.uid,
      debtId: params.debtId,
      paymentId: params.paymentId,
      newAmount: params.newAmount,
      note: params.note,
    );
  }
}
