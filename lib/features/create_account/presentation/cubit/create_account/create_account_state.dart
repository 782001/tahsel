import 'package:equatable/equatable.dart';

abstract class CreateAccountState extends Equatable {
  const CreateAccountState();
  @override
  List<Object?> get props => [];
}

class CreateAccountInitial extends CreateAccountState {}


class CreateAccountSuccess extends CreateAccountState {}

class CreateAccountError extends CreateAccountState {
  final String message;
  const CreateAccountError(this.message);
  @override
  List<Object?> get props => [message];
}
