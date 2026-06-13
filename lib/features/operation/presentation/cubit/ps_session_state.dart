import 'package:equatable/equatable.dart';
import '../../domain/entities/ps_session_entity.dart';

abstract class PsSessionState extends Equatable {
  const PsSessionState();

  @override
  List<Object?> get props => [];
}

class PsSessionInitial extends PsSessionState {}

class PsSessionLoading extends PsSessionState {}

/// Emitted when a new session has been started successfully.
class PsSessionStarted extends PsSessionState {
  final String sessionId;

  const PsSessionStarted({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

/// Emitted when a session has been ended successfully.
class PsSessionEnded extends PsSessionState {
  final String sessionId;

  const PsSessionEnded({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

/// Emitted when the active sessions list has been loaded.
class PsSessionActiveLoaded extends PsSessionState {
  final List<PsSessionEntity> sessions;

  const PsSessionActiveLoaded({required this.sessions});

  @override
  List<Object?> get props => [sessions];
}

/// Emitted on any failure.
class PsSessionFailure extends PsSessionState {
  final String message;

  const PsSessionFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
