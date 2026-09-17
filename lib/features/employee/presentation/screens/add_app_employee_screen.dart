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
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/custom_app_bar/custom_app_bar.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

import '../cubit/team_management_cubit.dart';

class AddAppEmployeeScreen extends StatefulWidget {
  final TeamManagementCubit cubit;

  const AddAppEmployeeScreen({super.key, required this.cubit});

  static Future<void> push(BuildContext context, TeamManagementCubit cubit) {
    return Navigator.pushNamed(
      context,
      AppRoutes.addAppEmployee,
      arguments: cubit,
    );
  }

  @override
  State<AddAppEmployeeScreen> createState() => _AddAppEmployeeScreenState();
}

class _AddAppEmployeeScreenState extends State<AddAppEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();

  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  bool _obscurePassword = true;
  String _selectedPreset = AppPermissions.roleCashier;
  late final Set<String> _selectedPermissions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPermissions = Set.from(
      AppPermissions.permissionsForPreset(_selectedPreset),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
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
        final dependents = AppPermissions.getDependents(key);
        final removedDependents = dependents
            .where((d) => _selectedPermissions.contains(d))
            .toList();
        if (removedDependents.isNotEmpty) {
          _selectedPermissions.removeAll(dependents);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showDependencyToast(
              '${AppStrings.permAutoDisabledDependents.tr()}: ${removedDependents.map((k) => AppPermissions.getPermissionLabel(k)).join('، ')}',
              isWarning: true,
            );
          });
        }
      } else {
        _selectedPermissions.add(key);
        final prerequisites = AppPermissions.getPrerequisites(key);
        final addedPrerequisites = prerequisites
            .where((p) => !_selectedPermissions.contains(p))
            .toList();
        if (addedPrerequisites.isNotEmpty) {
          _selectedPermissions.addAll(prerequisites);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showDependencyToast(
              '${AppStrings.permAutoEnabledPrerequisites.tr()}: ${addedPrerequisites.map((k) => AppPermissions.getPermissionLabel(k)).join('، ')}',
            );
          });
        }
      }
      _selectedPreset = AppPermissions.roleCustom;
    });
  }

  void _showDependencyToast(String message, {bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isWarning ? Icons.info_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyles.customStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isWarning
            ? Colors.orange.shade800
            : AppColors.primaryColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
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

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showValidationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        backgroundColor: AppColors.error,
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                message,
                style: TextStyles.customStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: label,
          style: TextStyles.customStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
          children: [
            if (isRequired)
              TextSpan(
                text: ' *',
                style: TextStyles.customStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _autoValidateMode = AutovalidateMode.onUserInteraction;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. Mandatory Name Validation
    if (name.isEmpty) {
      _scrollToTop();
      _showValidationError(AppStrings.appEmployeeNameRequired.tr());
      return;
    }

    // 2. Mandatory Email Validation & Format
    if (email.isEmpty) {
      _scrollToTop();
      _showValidationError(AppStrings.appEmployeeEmailRequired.tr());
      return;
    }
    if (!email.isValidEmail()) {
      _scrollToTop();
      _showValidationError(AppStrings.appEmployeeEmailFormatInvalid.tr());
      return;
    }

    // 3. Mandatory Temporary Password Validation & Minimum Length
    if (password.isEmpty) {
      _scrollToTop();
      _showValidationError(AppStrings.appEmployeePasswordRequired.tr());
      return;
    }
    if (password.length < 6) {
      _scrollToTop();
      _showValidationError(AppStrings.appEmployeePasswordMin6Chars.tr());
      return;
    }

    // Validate form fields for visual inline feedback
    if (!_formKey.currentState!.validate()) {
      _scrollToTop();
      return;
    }

    // 4. Validate permissions selection
    if (_selectedPermissions.isEmpty) {
      _showValidationError(
        AppStrings.appEmployeeSelectAtLeastOnePermission.tr(),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.cubit.addEmployee(
      name: name,
      email: email.toLowerCase(),
      password: password,
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
          centerTitle: AppStrings.addAppEmployee.tr(),
          leadingIcon: const Icon(Icons.arrow_back_ios_new_rounded),
          onLeadingTap: () => Navigator.pop(context),
          actions: [
            Padding(
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
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 860 : double.infinity,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: _autoValidateMode,
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 16.w,
                  vertical: isDesktop ? 24 : 16.h,
                ),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Hero Header Card
                  _buildHeroHeader(isDesktop),
                  SizedBox(height: isDesktop ? 20 : 16.h),

                  // Basic Info Section
                  _buildSectionCard(
                    isDesktop: isDesktop,
                    title: AppStrings.appEmployeeBasicInfo.tr(),
                    icon: Icons.person_outline_rounded,
                    child: isDesktop
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel(
                                          AppStrings.appEmployeeNameField.tr(),
                                        ),
                                        QuickAddTextField(
                                          hint: AppStrings.appEmployeeNameHint
                                              .tr(),
                                          controller: _nameController,
                                          icon: Icons.badge_outlined,
                                          textInputAction: TextInputAction.next,
                                          validator: (val) {
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return AppStrings
                                                  .appEmployeeNameRequired
                                                  .tr();
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel(
                                          AppStrings.employeeEmail.tr(),
                                        ),
                                        QuickAddTextField(
                                          hint: 'employee@example.com',
                                          controller: _emailController,
                                          icon: Icons.email_outlined,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          validator: (val) {
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return AppStrings
                                                  .appEmployeeEmailRequired
                                                  .tr();
                                            }
                                            if (!val.trim().isValidEmail()) {
                                              return AppStrings
                                                  .appEmployeeEmailFormatInvalid
                                                  .tr();
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel(
                                          AppStrings.temporaryPassword.tr(),
                                        ),
                                        QuickAddTextField(
                                          hint: AppStrings
                                              .appEmployeePasswordMinLengthHint
                                              .tr(),
                                          controller: _passwordController,
                                          icon: Icons.lock_outline_rounded,
                                          obscureText: _obscurePassword,
                                          suffixIcon: _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          onSuffixIconPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                          validator: (val) {
                                            if (val == null ||
                                                val.trim().isEmpty) {
                                              return AppStrings
                                                  .appEmployeePasswordRequired
                                                  .tr();
                                            }
                                            if (val.trim().length < 6) {
                                              return AppStrings
                                                  .appEmployeePasswordMin6Chars
                                                  .tr();
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Spacer(),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(
                                AppStrings.appEmployeeNameField.tr(),
                              ),
                              QuickAddTextField(
                                hint: AppStrings.appEmployeeNameHint.tr(),
                                controller: _nameController,
                                icon: Icons.badge_outlined,
                                textInputAction: TextInputAction.next,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return AppStrings.appEmployeeNameRequired
                                        .tr();
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 14.h),
                              _buildFieldLabel(AppStrings.employeeEmail.tr()),
                              QuickAddTextField(
                                hint: 'employee@example.com',
                                controller: _emailController,
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return AppStrings.appEmployeeEmailRequired
                                        .tr();
                                  }
                                  if (!val.trim().isValidEmail()) {
                                    return AppStrings
                                        .appEmployeeEmailFormatInvalid
                                        .tr();
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 14.h),
                              _buildFieldLabel(
                                AppStrings.temporaryPassword.tr(),
                              ),
                              QuickAddTextField(
                                hint: AppStrings
                                    .appEmployeePasswordMinLengthHint
                                    .tr(),
                                controller: _passwordController,
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                suffixIcon: _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                onSuffixIconPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return AppStrings
                                        .appEmployeePasswordRequired
                                        .tr();
                                  }
                                  if (val.trim().length < 6) {
                                    return AppStrings
                                        .appEmployeePasswordMin6Chars
                                        .tr();
                                  }
                                  return null;
                                },
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
                          AppStrings.appEmployeeRolePresetDesc.tr(),
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

                            final isFull =
                                activeInGroup == groupItemsCount &&
                                groupItemsCount > 0;
                            final isPartial =
                                activeInGroup > 0 &&
                                activeInGroup < groupItemsCount;

                            return Container(
                              margin: EdgeInsets.only(
                                bottom: isDesktop ? 12 : 10.h,
                              ),
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
                                    padding: EdgeInsets.all(
                                      isDesktop ? 6 : 6.r,
                                    ),
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
                                      subtitle:
                                          AppPermissions.hasPrerequisites(
                                            item.key,
                                          )
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.link_rounded,
                                                    size: 13,
                                                    color: AppColors
                                                        .primaryColor
                                                        .withValues(
                                                          alpha: 0.75,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '${AppStrings.permRequiresPrefix.tr()}: ${AppPermissions.getPrerequisiteLabels(item.key)}',
                                                      style:
                                                          TextStyles.customStyle(
                                                            fontSize: 9,
                                                            color: AppColors
                                                                .sandText,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : null,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.person_add_alt_1_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            AppStrings
                                                .appEmployeeSaveAndActivateAccount
                                                .tr(),
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
      ),
    );
  }

  Widget _buildHeroHeader(bool isDesktop) {
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
            padding: EdgeInsets.all(isDesktop ? 12 : 12.r),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group_add_rounded,
              color: AppColors.primaryColor,
              size: 26,
            ),
          ),
          SizedBox(width: isDesktop ? 16 : 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.appEmployeeAddHeroTitle.tr(),
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 16 : 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                SizedBox(height: isDesktop ? 4 : 3.h),
                Text(
                  AppStrings.appEmployeeAddHeroDesc.tr(),
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 13 : 12,
                    color: AppColors.sandText,
                    height: 1.3,
                  ),
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
                      child: Icon(
                        icon,
                        size: 18,
                        color: AppColors.primaryColor,
                      ),
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
