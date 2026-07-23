import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.userType,
    super.displayName,
    super.accountStatus = 'active',
    super.platformType = 'mobile',
    super.isVip = false,
  });

  factory UserModel.fromFirebaseUser(
    User user, {
    String? userType,
    String? accountStatus,
    String? platformType,
    bool? isVip,
  }) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      userType: userType ?? 'cafe',
      accountStatus: accountStatus ?? 'active',
      platformType: platformType ?? 'mobile',
      isVip: isVip ?? false,
    );
  }
}
