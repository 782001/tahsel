import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserEntity user;

  const AuthSuccess(this.user);

  @override
  List<Object> get props => [user];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object> get props => [message];
}

class AuthUnauthenticated extends AuthState {}

class AuthDeleteLoading extends AuthState {}

class AuthDeleteSuccess extends AuthState {}

class AuthDeleteFailure extends AuthState {
  final String message;

  const AuthDeleteFailure(this.message);

  @override
  List<Object> get props => [message];
}
