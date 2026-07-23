import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/constants/admin_constants.dart';
import 'package:tahsel/features/create_account/data/services/create_account_auth_service.dart';
import 'package:tahsel/features/create_account/data/utils/search_keywords_builder.dart';
import 'package:tahsel/features/create_account/domain/services/user_access_policy.dart';

abstract class CreateAccountRemoteDataSource {
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data);
}

class CreateAccountRemoteDataSourceImpl implements CreateAccountRemoteDataSource {
  CreateAccountRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required CreateAccountService authService,
  }) : _firestore = firestore,
       _authService = authService;

  final FirebaseFirestore _firestore;
  final CreateAccountService _authService;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection(AdminConstants.usersCollection).doc(uid);

  @override
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final email = (data['email'] as String).trim();
    final password = data['password'] as String;
    final fullName = (data['fullName'] as String).trim();
    final phoneNumber = data['phoneNumber'] as String?;
    final projectName = (data['projectName'] as String).trim();
    final days = data['subscriptionDays'] as int? ?? 5;

    final credential = await _authService.createAuthUser(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final now = Timestamp.now();
    final subscriptionEndDate = DateTime.now().add(Duration(days: days));
    final endDate = Timestamp.fromDate(subscriptionEndDate);
    final graceEndDate = UserAccessPolicy.gracePeriodEnd(subscriptionEndDate)!;

    final userDoc = {
      'uid': uid,
      'fullName': fullName,
      'email': email.toLowerCase(),
      'phoneNumber': phoneNumber ?? '',
      'accountStatus': 'active',
      'projectName': projectName,
      'subscriptionStatus': 'active',
      'subscriptionSuspended': false,
      'subscriptionStart': now,
      'userType': data['userType'] ?? 'cafe',
      'platformType': data['platformType'] ?? "mobile",
      'isVip': data['isVip'] ?? false,
      'subscriptionEnd': endDate,
      'gracePeriodEnd': Timestamp.fromDate(graceEndDate),
      'loginAllowed': true,
      'authAccessRevoked': false,
      'authAccessReason': null,
      'authAccessRevokedAt': null,
      'createdAt': now,
      'lastLogin': null,
      'lastActive': null,
      'devicePlatform': null,
      'deletedAt': null,
      'forceLogoutAt': null,
      'searchKeywords': SearchKeywordsBuilder.build(
        uid: uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
      ),
      'stats': {
        'customers': 0,
        'debts': 0,
        'employees': 0,
        'transactions': 0,
        'expenses': 0,
      },
    };

    await _userRef(uid).set(userDoc);

    return {...userDoc, 'uid': uid};
  }
}
