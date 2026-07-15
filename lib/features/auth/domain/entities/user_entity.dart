import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String userType;
  final String accountStatus;
  final String platformType;
  final Timestamp createdAt;

  const UserEntity({
    required this.uid,
    required this.email,
    this.userType = 'cafe',
    this.displayName,
    this.accountStatus = 'active',
    this.platformType = 'mobile',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    userType,
    accountStatus,
    platformType,
    createdAt,
  ];
}
