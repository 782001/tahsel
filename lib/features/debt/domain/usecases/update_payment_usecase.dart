import 'package:dartz/dartz.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
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
  final double? maxAmount;
  final bool isDebtAdded;
  final String? note;

  UpdatePaymentParams({
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

class UpdatePaymentUseCase implements BaseUseCase<void, UpdatePaymentParams> {
  final DebtRepository repository;

  UpdatePaymentUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(UpdatePaymentParams params) {
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

    return repository.updatePayment(
      uid: params.uid,
      debtId: params.debtId,
      paymentId: params.paymentId,
      newAmount: params.newAmount,
      note: params.note,
    );
  }
}
