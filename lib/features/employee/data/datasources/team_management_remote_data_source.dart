import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tahsel/core/error/exceptions.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import '../models/app_employee_model.dart';

abstract class TeamManagementRemoteDataSource {
  Future<AppEmployeeModel> createAppEmployee({
    required String ownerUid,
    required String name,
    required String email,
    required String password,
    required String rolePreset,
    required List<String> permissions,
  });

  Future<List<AppEmployeeModel>> getAppEmployees(String ownerUid);

  Future<void> updateAppEmployeePermissions({
    required String ownerUid,
    required String employeeAuthUid,
    required String rolePreset,
    required List<String> permissions,
    String? name,
  });

  Future<void> toggleEmployeeStatus({
    required String ownerUid,
    required String employeeAuthUid,
    required String newStatus,
  });

  Future<void> deleteAppEmployee({
    required String ownerUid,
    required String employeeAuthUid,
  });
}

class TeamManagementRemoteDataSourceImpl implements TeamManagementRemoteDataSource {
  final FirebaseFirestore firestore;

  TeamManagementRemoteDataSourceImpl({required this.firestore});

  @override
  Future<AppEmployeeModel> createAppEmployee({
    required String ownerUid,
    required String name,
    required String email,
    required String password,
    required String rolePreset,
    required List<String> permissions,
  }) async {
    FirebaseApp? tempApp;
    try {
      final appName = 'emp_creator_${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) {
        throw ServerException('Failed to create employee credentials');
      }

      final employeeAuthUid = user.uid;
      final now = DateTime.now();

      // Fetch owner's store profile to inherit userType and metadata
      String ownerUserType = AppStrings.cafe;
      String? ownerProjectName;
      bool ownerIsVip = false;
      try {
        final ownerDoc = await firestore.collection('users').doc(ownerUid).get();
        if (ownerDoc.exists && ownerDoc.data() != null) {
          final oData = ownerDoc.data()!;
          ownerUserType = (oData['userType'] as String?) ?? AppStrings.cafe;
          ownerProjectName = oData['projectName'] as String?;
          ownerIsVip = (oData['isVip'] as bool?) ?? false;
        }
      } catch (_) {}

      final batch = firestore.batch();

      // 1. Top-level user document for authentication & RBAC resolution
      final userRef = firestore.collection('users').doc(employeeAuthUid);
      batch.set(userRef, {
        'role': 'employee',
        'ownerUid': ownerUid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'accountStatus': 'active',
        'platformType': 'both',
        'permissions': permissions,
        'userType': ownerUserType,
        'projectName': ownerProjectName,
        'isVip': ownerIsVip,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Owner's team roster record
      final teamRef = firestore
          .collection('users')
          .doc(ownerUid)
          .collection('app_employees')
          .doc(employeeAuthUid);

      final employeeModel = AppEmployeeModel(
        authUid: employeeAuthUid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        rolePreset: rolePreset,
        permissions: permissions,
        accountStatus: 'active',
        createdAt: now,
      );

      batch.set(teamRef, employeeModel.toMap());

      await batch.commit();

      AppLogger.printMessage(
        '[TeamManagement] Created employee $employeeAuthUid ($email) successfully',
      );

      return employeeModel;
    } on FirebaseAuthException catch (e) {
      AppLogger.printMessage('[TeamManagement] FirebaseAuthException: ${e.code}');
      throw ServerException(e.code);
    } catch (e) {
      AppLogger.printMessage('[TeamManagement] Error creating employee: $e');
      throw ServerException(e.toString());
    } finally {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (_) {}
      }
    }
  }

  @override
  Future<List<AppEmployeeModel>> getAppEmployees(String ownerUid) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(ownerUid)
          .collection('app_employees')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AppEmployeeModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      AppLogger.printMessage('[TeamManagement] Error getting employees: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateAppEmployeePermissions({
    required String ownerUid,
    required String employeeAuthUid,
    required String rolePreset,
    required List<String> permissions,
    String? name,
  }) async {
    try {
      final batch = firestore.batch();
      final trimmedName = name?.trim();

      // Update in employee's top-level auth document
      final userRef = firestore.collection('users').doc(employeeAuthUid);
      final Map<String, dynamic> userUpdates = {
        'permissions': permissions,
        'lastPermissionsUpdatedAt': FieldValue.serverTimestamp(),
      };
      if (trimmedName != null && trimmedName.isNotEmpty) {
        userUpdates['name'] = trimmedName;
        userUpdates['fullName'] = trimmedName;
      }
      batch.update(userRef, userUpdates);

      // Update in owner's team roster
      final teamRef = firestore
          .collection('users')
          .doc(ownerUid)
          .collection('app_employees')
          .doc(employeeAuthUid);

      final Map<String, dynamic> teamUpdates = {
        'rolePreset': rolePreset,
        'permissions': permissions,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };
      if (trimmedName != null && trimmedName.isNotEmpty) {
        teamUpdates['name'] = trimmedName;
      }

      batch.update(teamRef, teamUpdates);

      await batch.commit();
      AppLogger.printMessage(
        '[TeamManagement] Updated permissions and profile for $employeeAuthUid',
      );
    } catch (e) {
      AppLogger.printMessage('[TeamManagement] Error updating permissions: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> toggleEmployeeStatus({
    required String ownerUid,
    required String employeeAuthUid,
    required String newStatus,
  }) async {
    try {
      final batch = firestore.batch();

      final userRef = firestore.collection('users').doc(employeeAuthUid);
      batch.update(userRef, {'accountStatus': newStatus});

      final teamRef = firestore
          .collection('users')
          .doc(ownerUid)
          .collection('app_employees')
          .doc(employeeAuthUid);
      batch.update(teamRef, {'accountStatus': newStatus});

      await batch.commit();
      AppLogger.printMessage(
        '[TeamManagement] Status toggled for $employeeAuthUid -> $newStatus',
      );
    } catch (e) {
      AppLogger.printMessage('[TeamManagement] Error toggling status: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteAppEmployee({
    required String ownerUid,
    required String employeeAuthUid,
  }) async {
    try {
      final batch = firestore.batch();

      // Mark status as deleted in top-level user doc
      final userRef = firestore.collection('users').doc(employeeAuthUid);
      batch.update(userRef, {'accountStatus': 'deleted'});

      // Delete from owner's team collection
      final teamRef = firestore
          .collection('users')
          .doc(ownerUid)
          .collection('app_employees')
          .doc(employeeAuthUid);
      batch.delete(teamRef);

      await batch.commit();
      AppLogger.printMessage(
        '[TeamManagement] Deleted employee $employeeAuthUid',
      );
    } catch (e) {
      AppLogger.printMessage('[TeamManagement] Error deleting employee: $e');
      throw ServerException(e.toString());
    }
  }
}
