import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/error/exceptions.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import '../../data/datasources/team_management_remote_data_source.dart';
import '../../data/models/app_employee_model.dart';
import 'team_management_state.dart';

class TeamManagementCubit extends Cubit<TeamManagementState> {
  final TeamManagementRemoteDataSource remoteDataSource;

  TeamManagementCubit({required this.remoteDataSource})
      : super(TeamManagementInitial());

  List<AppEmployeeModel> _employees = [];
  List<AppEmployeeModel> get employees => List.unmodifiable(_employees);

  Future<void> loadEmployees() async {
    final ownerUid = AppStrings.userToken;
    if (ownerUid.isEmpty) return;

    if (!PermissionService.instance.isOwner) {
      emit(TeamManagementFailure(AppStrings.noPermissionForAction.tr()));
      return;
    }

    emit(TeamManagementLoading());
    try {
      _employees = await remoteDataSource.getAppEmployees(ownerUid);
      emit(TeamManagementLoaded(_employees));
    } catch (e) {
      emit(TeamManagementFailure(e.toString()));
    }
  }

  Future<bool> addEmployee({
    required String name,
    required String email,
    required String password,
    required String rolePreset,
    required List<String> permissions,
  }) async {
    final ownerUid = AppStrings.userToken;
    if (ownerUid.isEmpty) return false;

    if (!PermissionService.instance.isOwner) {
      emit(TeamManagementFailure(AppStrings.noPermissionForAction.tr()));
      return false;
    }

    // Privilege escalation guard: Non-owners cannot grant user-management or unheld permissions
    if (!PermissionService.instance.isOwner) {
      if (permissions.contains(AppPermissions.employeesManageAppUsers) ||
          permissions.contains(AppPermissions.all)) {
        emit(TeamManagementFailure(AppStrings.noPermissionForAction.tr()));
        return false;
      }
      final myPerms = PermissionService.instance.permissions;
      if (!permissions.every((p) => myPerms.contains(p))) {
        emit(TeamManagementFailure(AppStrings.noPermissionForAction.tr()));
        return false;
      }
    }

    emit(TeamManagementLoading());
    try {
      final newEmp = await remoteDataSource.createAppEmployee(
        ownerUid: ownerUid,
        name: name,
        email: email,
        password: password,
        rolePreset: rolePreset,
        permissions: permissions,
      );

      _employees = [newEmp, ..._employees];
      emit(const TeamManagementActionSuccess(AppStrings.appEmployeeAddedSuccess));
      emit(TeamManagementLoaded(_employees));
      return true;
    } on ServerException catch (e) {
      emit(TeamManagementFailure(_mapExceptionCode(e.code)));
      emit(TeamManagementLoaded(_employees));
      return false;
    } catch (e) {
      emit(TeamManagementFailure(e.toString()));
      emit(TeamManagementLoaded(_employees));
      return false;
    }
  }

  Future<bool> updatePermissions({
    required String employeeAuthUid,
    required String rolePreset,
    required List<String> permissions,
  }) async {
    final ownerUid = AppStrings.userToken;
    if (ownerUid.isEmpty) return false;

    if (!PermissionService.instance.isOwner) {
      emit(TeamManagementFailure(AppStrings.noPermissionForAction.tr()));
      return false;
    }

    if (employeeAuthUid == AppStrings.employeeAuthUid || employeeAuthUid == ownerUid) {
      emit(TeamManagementFailure(AppStrings.cannotModifySelf.tr()));
      return false;
    }

    // Privilege escalation guard: Non-owners cannot grant user-management or unheld permissions
    if (!PermissionService.instance.isOwner) {
      if (permissions.contains(AppPermissions.employeesManageAppUsers) ||
          permissions.contains(AppPermissions.all)) {
        emit(TeamManagementFailure(AppStrings.noPermissionForAction.tr()));
        return false;
      }
      final myPerms = PermissionService.instance.permissions;
      if (!permissions.every((p) => myPerms.contains(p))) {
        emit(TeamManagementFailure(AppStrings.noPermissionForAction.tr()));
        return false;
      }
    }

    emit(TeamManagementLoading());
    try {
      await remoteDataSource.updateAppEmployeePermissions(
        ownerUid: ownerUid,
        employeeAuthUid: employeeAuthUid,
        rolePreset: rolePreset,
        permissions: permissions,
      );

      _employees = _employees.map((emp) {
        if (emp.authUid == employeeAuthUid) {
          return emp.copyWith(
            rolePreset: rolePreset,
            permissions: permissions,
          );
        }
        return emp;
      }).toList();

      emit(const TeamManagementActionSuccess(AppStrings.employeeUpdatedSuccess));
      emit(TeamManagementLoaded(_employees));
      return true;
    } catch (e) {
      emit(TeamManagementFailure(e.toString()));
      emit(TeamManagementLoaded(_employees));
      return false;
    }
  }

  Future<void> toggleStatus({
    required String employeeAuthUid,
    required String currentStatus,
  }) async {
    final ownerUid = AppStrings.userToken;
    if (ownerUid.isEmpty) return;

    if (!PermissionService.instance.isOwner) {
      emit(TeamManagementFailure(AppStrings.noPermissionForAction.tr()));
      return;
    }

    if (employeeAuthUid == AppStrings.employeeAuthUid || employeeAuthUid == ownerUid) {
      emit(TeamManagementFailure(AppStrings.cannotModifySelf.tr()));
      return;
    }

    final newStatus = (currentStatus == 'active') ? 'disabled' : 'active';
    try {
      await remoteDataSource.toggleEmployeeStatus(
        ownerUid: ownerUid,
        employeeAuthUid: employeeAuthUid,
        newStatus: newStatus,
      );

      _employees = _employees.map((emp) {
        if (emp.authUid == employeeAuthUid) {
          return emp.copyWith(accountStatus: newStatus);
        }
        return emp;
      }).toList();

      emit(TeamManagementLoaded(_employees));
    } catch (e) {
      emit(TeamManagementFailure(e.toString()));
      emit(TeamManagementLoaded(_employees));
    }
  }

  Future<bool> deleteEmployee({required String employeeAuthUid}) async {
    final ownerUid = AppStrings.userToken;
    if (ownerUid.isEmpty) return false;

    if (!PermissionService.instance.isOwner) {
      emit(TeamManagementFailure(AppStrings.noPermissionForAction.tr()));
      return false;
    }

    if (employeeAuthUid == AppStrings.employeeAuthUid || employeeAuthUid == ownerUid) {
      emit(TeamManagementFailure(AppStrings.cannotDeleteSelf.tr()));
      return false;
    }

    emit(TeamManagementLoading());
    try {
      await remoteDataSource.deleteAppEmployee(
        ownerUid: ownerUid,
        employeeAuthUid: employeeAuthUid,
      );

      _employees = _employees.where((e) => e.authUid != employeeAuthUid).toList();
      emit(const TeamManagementActionSuccess(AppStrings.employeeDeletedSuccess));
      emit(TeamManagementLoaded(_employees));
      return true;
    } catch (e) {
      emit(TeamManagementFailure(e.toString()));
      emit(TeamManagementLoaded(_employees));
      return false;
    }
  }

  String _mapExceptionCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return AppStrings.emailAlreadyInUse.tr();
      case 'weak-password':
        return AppStrings.passwordMin6Chars.tr();
      case 'invalid-email':
        return AppStrings.emailFormatInvalid.tr();
      default:
        return code;
    }
  }
}
