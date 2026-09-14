import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String userType;
  final String accountStatus;
  final String platformType;
  final bool isVip;

  final String? projectName;
  final String? phoneNumber;
  final String? crn;
  final String? address;
  final String? vat;
  final double? taxRate;

  final String role;
  final List<String> permissions;
  final String? ownerUid;
  final bool isEmployee;

  const UserEntity({
    required this.uid,
    required this.email,
    this.userType = 'cafe',
    this.displayName,
    this.accountStatus = 'active',
    this.platformType = 'mobile',
    this.isVip = false,
    this.projectName,
    this.phoneNumber,
    this.crn,
    this.address,
    this.vat,
    this.taxRate,
    this.role = 'owner',
    this.permissions = const ['*'],
    this.ownerUid,
    this.isEmployee = false,
  });

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    userType,
    accountStatus,
    platformType,
    isVip,
    projectName,
    phoneNumber,
    crn,
    address,
    vat,
    taxRate,
    role,
    permissions,
    ownerUid,
    isEmployee,
  ];
}
