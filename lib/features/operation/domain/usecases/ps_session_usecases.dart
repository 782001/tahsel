import 'package:dartz/dartz.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/debt/domain/entities/debt_entity.dart';
import 'package:tahsel/features/debt/domain/repositories/debt_repository.dart';

import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/ps_session_entity.dart';
import '../repositories/ps_session_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// START SESSION
// ─────────────────────────────────────────────────────────────────────────────

class StartPsSessionUseCase
    implements BaseUseCase<String, StartPsSessionParams> {
  final PsSessionRepository repository;

  StartPsSessionUseCase({required this.repository});

  @override
  Future<Either<Failure, String>> call(StartPsSessionParams params) async {
    return await repository.startSession(params.session);
  }
}

class StartPsSessionParams {
  final PsSessionEntity session;

  StartPsSessionParams({required this.session});
}

// ─────────────────────────────────────────────────────────────────────────────
// END SESSION
// ─────────────────────────────────────────────────────────────────────────────

class EndPsSessionUseCase implements BaseUseCase<Unit, EndPsSessionParams> {
  final PsSessionRepository repository;
  final DebtRepository debtRepository;

  EndPsSessionUseCase({required this.repository, required this.debtRepository});

  @override
  Future<Either<Failure, Unit>> call(EndPsSessionParams params) async {
    final result = await repository.endSession(
      uid: params.uid,
      sessionId: params.sessionId,
      endTime: params.endTime,
      totalAmount: params.totalAmount,
      paidAmount: params.paidAmount,
      turnCount: params.turnCount,
    );

    return await result.fold((failure) async => Left(failure), (_) async {
      // If there's remaining debt, create a debt record
      final remaining = params.totalAmount - params.paidAmount;
      if (remaining > 0) {
        final debt = DebtEntity(
          uid: params.uid,
          operationId: params.sessionId,
          totalAmount: params.totalAmount,
          paidAmount: params.paidAmount,
          remainingAmount: remaining,
          customerName: params.customerName,
          productOrSessionDetails: params.subType == 'time'
              ? AppStrings.psSessionTime.tr()
              : AppStrings.psSessionTurn.tr(),
          operationType: AppStrings.playStation,
          timestamp: params.endTime,
          ledgerNumber: params.ledgerNumber,
          phoneNumber: params.phoneNumber,
          isPaid: false,
        );
        await debtRepository.addDebt(debt);
      }
      return const Right(unit);
    });
  }
}

class EndPsSessionParams {
  final String uid;
  final String sessionId;
  final DateTime endTime;
  final double totalAmount;
  final double paidAmount;
  final String? customerName;
  final String? phoneNumber;
  final String? ledgerNumber;
  final String subType;
  final int? turnCount;

  EndPsSessionParams({
    required this.uid,
    required this.sessionId,
    required this.endTime,
    required this.totalAmount,
    required this.paidAmount,
    this.customerName,
    this.phoneNumber,
    this.ledgerNumber,
    required this.subType,
    this.turnCount,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// GET ACTIVE SESSIONS
// ─────────────────────────────────────────────────────────────────────────────

class GetActiveSessionsUseCase
    implements BaseUseCase<List<PsSessionEntity>, GetActiveSessionsParams> {
  final PsSessionRepository repository;

  GetActiveSessionsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<PsSessionEntity>>> call(
    GetActiveSessionsParams params,
  ) async {
    return await repository.getActiveSessions(params.uid);
  }
}

class GetActiveSessionsParams {
  final String uid;

  GetActiveSessionsParams({required this.uid});
}
