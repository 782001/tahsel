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
    super.projectName,
    super.phoneNumber,
    super.crn,
    super.address,
    super.vat,
    super.taxRate,
    super.role = 'owner',
    super.permissions = const ['*'],
    super.ownerUid,
    super.isEmployee = false,
  });

  factory UserModel.fromFirebaseUser(
    User user, {
    String? userType,
    String? accountStatus,
    String? platformType,
    bool? isVip,
    String? projectName,
    String? phoneNumber,
    String? crn,
    String? address,
    String? vat,
    double? taxRate,
    String? role,
    List<String>? permissions,
    String? ownerUid,
    bool? isEmployee,
  }) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      userType: userType ?? 'cafe',
      accountStatus: accountStatus ?? 'active',
      platformType: platformType ?? 'mobile',
      isVip: isVip ?? false,
      projectName: projectName,
      phoneNumber: phoneNumber,
      crn: crn,
      address: address,
      vat: vat,
      taxRate: taxRate,
      role: role ?? 'owner',
      permissions: permissions ?? const ['*'],
      ownerUid: ownerUid,
      isEmployee: isEmployee ?? (role == 'employee' || (ownerUid != null && ownerUid.isNotEmpty)),
    );
  }
}
