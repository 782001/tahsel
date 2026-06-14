import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class ConnectionFailure extends Failure {
  const ConnectionFailure(super.message);
}

class GeneralFailure extends Failure {
  const GeneralFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class OfflineFailure extends Failure {
  const OfflineFailure(super.message);
}

class StatusViolationFailure extends Failure {
  const StatusViolationFailure(super.message);
}

class DuplicateAttendanceFailure extends Failure {
  const DuplicateAttendanceFailure(super.message);
}

/// Thrown by the data source layer when an attendance record already exists
/// for the same employee on the same date. Caught and mapped to
/// [DuplicateAttendanceFailure] by the repository layer.
class DuplicateAttendanceException implements Exception {
  const DuplicateAttendanceException();
}
