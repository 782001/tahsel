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
  ];
}
