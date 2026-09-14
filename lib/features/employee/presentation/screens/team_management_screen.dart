import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/custom_app_bar/custom_app_bar.dart';

import '../cubit/team_management_cubit.dart';
import '../cubit/team_management_state.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  late final TeamManagementCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<TeamManagementCubit>();
    _cubit.loadEmployees();
  }

  void _showDeleteConfirmation(String employeeAuthUid, String employeeName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.scafoldBackGround,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 26),
            SizedBox(width: 8.w),
            Text(
              AppStrings.deleteEmployeeAccess.tr(),
              style: TextStyles.customStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
          ],
        ),
        content: Text(
          '${AppStrings.deleteEmployeeConfirm.tr()}\n\n${AppStrings.employeeName.tr()}: $employeeName',
          style: TextStyles.customStyle(
            fontSize: 14,
            color: AppColors.sandText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.cancel.tr(),
              style: TextStyles.customStyle(
                fontSize: 14,
                color: AppColors.sandText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cubit.deleteEmployee(employeeAuthUid: employeeAuthUid);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              AppStrings.deleteAccount.tr(),
              style: TextStyles.customStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isPushed = !(ModalRoute.of(context)?.isFirst ?? true);
    final showBackButton = isPushed || !isDesktop;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        appBar: CustomAppBar(
          centerTitle: AppStrings.teamAndPermissions.tr(),
          leadingIcon: showBackButton
              ? const Icon(Icons.arrow_back_ios_new_rounded)
              : null,
          onLeadingTap: showBackButton
              ? () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    try {
                      context.read<MainLayoutCubit>().changeBottomNav(0);
                    } catch (_) {}
                  }
                }
              : null,
          actionIcon: Padding(
            padding: EdgeInsetsDirectional.only(end: 14.w),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.vipGoldStart, AppColors.vipGoldEnd],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.vipGoldStart.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      size: 14,
                      color: Colors.black87,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'VIP',
                      style: TextStyles.customStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.addAppEmployee,
            arguments: _cubit,
          ),
          backgroundColor: AppColors.primaryColor,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: Text(
            AppStrings.addAppEmployee.tr(),
            style: TextStyles.customStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<TeamManagementCubit, TeamManagementState>(
            listener: (context, state) {
              if (state is TeamManagementActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message.tr(),
                      style: TextStyles.customStyle(color: Colors.white),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (state is TeamManagementFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: TextStyles.customStyle(color: Colors.white),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is TeamManagementLoading && _cubit.employees.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final employees = _cubit.employees;

              if (employees.isEmpty) {
                return _buildEmptyState(context);
              }

              return RefreshIndicator(
                onRefresh: () => _cubit.loadEmployees(),
                color: AppColors.primaryColor,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 900 : double.infinity,
                    ),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 24 : 16.w,
                        vertical: 16.h,
                      ),
                      children: [
                        // Overview Banner
                        _buildOverviewCard(employees),
                        SizedBox(height: 16.h),

                        // List Header
                        Text(
                          '${AppStrings.registeredSystemEmployees.tr()} (${employees.length})',
                          style: TextStyles.customStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 10.h),

                        // Employee Cards
                        ...employees.map(
                          (emp) => _buildEmployeeCard(context, emp),
                        ),
                        SizedBox(height: 80.h), // Spacing for FAB
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(List employees) {
    final activeCount = employees.where((e) => e.isActive).length;
    final disabledCount = employees.length - activeCount;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: AppColors.vipGoldStart.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.vipGoldStart.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: 15.w,
            bottom: -15.h,
            child: Icon(
              Icons.admin_panel_settings_outlined,
              size: 90,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.whiteColor.withValues(alpha: 0.25),
                            AppColors.whiteColor.withValues(alpha: 0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.vipGoldStart.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppColors.vipGoldStart,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.teamAndPermissions.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            AppStrings.teamAndPermissionsDesc.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // VIP Golden Metallic Pill
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.vipGoldStart,
                            AppColors.vipGoldEnd,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.vipGoldStart.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            size: 13,
                            color: Colors.black87,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'VIP',
                            style: TextStyles.customStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      AppStrings.totalEmployeesStat.tr(),
                      employees.length.toString(),
                    ),
                    Container(height: 25.h, width: 1, color: Colors.white24),
                    _buildStatColumn(
                      AppStrings.activeInService.tr(),
                      activeCount.toString(),
                    ),
                    Container(height: 25.h, width: 1, color: Colors.white24),
                    _buildStatColumn(
                      AppStrings.temporarilyDisabled.tr(),
                      disabledCount.toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyles.customStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyles.customStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(BuildContext context, dynamic emp) {
    final bool isActive = emp.isActive;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isActive
              ? AppColors.lightGreyColor
              : AppColors.error.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar, Name, Email, Status Switch
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: isActive
                    ? AppColors.primaryColor.withValues(alpha: 0.1)
                    : AppColors.disabledColor.withValues(alpha: 0.2),
                child: Text(
                  emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '؟',
                  style: TextStyles.customStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? AppColors.primaryColor
                        : AppColors.sandText,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.name,
                      style: TextStyles.customStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      emp.email,
                      style: TextStyles.customStyle(
                        fontSize: 12,
                        color: AppColors.sandText,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Switch
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isActive,
                  activeThumbColor: AppColors.success,
                  onChanged: (_) {
                    _cubit.toggleStatus(
                      employeeAuthUid: emp.authUid,
                      currentStatus: emp.accountStatus,
                    );
                  },
                ),
              ),
            ],
          ),
          Divider(height: 18.h, color: AppColors.lightGreyColor),

          // Bottom Row: Role Badge, Permissions Count, Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildRoleBadge(emp.rolePreset),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.scafoldBackGround,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${emp.permissions.length} ${AppStrings.permissionsCount.tr()}',
                      style: TextStyles.customStyle(
                        fontSize: 11,
                        color: AppColors.sandText,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: AppColors.primaryColor,
                    tooltip: AppStrings.editAppEmployee.tr(),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.editAppEmployee,
                        arguments: {'employee': emp, 'cubit': _cubit},
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: AppColors.error,
                    tooltip: AppStrings.deleteEmployeeAccess.tr(),
                    onPressed: () =>
                        _showDeleteConfirmation(emp.authUid, emp.name),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String preset) {
    String label = preset;
    Color color = AppColors.primaryColor;

    switch (preset) {
      case AppPermissions.roleCashier:
        label = AppStrings.roleCashierLabel.tr();
        color = Colors.blue;
        break;
      case AppPermissions.roleStorekeeper:
        label = AppStrings.roleStorekeeperLabel.tr();
        color = Colors.orange;
        break;
      case AppPermissions.roleAccountant:
        label = AppStrings.roleAccountantLabel.tr();
        color = Colors.teal;
        break;
      case AppPermissions.roleSupervisor:
        label = AppStrings.roleSupervisorLabel.tr();
        color = Colors.purple;
        break;
      case AppPermissions.roleCustom:
        label = AppStrings.roleCustomLabel.tr();
        color = AppColors.sandText;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyles.customStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_add_outlined,
                size: 64,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              AppStrings.noAppEmployeesYet.tr(),
              style: TextStyles.customStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              AppStrings.noAppEmployeesDesc.tr(),
              style: TextStyles.customStyle(
                fontSize: 13,
                color: AppColors.sandText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.addAppEmployee,
                arguments: _cubit,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                AppStrings.addAppEmployee.tr(),
                style: TextStyles.customStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
