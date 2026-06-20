import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String userType;
  final String accountStatus;
  final String platformType;

  const UserEntity({
    required this.uid,
    required this.email,
    this.userType = 'cafe',
    this.displayName,
    this.accountStatus = 'active',
    this.platformType = 'mobile',
  });

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        userType,
        accountStatus,
        platformType,
      ];
}
