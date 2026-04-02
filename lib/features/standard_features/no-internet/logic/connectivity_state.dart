import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

sealed class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

final class ConnectivityInitial extends ConnectivityState {
  const ConnectivityInitial();
}

final class ConnectivityLoading extends ConnectivityState {
  const ConnectivityLoading();
}

final class ConnectivityConnected extends ConnectivityState {
  final ConnectivityResult result;

  const ConnectivityConnected(this.result);

  @override
  List<Object?> get props => [result];
}

final class ConnectivityDisconnected extends ConnectivityState {
  const ConnectivityDisconnected();
}

final class ConnectivityError extends ConnectivityState {
  final String message;

  const ConnectivityError(this.message);

  @override
  List<Object?> get props => [message];
}
