// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/create_account/domain/usecases/create_account_usecases.dart';
import 'package:tahsel/features/create_account/presentation/cubit/create_account/create_account_cubit.dart';
import 'package:tahsel/features/create_account/presentation/cubit/create_account/create_account_state.dart';
import 'package:tahsel/features/offline_sync/presentation/widgets/offline_banner.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/text_fields/custom_text_form_field.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _projectNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final int _days = 5;
  String _userType = 'cafe';
  String _platformType = 'mobile';
  bool _isVip = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _projectNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// دالة للتحقق من منصة الجهاز الحالي ومقارنتها بالمنصة المختارة للحساب الجديد
  Future<bool> _validatePlatformConflict() async {
    // تحديد طبيعة الجهاز الحالي (موبايل أم ديسكتوب/ويندوز)
    final currentPlatform = Theme.of(context).platform;
    bool isCurrentlyMobile =
        currentPlatform == TargetPlatform.iOS ||
        currentPlatform == TargetPlatform.android;
    bool isCurrentlyDesktop =
        currentPlatform == TargetPlatform.windows ||
        currentPlatform == TargetPlatform.macOS ||
        currentPlatform == TargetPlatform.linux;

    // إذا تم اختيار 'both' (كلاهما) فلا يوجد أي تعارض نهائياً
    if (_platformType == 'both') return true;

    bool hasConflict = false;
    String currentDeviceName = '';
    String chosenPlatformName = '';

    if (isCurrentlyMobile && _platformType == 'desktop') {
      hasConflict = true;
      currentDeviceName = 'platform_type_mobile'.tr();
      chosenPlatformName = 'platform_type_desktop'.tr();
    } else if (isCurrentlyDesktop && _platformType == 'mobile') {
      hasConflict = true;
      currentDeviceName = 'platform_type_desktop'.tr();
      chosenPlatformName = 'platform_type_mobile'.tr();
    }

    if (hasConflict) {
      // إظهار الدايلوج التحذيري للمستخدم وتلقي قراره (تأكيد أو إلغاء)
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          backgroundColor: AppColors.scafoldBackGround,
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.orange,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'warning'
                      .tr(), // تأكد من وجود مفتاح الترجمة هذا أو استبدله بنص ثابت
                  style: TextStyles.customStyle(
                    color: AppColors.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            '${"platform_conflict_msg".tr()} ($currentDeviceName) ${"platform_conflict_chosen".tr()} ($chosenPlatformName). ${"platform_conflict_confirm".tr()}',
            style: TextStyles.customStyle(
              color: AppColors.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                AppStrings.cancel.tr(),
                style: TextStyles.customStyle(
                  color: AppColors.disabledColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppStrings.confirm.tr(),
                style: TextStyles.customStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      return proceed ?? false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message.tr(),
                style: TextStyles.customStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 4,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message.tr(),
                style: TextStyles.customStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocListener<CreateAccountCubit, CreateAccountState>(
      listener: (context, state) async {
        if (state is CreateAccountSuccess) {
          _showSuccess(AppStrings.userCreatedSuccessfully.tr());

          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
        if (state is CreateAccountError) {
          _showError(AppStrings.failedToCreateUser.tr());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 800 : double.infinity,
            ),
            child: SafeArea(
              child: OfflineBanner(
                child: Stack(
                  children: [
                    // Background Decoration
                    Positioned(
                      top: -100,
                      left: -100,
                      child: Container(
                        width: 384,
                        height: 384,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 24 : 24.w,
                            vertical: isDesktop ? 48 : 48.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Branding Area
                              Container(
                                width: isDesktop ? 64 : 64.w,
                                height: isDesktop ? 64 : 64.w,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  Assets.imagesAppLogo,
                                  width: isDesktop ? 35 : 32.w,
                                  height: isDesktop ? 35 : 32.w,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                AppStrings.financialEngineer.tr(),
                                style: TextStyles.customStyle(
                                  color: AppColors.textColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              SizedBox(height: isDesktop ? 30 : 20.h),

                              // Main Card Context
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(isDesktop ? 32 : 12.w),
                                decoration: BoxDecoration(
                                  color: AppColors.scafoldBackGround,
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'create_new_account'.tr(),
                                        style: TextStyles.customStyle(
                                          color: AppColors.textColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: isDesktop ? 24 : 24.h),

                                      // Project Name Field
                                      CustomTextFormField(
                                        labelText: AppStrings.projectName.tr(),
                                        controller: _projectNameController,
                                        keyboardType: TextInputType.text,
                                        hintText: 'اسم مشروعك',
                                        prefixIcon: Icons.storefront_outlined,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return AppStrings
                                                .validationFieldRequired
                                                .tr();
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: isDesktop ? 24 : 24.h),
                                      // Full Name Field
                                      CustomTextFormField(
                                        labelText: AppStrings.fullName.tr(),
                                        controller: _nameController,
                                        keyboardType: TextInputType.name,
                                        hintText: 'عبدالله العوضي',
                                        prefixIcon: Icons.person_outline,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return AppStrings
                                                .validationFieldRequired
                                                .tr();
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: isDesktop ? 24 : 24.h),

                                      // Email Field
                                      CustomTextFormField(
                                        labelText: AppStrings.emailAddress.tr(),
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        hintText: 'name@gmail.com',
                                        prefixIcon: Icons.email_outlined,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return AppStrings
                                                .validationEmailRequired
                                                .tr();
                                          }
                                          if (!value.isValidEmail()) {
                                            return AppStrings
                                                .validationEmailInvalid
                                                .tr();
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: isDesktop ? 24 : 24.h),

                                      // Phone Field
                                      CustomTextFormField(
                                        labelText: AppStrings.customerPhone
                                            .tr(),
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        hintText: '01xxxxxxxxx',
                                        prefixIcon: Icons.phone_outlined,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return AppStrings
                                                .validationFieldRequired
                                                .tr();
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: isDesktop ? 24 : 24.h),

                                      // Password Field
                                      CustomTextFormField(
                                        labelText: AppStrings.password.tr(),
                                        controller: _passwordController,
                                        isPassword: true,
                                        hintText: '••••••••',
                                        prefixIcon: Icons.lock_outline,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return AppStrings
                                                .validationPasswordRequired
                                                .tr();
                                          }
                                          if (value.length < 6) {
                                            return AppStrings
                                                .validationPasswordLength
                                                .tr();
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: isDesktop ? 24 : 24.h),

                                      // User Type Dropdown
                                      DropdownButtonFormField<String>(
                                        initialValue: _userType,
                                        style: TextStyles.customStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textColor,
                                        ),
                                        dropdownColor:
                                            AppColors.scafoldBackGround,
                                        decoration: InputDecoration(
                                          labelText: AppStrings.userTypeTitle
                                              .tr(),
                                          labelStyle: TextStyles.customStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textColor,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.badge_outlined,
                                            color: AppColors.primaryColor,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                        ),
                                        items: [
                                          DropdownMenuItem(
                                            value: 'cafe',
                                            child: Text(
                                              AppStrings.userTypeCafe.tr(),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'shop',
                                            child: Text(
                                              AppStrings.userTypeShop.tr(),
                                            ),
                                          ),
                                        ],
                                        onChanged: (v) => setState(
                                          () => _userType = v ?? 'cafe',
                                        ),
                                      ),
                                      SizedBox(height: isDesktop ? 24 : 24.h),

                                      // Platform Type Dropdown
                                      DropdownButtonFormField<String>(
                                        initialValue: _platformType,
                                        style: TextStyles.customStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textColor,
                                        ),
                                        dropdownColor:
                                            AppColors.scafoldBackGround,
                                        decoration: InputDecoration(
                                          labelText: AppStrings.platformType
                                              .tr(),
                                          labelStyle: TextStyles.customStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textColor,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.devices_outlined,
                                            color: AppColors.primaryColor,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                        ),
                                        items: [
                                          DropdownMenuItem(
                                            value: 'mobile',
                                            child: Text(
                                              AppStrings.platformTypeMobile
                                                  .tr(),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'desktop',
                                            child: Text(
                                              AppStrings.platformTypeDesktop
                                                  .tr(),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'both',
                                            child: Text(
                                              AppStrings.platformTypeBoth.tr(),
                                            ),
                                          ),
                                        ],
                                        onChanged: (v) => setState(
                                          () => _platformType = v ?? 'mobile',
                                        ),
                                      ),
                                      SizedBox(height: isDesktop ? 24 : 24.h),

                                      // VIP Account Switch Tile
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isVip
                                              ? Colors.amber.withValues(alpha: 0.1)
                                              : AppColors.scafoldBackGround,
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(
                                            color: _isVip
                                                ? Colors.amber
                                                : AppColors.primaryColor.withValues(alpha: 0.3),
                                            width: _isVip ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.workspace_premium_rounded,
                                              color: _isVip ? Colors.amber : AppColors.sandText,
                                              size: 24,
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    AppStrings.vipAccount.tr(),
                                                    style: TextStyles.customStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.textColor,
                                                    ),
                                                  ),
                                                  Text(
                                                    _isVip ? 'مفعل (☑ Enabled)' : 'غير مفعل (☐ Disabled)',
                                                    style: TextStyles.customStyle(
                                                      fontSize: 11,
                                                      color: _isVip ? Colors.amber.shade800 : AppColors.sandText,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Switch(
                                              value: _isVip,
                                              activeThumbColor: Colors.amber,
                                              onChanged: (val) {
                                                setState(() {
                                                  _isVip = val;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: isDesktop ? 24 : 24.h),

                                      // Create Account / Submit Action Button
                                      _isLoading
                                          ? Center(
                                              child: CircularProgressIndicator(
                                                color: AppColors.primaryColor,
                                              ),
                                            )
                                          : GestureDetector(
                                              onTap: () async {
                                                // 1. التحقق من تعارض المنصة أولاً والانتظار حتى تأكيد المستخدم
                                                final bool isValidPlatform =
                                                    await _validatePlatformConflict();
                                                if (!isValidPlatform) {
                                                  return;
                                                }
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  var days = _days == 0
                                                      ? 5
                                                      : _days;

                                                  setState(
                                                    () => _isLoading = true,
                                                  );

                                                  await context
                                                      .read<
                                                        CreateAccountCubit
                                                      >()
                                                      .createUser(
                                                        CreateUserParams(
                                                          email:
                                                              _emailController
                                                                  .text
                                                                  .trim(),
                                                          password:
                                                              _passwordController
                                                                  .text,
                                                          fullName:
                                                              _nameController
                                                                  .text
                                                                  .trim(),
                                                          projectName:
                                                              _projectNameController
                                                                  .text
                                                                  .trim(),
                                                          phoneNumber:
                                                              _phoneController
                                                                  .text
                                                                  .trim()
                                                                  .isEmpty
                                                              ? null
                                                              : _phoneController
                                                                    .text
                                                                    .trim(),
                                                          subscriptionDays:
                                                              days,
                                                          userType: _userType,
                                                          platformType:
                                                              _platformType,
                                                          isVip: _isVip,
                                                        ),
                                                      );

                                                  setState(
                                                    () => _isLoading = false,
                                                  );
                                                }
                                              },
                                              child: Container(
                                                width: double.infinity,
                                                height: isDesktop ? 56 : 56.h,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.r,
                                                      ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors
                                                          .primaryColor
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      AppStrings.confirm.tr(),
                                                      style:
                                                          TextStyles.customStyle(
                                                            color: Colors.white,
                                                            fontSize: isDesktop
                                                                ? 16
                                                                : 16.sp,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                    SizedBox(
                                                      width: isDesktop
                                                          ? 8
                                                          : 8.w,
                                                    ),
                                                    Icon(
                                                      Icons.arrow_forward,
                                                      color: Colors.white,
                                                      size: isDesktop
                                                          ? 20
                                                          : 20.sp,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                      SizedBox(height: 24.h),

                                      // Back to Login link
                                      Center(
                                        child: GestureDetector(
                                          onTap: () => Navigator.pop(context),
                                          child: Text(
                                            AppStrings.cancel.tr(),
                                            style:
                                                TextStyles.customStyle(
                                                  color: AppColors.primaryColor,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ).copyWith(
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
          ),
        ),
      ),
    );
  }
}
