import 'package:dartz/dartz.dart';
import 'package:tahsel/core/base_usecase/base_usecase.dart';
import 'package:tahsel/core/error/failures.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/features/my_debts/domain/repositories/my_debt_repository.dart';

import 'package:tahsel/core/utils/app_strings.dart';

class UpdateMyDebtPaymentParams {
  final String uid;
  final String debtId;
  final String paymentId;
  final double newAmount;
  final double minAmount;
  final double? maxAmount;
  final bool isDebtAdded;
  final String? note;

  UpdateMyDebtPaymentParams({
    required this.uid,
    required this.debtId,
    required this.paymentId,
    required this.newAmount,
    required this.minAmount,
    required this.isDebtAdded,
    this.maxAmount,
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

    if (params.isDebtAdded && (newAmountRounded < minAmountRounded)) {
      return Future.value(Left(ServerFailure(AppStrings.minValueError.tr())));
    }

    if (!params.isDebtAdded && params.maxAmount != null) {
      final maxAmountRounded = double.parse(
        params.maxAmount!.toStringAsFixed(2),
      );
      if (newAmountRounded > maxAmountRounded) {
        return Future.value(
          Left(ServerFailure(AppStrings.paymentExceedsRemaining.tr())),
        );
      }
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
