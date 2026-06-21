import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/ps_session_entity.dart';
import '../../domain/usecases/ps_session_usecases.dart';
import 'ps_session_state.dart';

class PsSessionCubit extends Cubit<PsSessionState> {
  final StartPsSessionUseCase startPsSessionUseCase;
  final EndPsSessionUseCase endPsSessionUseCase;
  final GetActiveSessionsUseCase getActiveSessionsUseCase;

  PsSessionCubit({
    required this.startPsSessionUseCase,
    required this.endPsSessionUseCase,
    required this.getActiveSessionsUseCase,
  }) : super(PsSessionInitial());

  /// Cached list of active sessions for quick access by the UI.
  List<PsSessionEntity> _activeSessions = [];
  List<PsSessionEntity> get activeSessions => _activeSessions;

  /// Starts a new PlayStation session.
  Future<void> startSession(PsSessionEntity session) async {
    emit(PsSessionLoading());
    final result = await startPsSessionUseCase(
      StartPsSessionParams(session: session),
    );

    result.fold(
      (failure) => emit(PsSessionFailure(message: failure.toString())),
      (sessionId) {
        // Add the new session to local cache with the ID
        final started = session.copyWith(id: sessionId);
        _activeSessions = [started, ..._activeSessions];
        emit(PsSessionStarted(sessionId: sessionId));
      },
    );
  }

  /// Ends an active session and triggers billing.
  Future<void> endSession({
    required String uid,
    required String sessionId,
    required DateTime endTime,
    required double totalAmount,
    required double paidAmount,
    String? customerName,
    String? phoneNumber,
    String? ledgerNumber,
    required String subType,
    int? turnCount,
  }) async {
    emit(PsSessionLoading());
    final result = await endPsSessionUseCase(
      EndPsSessionParams(
        uid: uid,
        sessionId: sessionId,
        endTime: endTime,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        customerName: customerName,
        phoneNumber: phoneNumber,
        ledgerNumber: ledgerNumber,
        subType: subType,
        turnCount: turnCount,
      ),
    );

    result.fold(
      (failure) => emit(PsSessionFailure(message: failure.toString())),
      (_) {
        // Remove the ended session from local cache
        _activeSessions = _activeSessions
            .where((s) => s.id != sessionId)
            .toList();
        emit(PsSessionEnded(sessionId: sessionId));
      },
    );
  }

  /// Loads all active (running) sessions.
  Future<void> loadActiveSessions(String uid) async {
    emit(PsSessionLoading());
    final result = await getActiveSessionsUseCase(
      GetActiveSessionsParams(uid: uid),
    );

    result.fold(
      (failure) => emit(PsSessionFailure(message: failure.toString())),
      (sessions) {
        _activeSessions = sessions;
        emit(PsSessionActiveLoaded(sessions: sessions));
      },
    );
  }
}
