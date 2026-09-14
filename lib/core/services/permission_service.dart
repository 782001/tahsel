import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/storage/secure_storage_helper.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';

/// Single source of truth for Role-Based Access Control (RBAC) permissions.
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  static const String keyRole = 'user_role';
  static const String keyPermissions = 'user_permissions';
  static const String keyEmployeeUid = 'employee_auth_uid';

  String _currentRole = 'owner';
  final Set<String> _permissions = {AppPermissions.all};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _employeeDocSubscription;

  /// Notifier for UI reactivity when permissions change dynamically.
  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  String get currentRole => _currentRole;
  bool get isOwner => _currentRole == 'owner' || _currentRole.isEmpty;
  bool get isEmployee => _currentRole == 'employee';
  bool get isRealtimeListenerActive => _employeeDocSubscription != null;
  Set<String> get permissions => Set.unmodifiable(_permissions);

  /// Initializes permissions in memory and reflects them to AppStrings.
  void init({
    required String role,
    required List<String> permissionsList,
    String? employeeUid,
  }) {
    _currentRole = (role.isEmpty || role == 'owner') ? 'owner' : 'employee';
    _permissions.clear();

    if (isOwner) {
      _permissions.add(AppPermissions.all);
    } else {
      _permissions.addAll(permissionsList);
    }

    // Mirror to AppStrings for fast access
    AppStrings.userRole = _currentRole;
    AppStrings.userPermissions = _permissions.toList();
    if (employeeUid != null) {
      AppStrings.employeeAuthUid = employeeUid;
    }

    changeNotifier.value++;
    AppLogger.printMessage(
      '[PermissionService] Initialized: role=$_currentRole, permissionsCount=${_permissions.length}',
    );
  }

  /// Checks if current user has the given [permission].
  /// Owners always have access (`*`).
  bool hasPermission(String permission) {
    if (isOwner || _permissions.contains(AppPermissions.all)) {
      return true;
    }
    return _permissions.contains(permission);
  }

  /// Checks if current user has at least one of the given [permissions].
  bool hasAnyPermission(List<String> perms) {
    if (isOwner || _permissions.contains(AppPermissions.all)) {
      return true;
    }
    return perms.any((p) => _permissions.contains(p));
  }

  /// Checks if current user has all of the given [permissions].
  bool hasAllPermissions(List<String> perms) {
    if (isOwner || _permissions.contains(AppPermissions.all)) {
      return true;
    }
    return perms.every((p) => _permissions.contains(p));
  }

  /// Starts a real-time Firestore listener for logged-in employees.
  /// Automatically revokes access or syncs updated permissions without app restart.
  void startRealtimeListener({
    required String employeeUid,
    required SecureStorageHelper storage,
    VoidCallback? onAccountDisabled,
  }) {
    stopRealtimeListener();
    if (employeeUid.isEmpty || isOwner) return;

    try {
      _employeeDocSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(employeeUid)
          .snapshots()
          .listen((snapshot) async {
        if (!snapshot.exists) {
          AppLogger.printMessage('[PermissionService] Employee doc deleted in Firestore.');
          onAccountDisabled?.call();
          return;
        }

        final data = snapshot.data();
        if (data == null) return;

        final isActive = data['isActive'] as bool? ?? true;
        final accountStatus = (data['accountStatus'] as String?) ?? 'active';

        if (!isActive ||
            accountStatus == 'disabled' ||
            accountStatus == 'deleted' ||
            accountStatus == 'suspended') {
          AppLogger.printMessage(
            '[PermissionService] Employee account revoked in real-time ($accountStatus, active: $isActive).',
          );
          onAccountDisabled?.call();
          return;
        }

        // Update permissions in real-time if changed
        final rawPerms = data['permissions'];
        final List<String> updatedPerms = rawPerms is List
            ? rawPerms.map((e) => e.toString()).toList()
            : [];

        final currentPermsList = _permissions.toList()..sort();
        final newPermsList = List<String>.from(updatedPerms)..sort();

        if (currentPermsList.join(',') != newPermsList.join(',')) {
          AppLogger.printMessage(
            '[PermissionService] Real-time permissions updated: ${updatedPerms.length} permissions.',
          );
          _permissions.clear();
          _permissions.addAll(updatedPerms);
          AppStrings.userPermissions = _permissions.toList();
          await saveToStorage(storage);
          changeNotifier.value++;
        }
      }, onError: (e) {
        AppLogger.printMessage('[PermissionService] Real-time listener error: $e');
      });
    } catch (e) {
      AppLogger.printMessage('[PermissionService] Failed to start real-time listener: $e');
    }
  }

  /// Cancels active real-time employee document listener.
  void stopRealtimeListener() {
    _employeeDocSubscription?.cancel();
    _employeeDocSubscription = null;
  }

  /// Saves session role and permissions to SecureStorage.
  Future<void> saveToStorage(SecureStorageHelper storage) async {
    await storage.saveData(key: keyRole, value: _currentRole);
    await storage.saveData(
      key: keyPermissions,
      value: _permissions.join(','),
    );
    if (AppStrings.employeeAuthUid.isNotEmpty) {
      await storage.saveData(
        key: keyEmployeeUid,
        value: AppStrings.employeeAuthUid,
      );
    }
  }

  /// Loads permissions from SecureStorage during startup / offline-first boot.
  Future<void> loadFromStorage(SecureStorageHelper storage) async {
    try {
      final role = await storage.getData(key: keyRole) ?? 'owner';
      final permsStr = await storage.getData(key: keyPermissions);
      final empUid = await storage.getData(key: keyEmployeeUid);

      List<String> permsList = [];
      if (permsStr != null && permsStr.isNotEmpty) {
        permsList = permsStr.split(',');
      } else if (role == 'owner') {
        permsList = [AppPermissions.all];
      }

      init(
        role: role,
        permissionsList: permsList,
        employeeUid: empUid,
      );
    } catch (e) {
      AppLogger.printMessage('[PermissionService] Error loading from storage: $e');
      // Fallback safe default: owner full access
      init(role: 'owner', permissionsList: [AppPermissions.all]);
    }
  }

  /// Clears permissions and resets to default on logout.
  Future<void> clear(SecureStorageHelper storage) async {
    stopRealtimeListener();
    _currentRole = 'owner';
    _permissions.clear();
    _permissions.add(AppPermissions.all);

    AppStrings.userRole = 'owner';
    AppStrings.userPermissions = [AppPermissions.all];
    AppStrings.employeeAuthUid = '';

    await storage.deleteData(key: keyRole);
    await storage.deleteData(key: keyPermissions);
    await storage.deleteData(key: keyEmployeeUid);

    changeNotifier.value++;
  }
}
