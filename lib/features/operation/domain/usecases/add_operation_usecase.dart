import 'package:dartz/dartz.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/debt/domain/entities/debt_entity.dart';
import 'package:tahsel/features/debt/domain/repositories/debt_repository.dart';

import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/operation_entity.dart';
import '../repositories/operation_repository.dart';

class AddOperationUseCase implements BaseUseCase<String, AddOperationParams> {
  final OperationRepository repository;
  final DebtRepository debtRepository;

  AddOperationUseCase({required this.repository, required this.debtRepository});

  @override
  Future<Either<Failure, String>> call(AddOperationParams params) async {
    final result = await repository.addOperation(params.operation);

    return await result.fold((failure) async => Left(failure), (
      operationId,
    ) async {
      // If there's remaining debt, also create a debt record
      if (params.operation.remainingDebt > 0) {
        final debt = DebtEntity(
          uid: params.operation.uid,
          operationId: operationId,
          totalAmount: params.operation.totalAmount,
          paidAmount: params.operation.paidAmount,
          remainingAmount: params.operation.remainingDebt,
          customerName: params.operation.customerName,
          productOrSessionDetails:
              params.operation.productName ??
              (params.operation.subType == 'time'
                  ? AppStrings.psSessionTime.tr()
                  : AppStrings.psSessionTurn.tr()),
          operationType: params.operation.type,
          timestamp: params.operation.timestamp ?? DateTime.now(),
          ledgerNumber: params.operation.ledgerNumber,
          phoneNumber: params.operation.phoneNumber,
          isPaid: false,
        );

        await debtRepository.addDebt(debt);
      }
      return Right(operationId);
    });
  }
}

class AddOperationParams {
  final OperationEntity operation;

  AddOperationParams({required this.operation});
}
