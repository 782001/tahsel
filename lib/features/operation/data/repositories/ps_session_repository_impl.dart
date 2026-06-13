import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/ps_session_entity.dart';
import '../../domain/repositories/ps_session_repository.dart';
import '../datasources/ps_session_remote_data_source.dart';
import '../models/ps_session_model.dart';

class PsSessionRepositoryImpl implements PsSessionRepository {
  final PsSessionRemoteDataSource remoteDataSource;

  PsSessionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> startSession(
    PsSessionEntity session,
  ) async {
    try {
      final model = PsSessionModel.fromEntity(session);
      final sessionId = await remoteDataSource.startSession(model);
      return Right(sessionId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> endSession({
    required String uid,
    required String sessionId,
    required DateTime endTime,
    required double totalAmount,
    required double paidAmount,
    int? turnCount,
  }) async {
    try {
      await remoteDataSource.endSession(
        uid: uid,
        sessionId: sessionId,
        endTime: endTime,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        turnCount: turnCount,
      );
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PsSessionEntity>>> getActiveSessions(
    String uid,
  ) async {
    try {
      final sessions = await remoteDataSource.getActiveSessions(uid);
      return Right(sessions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PsSessionEntity?>> getSessionById(
    String uid,
    String sessionId,
  ) async {
    try {
      final session = await remoteDataSource.getSessionById(uid, sessionId);
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
