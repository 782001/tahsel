import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/ps_session_entity.dart';

abstract class PsSessionRepository {
  /// Starts a new PlayStation session. Returns the session document ID.
  Future<Either<Failure, String>> startSession(PsSessionEntity session);

  /// Ends an active session, creates an operation record for billing.
  Future<Either<Failure, Unit>> endSession({
    required String uid,
    required String sessionId,
    required DateTime endTime,
    required double totalAmount,
    required double paidAmount,
    int? turnCount,
  });

  /// Returns all active (running) sessions for the given user.
  Future<Either<Failure, List<PsSessionEntity>>> getActiveSessions(String uid);

  /// Returns a single session by its ID.
  Future<Either<Failure, PsSessionEntity?>> getSessionById(
    String uid,
    String sessionId,
  );
}
