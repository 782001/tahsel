import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AppEmployeeModel extends Equatable {
  final String authUid;
  final String name;
  final String email;
  final String rolePreset;
  final List<String> permissions;
  final String accountStatus; // 'active' or 'disabled'
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const AppEmployeeModel({
    required this.authUid,
    required this.name,
    required this.email,
    required this.rolePreset,
    required this.permissions,
    this.accountStatus = 'active',
    required this.createdAt,
    this.lastLoginAt,
  });

  bool get isActive => accountStatus == 'active';

  factory AppEmployeeModel.fromMap(Map<String, dynamic> map, String authUid) {
    final createdData = map['createdAt'];
    DateTime createdAtDate;
    if (createdData is Timestamp) {
      createdAtDate = createdData.toDate().toLocal();
    } else if (createdData is String) {
      createdAtDate = DateTime.tryParse(createdData)?.toLocal() ?? DateTime.now();
    } else {
      createdAtDate = DateTime.now();
    }

    final loginData = map['lastLoginAt'];
    DateTime? lastLoginDate;
    if (loginData is Timestamp) {
      lastLoginDate = loginData.toDate().toLocal();
    } else if (loginData is String) {
      lastLoginDate = DateTime.tryParse(loginData)?.toLocal();
    }

    return AppEmployeeModel(
      authUid: authUid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      rolePreset: map['rolePreset'] as String? ?? 'custom',
      permissions: List<String>.from(map['permissions'] ?? []),
      accountStatus: map['accountStatus'] as String? ?? 'active',
      createdAt: createdAtDate,
      lastLoginAt: lastLoginDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authUid': authUid,
      'name': name,
      'email': email,
      'rolePreset': rolePreset,
      'permissions': permissions,
      'accountStatus': accountStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastLoginAt != null) 'lastLoginAt': Timestamp.fromDate(lastLoginAt!),
    };
  }

  AppEmployeeModel copyWith({
    String? name,
    String? email,
    String? rolePreset,
    List<String>? permissions,
    String? accountStatus,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AppEmployeeModel(
      authUid: authUid,
      name: name ?? this.name,
      email: email ?? this.email,
      rolePreset: rolePreset ?? this.rolePreset,
      permissions: permissions ?? this.permissions,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  List<Object?> get props => [
        authUid,
        name,
        email,
        rolePreset,
        permissions,
        accountStatus,
        createdAt,
        lastLoginAt,
      ];
}
