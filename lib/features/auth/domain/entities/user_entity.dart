import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String userType;

  const UserEntity({
    required this.uid,
    required this.email,
    this.userType = 'cafe', // Default to cafe/safe mode
    this.displayName,
  });

  @override
  List<Object?> get props => [uid, email, displayName, userType];
}
