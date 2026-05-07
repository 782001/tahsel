part of 'update_cubit.dart';

abstract class UpdateState {}

class UpdateInitial extends UpdateState {}

class UpdateChecking extends UpdateState {}

class UpdateAvailable extends UpdateState {
  final AppVersionModel versionInfo;
  UpdateAvailable(this.versionInfo);
}

class UpdateNotAvailable extends UpdateState {}

class UpdateDownloading extends UpdateState {
  final double progress;
  UpdateDownloading(this.progress);
}

class UpdateInstalled extends UpdateState {}

class UpdateRedirected extends UpdateState {}

class UpdateError extends UpdateState {
  final String message;
  UpdateError(this.message);
}
