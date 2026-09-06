import 'package:equatable/equatable.dart';

class UserProfileModel extends Equatable {
  final String uid;
  final String email;
  final String fullName;
  final String projectName;
  final String phoneNumber;
  final String crn;
  final String address;
  final String vat;
  final String userType;
  final String platformType;
  final bool isVip;
  final String accountStatus;

  const UserProfileModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.projectName,
    this.phoneNumber = '',
    this.crn = '',
    this.address = '',
    this.vat = '',
    this.userType = 'cafe',
    this.platformType = 'mobile',
    this.isVip = false,
    this.accountStatus = 'active',
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map, {String? uid, String? fallbackEmail}) {
    return UserProfileModel(
      uid: (map['uid'] as String?) ?? uid ?? '',
      email: (map['email'] as String?) ?? fallbackEmail ?? '',
      fullName: (map['fullName'] as String?) ?? (map['name'] as String?) ?? '',
      projectName: (map['projectName'] as String?) ?? '',
      phoneNumber: (map['phoneNumber'] as String?) ?? (map['phone'] as String?) ?? '',
      crn: (map['crn'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      vat: (map['vat'] as String?) ?? (map['taxNumber'] as String?) ?? '',
      userType: (map['userType'] as String?) ?? 'cafe',
      platformType: (map['platformType'] as String?) ?? 'mobile',
      isVip: (map['isVip'] as bool?) ?? false,
      accountStatus: (map['accountStatus'] as String?) ?? 'active',
    );
  }

  UserProfileModel copyWith({
    String? fullName,
    String? projectName,
    String? phoneNumber,
    String? crn,
    String? address,
    String? vat,
    String? userType,
    bool? isVip,
    String? accountStatus,
  }) {
    return UserProfileModel(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      projectName: projectName ?? this.projectName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      crn: crn ?? this.crn,
      address: address ?? this.address,
      vat: vat ?? this.vat,
      userType: userType ?? this.userType,
      platformType: platformType,
      isVip: isVip ?? this.isVip,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'projectName': projectName,
      'phoneNumber': phoneNumber,
      'crn': crn,
      'address': address,
      'vat': vat,
      'userType': userType,
      'platformType': platformType,
      'isVip': isVip,
      'accountStatus': accountStatus,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'fullName': fullName.trim(),
      'projectName': projectName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'crn': crn.trim(),
      'address': address.trim(),
      'vat': vat.trim(),
    };
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    fullName,
    projectName,
    phoneNumber,
    crn,
    address,
    vat,
    userType,
    platformType,
    isVip,
    accountStatus,
  ];
}
