import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/employee/data/models/employee_activity_model.dart';

class ActivityLoggerService {
  final FirebaseFirestore firestore;

  ActivityLoggerService({required this.firestore});

  /// Generates a standardized activity model for current session or explicit actor.
  EmployeeActivityModel createActivityModel({
    required String ownerUid,
    String? employeeUid,
    String? employeeName,
    String? rolePreset,
    required String actionCategory,
    required String actionType,
    required String actionTitle,
    required String details,
    double? amount,
    Map<String, dynamic>? extraData,
    DateTime? timestamp,
    bool isOfflineSync = false,
  }) {
    final effectiveEmpUid = employeeUid ?? AppStrings.employeeAuthUid;
    final effectiveEmpName = employeeName ??
        (AppStrings.loggedInEmployeeName.isNotEmpty
            ? AppStrings.loggedInEmployeeName
            : 'موظف النظام');

    final now = timestamp ?? DateTime.now();
    final docId =
        'act_${effectiveEmpUid}_${now.millisecondsSinceEpoch}_${now.microsecondsSinceEpoch % 1000}';

    Map<String, dynamic>? cleanExtraData;
    if (extraData != null) {
      cleanExtraData = {};
      for (final entry in extraData.entries) {
        if (entry.value != null) {
          cleanExtraData[entry.key] = entry.value;
        }
      }
    }

    return EmployeeActivityModel(
      id: docId,
      ownerUid: ownerUid.trim(),
      employeeUid: effectiveEmpUid,
      employeeName: effectiveEmpName,
      rolePreset: rolePreset ?? AppStrings.userRole,
      actionCategory: actionCategory,
      actionType: actionType,
      actionTitle: actionTitle,
      details: details,
      amount: amount,
      extraData: cleanExtraData,
      timestamp: now,
      isOfflineSync: isOfflineSync,
    );
  }

  /// Appends activity entry to an existing Firestore WriteBatch atomically.
  DocumentReference? appendToBatch(
    WriteBatch batch, {
    required String ownerUid,
    String? employeeUid,
    String? employeeName,
    String? rolePreset,
    required String actionCategory,
    required String actionType,
    required String actionTitle,
    required String details,
    double? amount,
    Map<String, dynamic>? extraData,
    DateTime? timestamp,
    bool isOfflineSync = false,
  }) {
    try {
      if (ownerUid.trim().isEmpty) return null;

      // Only log if action performed by an employee (or explicitly provided)
      final effectiveEmpUid = employeeUid ?? AppStrings.employeeAuthUid;
      if (effectiveEmpUid.isEmpty && !AppStrings.isEmployee) {
        return null;
      }

      final model = createActivityModel(
        ownerUid: ownerUid.trim(),
        employeeUid: effectiveEmpUid,
        employeeName: employeeName,
        rolePreset: rolePreset,
        actionCategory: actionCategory,
        actionType: actionType,
        actionTitle: actionTitle,
        details: details,
        amount: amount,
        extraData: extraData,
        timestamp: timestamp,
        isOfflineSync: isOfflineSync,
      );

      final docRef = firestore
          .collection('users')
          .doc(ownerUid.trim())
          .collection('employee_activities')
          .doc(model.id);

      batch.set(docRef, model.toMap());
      return docRef;
    } catch (e) {
      AppLogger.printMessage('[ActivityLoggerService] appendToBatch error: $e');
      return null;
    }
  }

  /// Logs activity standalone asynchronously.
  Future<void> logStandalone({
    required String ownerUid,
    String? employeeUid,
    String? employeeName,
    String? rolePreset,
    required String actionCategory,
    required String actionType,
    required String actionTitle,
    required String details,
    double? amount,
    Map<String, dynamic>? extraData,
    DateTime? timestamp,
    bool isOfflineSync = false,
  }) async {
    try {
      if (ownerUid.trim().isEmpty) return;

      final effectiveEmpUid = employeeUid ?? AppStrings.employeeAuthUid;
      if (effectiveEmpUid.isEmpty && !AppStrings.isEmployee) {
        return;
      }

      final model = createActivityModel(
        ownerUid: ownerUid.trim(),
        employeeUid: effectiveEmpUid,
        employeeName: employeeName,
        rolePreset: rolePreset,
        actionCategory: actionCategory,
        actionType: actionType,
        actionTitle: actionTitle,
        details: details,
        amount: amount,
        extraData: extraData,
        timestamp: timestamp,
        isOfflineSync: isOfflineSync,
      );

      await firestore
          .collection('users')
          .doc(ownerUid.trim())
          .collection('employee_activities')
          .doc(model.id)
          .set(model.toMap());
    } catch (e) {
      AppLogger.printMessage('[ActivityLoggerService] Failed to log activity: $e');
    }
  }
}
