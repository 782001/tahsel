import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tahsel/core/error/exceptions.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';

import '../../domain/usecases/login_usecase.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSourceBase {
  Future<UserModel> login({required LoginParameters parameters});
  Future<void> logout();
  Future<void> deleteAccount();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSourceBase {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> login({required LoginParameters parameters}) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: parameters.email,
        password: parameters.password,
      );
      if (userCredential.user != null) {
        // Fetch user document from Firestore
        final doc = await firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        final data = doc.data();

        if (data == null) {
          await firebaseAuth.signOut();
          throw ServerException('user_not_found');
        }

        // ── 1. Account status gate ────────────────────────────────────────
        final accountStatus = (data['accountStatus'] as String?) ?? 'active';
        if (accountStatus == 'deleted') {
          await firebaseAuth.signOut();
          throw ServerException('auth_user_deleted');
        }
        if (accountStatus == 'disabled') {
          await firebaseAuth.signOut();
          throw ServerException('auth_user_disabled');
        }
        if (accountStatus == 'suspended') {
          await firebaseAuth.signOut();
          throw ServerException('account_suspended');
        }

        final role = (data['role'] as String?) ?? 'owner';
        final ownerUid = data['ownerUid'] as String?;
        final isEmployee = (role == 'employee') ||
            (ownerUid != null && ownerUid.isNotEmpty);

        Map<String, dynamic> storeData = data;
        if (isEmployee && ownerUid != null && ownerUid.isNotEmpty) {
          final ownerDoc =
              await firestore.collection('users').doc(ownerUid).get();
          if (!ownerDoc.exists || ownerDoc.data() == null) {
            await firebaseAuth.signOut();
            throw ServerException('owner_not_found');
          }
          final ownerData = ownerDoc.data()!;
          final ownerStatus =
              (ownerData['accountStatus'] as String?) ?? 'active';
          if (ownerStatus == 'deleted' ||
              ownerStatus == 'disabled' ||
              ownerStatus == 'suspended') {
            await firebaseAuth.signOut();
            throw ServerException('account_disabled');
          }
          storeData = ownerData;
        }

        // ── 2. Subscription / grace-period gate (checked on store owner) ──
        final subscriptionEnd = storeData['subscriptionEnd'] != null
            ? (storeData['subscriptionEnd'] as Timestamp).toDate()
            : null;
        final now = DateTime.now();
        if (subscriptionEnd != null && now.isAfter(subscriptionEnd)) {
          // Grace period is 10 days after subscriptionEnd
          final gracePeriodEnd = subscriptionEnd.add(const Duration(days: 10));
          if (now.isAfter(gracePeriodEnd)) {
            // Past grace period → optimistically mark as expired (best-effort)
            if (!isEmployee && storeData['accountStatus'] != 'expired') {
              firestore
                  .collection('users')
                  .doc(userCredential.user!.uid)
                  .update({'accountStatus': 'expired'})
                  .ignore();
            }
            await firebaseAuth.signOut();
            throw ServerException('account_expired');
          }
          // Still within grace period — allow login
        }

        // ── 3. Platform restriction gate ─────────────────────────────────
        final platformType = (data['platformType'] as String?) ??
            (storeData['platformType'] as String?) ??
            'mobile';
        final currentPlatform = parameters.currentPlatform;
        if (!_isPlatformAllowed(platformType, currentPlatform)) {
          await firebaseAuth.signOut();
          throw ServerException('platform_not_allowed');
        }

        // ── 4. Success ────────────────────────────────────────────────────
        final userType = (storeData['userType'] as String?) ?? AppStrings.cafe;
        final isVip = (storeData['isVip'] as bool?) ?? false;
        final projectName = storeData['projectName'] as String?;
        final phoneNumber = (data['phoneNumber'] as String?) ??
            (storeData['phoneNumber'] as String?);
        final crn = storeData['crn'] as String?;
        final address = storeData['address'] as String?;
        final vat = storeData['vat'] as String?;
        final taxRate = (storeData['taxRate'] as num?)?.toDouble();
        final permissions = (data['permissions'] as List?)?.cast<String>() ??
            (role == 'owner' ? const ['*'] : const <String>[]);

        return UserModel.fromFirebaseUser(
          userCredential.user!,
          userType: userType,
          accountStatus: accountStatus,
          platformType: platformType,
          isVip: isVip,
          projectName: projectName,
          phoneNumber: phoneNumber,
          crn: crn,
          address: address,
          vat: vat,
          taxRate: taxRate,
          role: role,
          permissions: permissions,
          ownerUid: ownerUid,
          isEmployee: isEmployee,
        );
      } else {
        throw Exception('User not found');
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.printMessage(
        'FirebaseAuthException: [${e.code}] - ${e.message}',
      );
      throw ServerException(e.code);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.printMessage(e.toString());
      throw ServerException('default');
    }
  }

  /// Returns true if [platformType] (Firestore value) allows [currentPlatform].
  bool _isPlatformAllowed(String platformType, String currentPlatform) {
    if (platformType == 'both') return true;
    return platformType == currentPlatform;
  }

  @override
  Future<void> logout() async {
    try {
      await firestore.terminate();
      await firestore.clearPersistence();
    } catch (_) {
      // Ignore if cache is already cleared or throws
    }
    await firebaseAuth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = firebaseAuth.currentUser;
    if (user == null) throw ServerException('user_not_found');

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .update({'accountStatus': 'deleted'})
          .timeout(const Duration(seconds: 10));
    } on FirebaseException catch (e) {
      throw ServerException(e.code);
    } catch (e) {
      throw ServerException('delete_account_failed');
    }
  }
}
