part of 'offline_sync_cubit.dart';

abstract class OfflineSyncState extends Equatable {
  const OfflineSyncState();
  @override
  List<Object> get props => [];
}

class OfflineSyncInitial extends OfflineSyncState {}

class OfflineSyncInProgress extends OfflineSyncState {}

class OfflineSyncSuccess extends OfflineSyncState {}

class OfflineSyncFailure extends OfflineSyncState {
  final String message;
  const OfflineSyncFailure(this.message);
  @override
  List<Object> get props => [message];
}
