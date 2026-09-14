import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/shared/widgets/custom_app_bar/custom_app_bar.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';
import 'package:tahsel/routes/app_routes.dart';

import '../../data/models/app_employee_model.dart';
import '../cubit/team_management_cubit.dart';

class EditAppEmployeeScreen extends StatefulWidget {
  final AppEmployeeModel employee;
  final TeamManagementCubit cubit;

  const EditAppEmployeeScreen({
    super.key,
    required this.employee,
    required this.cubit,
  });

  static Future<void> push(
    BuildContext context, {
    required AppEmployeeModel employee,
    required TeamManagementCubit cubit,
  }) {
    return Navigator.pushNamed(
      context,
      AppRoutes.editAppEmployee,
      arguments: {
        'employee': employee,
        'cubit': cubit,
      },
    );
  }

  @override
  State<EditAppEmployeeScreen> createState() => _EditAppEmployeeScreenState();
}

class _EditAppEmployeeScreenState extends State<EditAppEmployeeScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late String _selectedPreset;
  late final Set<String> _selectedPermissions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _emailController = TextEditingController(text: widget.employee.email);
    _selectedPreset = widget.employee.rolePreset;
    _selectedPermissions = Set.from(widget.employee.permissions);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset != AppPermissions.roleCustom) {
        _selectedPermissions.clear();
        _selectedPermissions.addAll(
          AppPermissions.permissionsForPreset(preset),
        );
      }
    });
  }

  void _togglePermission(String key) {
    setState(() {
      if (_selectedPermissions.contains(key)) {
        _selectedPermissions.remove(key);
      } else {
        _selectedPermissions.add(key);
      }
      _selectedPreset = AppPermissions.roleCustom;
    });
  }

  void _selectAll() {
    setState(() {
      for (final group in AppPermissions.allGroups) {
        for (final item in group.items) {
          if (!PermissionService.instance.isOwner) {
            if (item.key == AppPermissions.employeesManageAppUsers) continue;
            if (!PermissionService.instance.hasPermission(item.key)) continue;
          }
          _selectedPermissions.add(item.key);
        }
      }
      _selectedPreset = AppPermissions.roleCustom;
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedPermissions.clear();
      _selectedPreset = AppPermissions.roleCustom;
    });
  }

  Future<void> _submit() async {
    if (_selectedPermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.appEmployeeSelectAtLeastOnePermission.tr(),
            style: TextStyles.customStyle(color: AppColors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.cubit.updatePermissions(
      employeeAuthUid: widget.employee.authUid,
      rolePreset: _selectedPreset,
      permissions: _selectedPermissions.toList(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocProvider.value(
      value: widget.cubit,
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        appBar: CustomAppBar(
          centerTitle: AppStrings.editAppEmployee.tr(),
          leadingIcon: const Icon(Icons.arrow_back_ios_new_rounded),
          onLeadingTap: () => Navigator.pop(context),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.only(end: 14.w),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 9.w,
                    vertical: 4.h,
                  ),
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
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 860 : double.infinity,
            ),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16.w,
                vertical: isDesktop ? 24 : 16.h,
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                // Employee Profile Summary Card
                _buildEmployeeProfileCard(isDesktop),
                SizedBox(height: isDesktop ? 20 : 16.h),

                // Account Information (ReadOnly fields with QuickAddTextField)
                _buildSectionCard(
                  isDesktop: isDesktop,
                  title: AppStrings.appEmployeeRegisteredAccountInfo.tr(),
                  icon: Icons.badge_outlined,
                  child: isDesktop
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.appEmployeeNameField.tr(),
                                        style: TextStyles.customStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      QuickAddTextField(
                                        hint: AppStrings.appEmployeeNameHint.tr(),
                                        controller: _nameController,
                                        icon: Icons.person_outline_rounded,
                                        readOnly: true,
                                        suffixIcon: Icons.lock_outline_rounded,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.employeeEmail.tr(),
                                        style: TextStyles.customStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      QuickAddTextField(
                                        hint: 'employee@example.com',
                                        controller: _emailController,
                                        icon: Icons.email_outlined,
                                        readOnly: true,
                                        suffixIcon: Icons.lock_outline_rounded,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: AppColors.sandText,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    AppStrings.appEmployeeAccountCredsNote.tr(),
                                    style: TextStyles.customStyle(
                                      fontSize: 11,
                                      color: AppColors.sandText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.appEmployeeNameField.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            QuickAddTextField(
                              hint: AppStrings.appEmployeeNameHint.tr(),
                              controller: _nameController,
                              icon: Icons.person_outline_rounded,
                              readOnly: true,
                              suffixIcon: Icons.lock_outline_rounded,
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              AppStrings.employeeEmail.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            QuickAddTextField(
                              hint: 'employee@example.com',
                              controller: _emailController,
                              icon: Icons.email_outlined,
                              readOnly: true,
                              suffixIcon: Icons.lock_outline_rounded,
                            ),
                            SizedBox(height: 6.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: AppColors.sandText,
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    AppStrings.appEmployeeAccountCredsNote.tr(),
                                    style: TextStyles.customStyle(
                                      fontSize: 11,
                                      color: AppColors.sandText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                SizedBox(height: isDesktop ? 20 : 16.h),

                // Role Presets Section
                _buildSectionCard(
                  isDesktop: isDesktop,
                  title: AppStrings.rolePreset.tr(),
                  icon: Icons.tune_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.appEmployeeRolePresetEditDesc.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          color: AppColors.sandText,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 14 : 12.h),
                      Wrap(
                        spacing: isDesktop ? 10 : 8.w,
                        runSpacing: isDesktop ? 10 : 8.h,
                        children: [
                          _buildPresetChip(
                            AppPermissions.roleCashier,
                            AppStrings.roleCashierLabel.tr(),
                            Icons.point_of_sale_rounded,
                            isDesktop: isDesktop,
                          ),
                          _buildPresetChip(
                            AppPermissions.roleStorekeeper,
                            AppStrings.roleStorekeeperLabel.tr(),
                            Icons.inventory_2_outlined,
                            isDesktop: isDesktop,
                          ),
                          _buildPresetChip(
                            AppPermissions.roleAccountant,
                            AppStrings.roleAccountantLabel.tr(),
                            Icons.calculate_outlined,
                            isDesktop: isDesktop,
                          ),
                          _buildPresetChip(
                            AppPermissions.roleSupervisor,
                            AppStrings.roleSupervisorLabel.tr(),
                            Icons.admin_panel_settings_outlined,
                            isDesktop: isDesktop,
                          ),
                          _buildPresetChip(
                            AppPermissions.roleCustom,
                            AppStrings.roleCustomLabel.tr(),
                            Icons.tune_rounded,
                            isDesktop: isDesktop,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isDesktop ? 20 : 16.h),

                // Granular Permissions Section
                _buildSectionCard(
                  isDesktop: isDesktop,
                  title:
                      '${AppStrings.appEmployeeGrantedPermissions.tr()} (${_selectedPermissions.length})',
                  icon: Icons.security_rounded,
                  headerTrailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _selectAll,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 12 : 8.w,
                          ),
                        ),
                        child: Text(
                          AppStrings.selectAll.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _deselectAll,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 12 : 8.w,
                          ),
                        ),
                        child: Text(
                          AppStrings.deselectAll.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  child: Column(
                    children: AppPermissions.allGroups
                        .where((group) {
                          if (PermissionService.instance.isOwner) {
                            return true;
                          }
                          return group.items.any(
                            (item) =>
                                item.key !=
                                    AppPermissions.employeesManageAppUsers &&
                                PermissionService.instance.hasPermission(
                                  item.key,
                                ),
                          );
                        })
                        .map((group) {
                          final visibleItems = group.items.where((item) {
                            if (PermissionService.instance.isOwner) {
                              return true;
                            }
                            return item.key !=
                                    AppPermissions.employeesManageAppUsers &&
                                PermissionService.instance.hasPermission(
                                  item.key,
                                );
                          }).toList();
                          final groupItemsCount = visibleItems.length;
                          final activeInGroup = visibleItems
                              .where(
                                (item) =>
                                    _selectedPermissions.contains(item.key),
                              )
                              .length;

                          final isFull = activeInGroup == groupItemsCount && groupItemsCount > 0;
                          final isPartial = activeInGroup > 0 && activeInGroup < groupItemsCount;

                          return Container(
                            margin: EdgeInsets.only(bottom: isDesktop ? 12 : 10.h),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: isFull
                                    ? AppColors.primaryColor.withValues(
                                        alpha: 0.4,
                                      )
                                    : isPartial
                                        ? AppColors.stitchOrange.withValues(
                                            alpha: 0.45,
                                          )
                                        : AppColors.lightGreyColor.withValues(
                                            alpha: 0.7,
                                          ),
                                width: (isFull || isPartial) ? 1.5 : 1,
                              ),
                            ),
                            child: Theme(
                              data: Theme.of(
                                context,
                              ).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                leading: Container(
                                  padding: EdgeInsets.all(isDesktop ? 6 : 6.r),
                                  decoration: BoxDecoration(
                                    color: isFull
                                        ? AppColors.primaryColor.withValues(
                                            alpha: 0.12,
                                          )
                                        : isPartial
                                            ? AppColors.stitchOrange.withValues(
                                                alpha: 0.12,
                                              )
                                            : AppColors.lightGreyColor.withValues(
                                                alpha: 0.3,
                                              ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isFull
                                        ? Icons.check_circle_rounded
                                        : isPartial
                                            ? Icons.remove_circle_rounded
                                            : Icons.circle_outlined,
                                    color: isFull
                                        ? AppColors.primaryColor
                                        : isPartial
                                            ? AppColors.stitchOrange
                                            : AppColors.disabledColor,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  group.titleKey.tr(),
                                  style: TextStyles.customStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                ),
                                subtitle: Text(
                                  '$activeInGroup / $groupItemsCount ${AppStrings.permissionsCount.tr()}',
                                  style: TextStyles.customStyle(
                                    fontSize: 11,
                                    color: isFull
                                        ? AppColors.primaryColor
                                        : isPartial
                                            ? AppColors.stitchOrange
                                            : AppColors.sandText,
                                    fontWeight: (isFull || isPartial)
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                children: visibleItems.map((item) {
                                  final isChecked = _selectedPermissions
                                      .contains(item.key);
                                  return CheckboxListTile(
                                    value: isChecked,
                                    onChanged: (_) =>
                                        _togglePermission(item.key),
                                    title: Text(
                                      item.labelKey.tr(),
                                      style: TextStyles.customStyle(
                                        fontSize: 13,
                                        fontWeight: isChecked
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isChecked
                                            ? AppColors.black
                                            : AppColors.blackLight,
                                      ),
                                    ),
                                    activeColor: AppColors.primaryColor,
                                    dense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isDesktop ? 20 : 16.w,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
                SizedBox(height: isDesktop ? 28 : 24.h),

                // Actions
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 500 : double.infinity,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isDesktop ? 16 : 14.h,
                              ),
                              side: BorderSide(
                                color: AppColors.lightGreyColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                            child: Text(
                              AppStrings.cancel.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 14,
                                color: AppColors.sandText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isDesktop ? 16 : 14.w),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.symmetric(
                                vertical: isDesktop ? 16 : 14.h,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: isDesktop ? 22 : 22.h,
                                    width: isDesktop ? 22 : 22.h,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.save_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          AppStrings.appEmployeeUpdatePermissions.tr(),
                                          style: TextStyles.customStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isDesktop ? 36 : 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeProfileCard(bool isDesktop) {
    final isActive = widget.employee.isActive;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.08),
            AppColors.primaryColor.withValues(alpha: 0.02),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 56 : 52.r,
            height: isDesktop ? 56 : 52.r,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.employee.name.isNotEmpty
                    ? widget.employee.name[0].toUpperCase()
                    : '?',
                style: TextStyles.customStyle(
                  fontSize: isDesktop ? 24 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: isDesktop ? 16 : 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.employee.name,
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 17 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 10 : 8.w,
                        vertical: isDesktop ? 4 : 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primaryColor.withValues(alpha: 0.12)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        isActive
                            ? AppStrings.activeAccount.tr()
                            : AppStrings.disabledAccount.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? AppColors.primaryColor
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 4 : 3.h),
                Text(
                  widget.employee.email,
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 13 : 12,
                    color: AppColors.sandText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? headerTrailing,
    bool isDesktop = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.lightGreyColor.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerTrailing != null)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 6 : 6.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(icon, size: 18, color: AppColors.primaryColor),
                    ),
                    SizedBox(width: isDesktop ? 10 : 10.w),
                    Text(
                      title,
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 16 : 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
                headerTrailing,
              ],
            )
          else
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isDesktop ? 6 : 6.r),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primaryColor),
                ),
                SizedBox(width: isDesktop ? 10 : 10.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyles.customStyle(
                      fontSize: isDesktop ? 16 : 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          Divider(
            height: isDesktop ? 22 : 22.h,
            color: AppColors.lightGreyColor.withValues(alpha: 0.7),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildPresetChip(
    String presetKey,
    String label,
    IconData icon, {
    bool isDesktop = false,
  }) {
    final isSelected = _selectedPreset == presetKey;
    return ChoiceChip(
      showCheckmark: false,
      padding: isDesktop
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
          : null,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : AppColors.primaryColor,
      ),
      label: Text(
        label,
        style: TextStyles.customStyle(
          fontSize: isDesktop ? 13 : 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.black,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryColor,
      backgroundColor: AppColors.surface,
      onSelected: (_) => _applyPreset(presetKey),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: BorderSide(
          color: isSelected ? AppColors.primaryColor : AppColors.lightGreyColor,
        ),
      ),
    );
  }
}
