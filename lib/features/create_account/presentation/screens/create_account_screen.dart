// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/error/firebase_error_handler.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/currency/currency_service.dart';
import 'package:tahsel/core/services/currency/domain/entities/currency_entity.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/create_account/domain/usecases/create_account_usecases.dart';
import 'package:tahsel/features/create_account/presentation/cubit/create_account/create_account_cubit.dart';
import 'package:tahsel/features/create_account/presentation/cubit/create_account/create_account_state.dart';
import 'package:tahsel/features/offline_sync/presentation/widgets/offline_banner.dart';
import 'package:tahsel/features/settings/presentation/widgets/currency_selection_bottom_sheet.dart';
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
  CurrencyEntity _selectedCurrency = CurrencyEntity.defaultCurrency;
  bool _isVip = true;
  bool _showVipDetails = false;
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
          final errorMessage = FirebaseErrorHandler.getLocalizedMessage(
            state.message,
          );
          _showError(errorMessage);
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
                                      SizedBox(height: isDesktop ? 16 : 14.h),
                                      _buildDataAccuracyBanner(isDesktop),
                                      SizedBox(height: isDesktop ? 20 : 18.h),

                                      // Project Name Field
                                      CustomTextFormField(
                                        labelText: AppStrings.projectName.tr(),
                                        controller: _projectNameController,
                                        keyboardType: TextInputType.text,
                                        hintText: AppStrings.projectNameHint
                                            .tr(),
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
                                        hintText: AppStrings.fullNameHint.tr(),
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
                                      _buildEmailNotice(isDesktop),
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
                                            size: 20,
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
                                            size: 20,
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

                                      // Currency Selector (Opens Smart Currency Bottom Sheet)
                                      InkWell(
                                        onTap: () async {
                                          final selected =
                                              await CurrencySelectionBottomSheet.show(
                                                context,
                                                initialCurrency:
                                                    _selectedCurrency,
                                                onCurrencySelected: (c) {
                                                  setState(
                                                    () => _selectedCurrency = c,
                                                  );
                                                },
                                              );
                                          if (selected != null) {
                                            setState(
                                              () =>
                                                  _selectedCurrency = selected,
                                            );
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: AppStrings.currencyLabel
                                                .tr(),
                                            labelStyle: TextStyles.customStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textColor,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.payments_outlined,
                                              color: AppColors.primaryColor,
                                              size: 20,
                                            ),
                                            suffixIcon: Icon(
                                              Icons.arrow_drop_down_rounded,
                                              color: AppColors.primaryColor,
                                              size: 26,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              borderSide: BorderSide(
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              borderSide: BorderSide(
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              borderSide: BorderSide(
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _selectedCurrency.getName(
                                                    AppStrings.currentLang,
                                                  ),
                                                  style: TextStyles.customStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textColor,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: isDesktop
                                                      ? 6
                                                      : 6.w,
                                                  vertical: isDesktop ? 2 : 2.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryColor
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        6.r,
                                                      ),
                                                ),
                                                child: Text(
                                                  _selectedCurrency.getSymbol(
                                                    AppStrings.currentLang,
                                                  ),
                                                  style: TextStyles.customStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppColors.primaryColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: isDesktop ? 24 : 24.h),

                                      // VIP Account Section
                                      _buildVipAccountSection(isDesktop),
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

                                                  await CurrencyService.instance
                                                      .updateCurrency(
                                                        _selectedCurrency,
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
                                                          currency:
                                                              _selectedCurrency
                                                                  .toMap(),
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
                                                                : 16,
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
                                                      size: isDesktop ? 20 : 20,
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

  /// بطاقة تنبيه للتأكد من صحة ودقة البيانات المدخلة
  Widget _buildDataAccuracyBanner(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 16 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 8 : 6.w),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: AppColors.primaryColor,
              size: isDesktop ? 20 : 18,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.createAccountAccuracyNoticeTitle.tr(),
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 15 : 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppStrings.createAccountAccuracyNoticeDesc.tr(),
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 13 : 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subTitleColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// توضيح خاص ومميز بحقل البريد الإلكتروني
  Widget _buildEmailNotice(bool isDesktop) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 12 : 10.w,
        vertical: isDesktop ? 8 : 8.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.stitchSurfaceHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.primaryColor,
            size: isDesktop ? 16 : 15,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              AppStrings.createAccountEmailNoticeDesc.tr(),
              style: TextStyles.customStyle(
                fontSize: isDesktop ? 11 : 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.subTitleColor,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// قسم وبطاقة الحساب المميز VIP التفاعلية
  Widget _buildVipAccountSection(bool isDesktop) {
    const Color goldStart = AppColors.vipGoldStart;
    const Color goldEnd = AppColors.vipGoldEnd;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _isVip
            ? goldStart.withValues(alpha: 0.08)
            : AppColors.stitchSurfaceHigh.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _isVip
              ? goldStart
              : AppColors.primaryColor.withValues(alpha: 0.2),
          width: _isVip ? 1.5 : 1,
        ),
        boxShadow: _isVip
            ? [
                BoxShadow(
                  color: goldStart.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 18 : 14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // شريط العنوان مع سويتش التفعيل وشارة VIP
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isDesktop ? 8 : 8.w),
                  decoration: BoxDecoration(
                    gradient: _isVip
                        ? LinearGradient(
                            colors: [Colors.amber.shade900, goldEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: _isVip
                        ? null
                        : AppColors.disabledColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: _isVip ? Colors.white : AppColors.sandText,
                    size: isDesktop ? 22 : 20,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              AppStrings.vipAccount.tr(),
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 15 : 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: _isVip
                                  ? goldStart.withValues(alpha: 0.2)
                                  : AppColors.disabledColor.withValues(
                                      alpha: 0.1,
                                    ),
                              borderRadius: BorderRadius.circular(4.r),
                              border: Border.all(
                                color: _isVip
                                    ? goldStart
                                    : AppColors.disabledColor,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'VIP ✨',
                              style: TextStyles.customStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _isVip
                                    ? Colors.amber.shade500
                                    : AppColors.sandText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _isVip
                            ? AppStrings.vipStatusEnabled.tr()
                            : AppStrings.vipStatusDisabled.tr(),
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 11 : 10.5,
                          fontWeight: FontWeight.w600,
                          color: _isVip
                              ? Colors.amber.shade900
                              : AppColors.sandText,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isVip,
                  activeThumbColor: Colors.amber.shade900,
                  activeTrackColor: Colors.amber.shade900.withValues(
                    alpha: 0.4,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _isVip = val;
                    });
                  },
                ),
              ],
            ),

            SizedBox(height: 10.h),
            // نبذة توضيحية عن الحساب المميز
            Text(
              AppStrings.vipAccountDesc.tr(),
              style: TextStyles.customStyle(
                fontSize: isDesktop ? 12 : 11,
                color: AppColors.subTitleColor,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),

            SizedBox(height: 12.h),
            Divider(
              color: _isVip
                  ? goldStart.withValues(alpha: 0.2)
                  : AppColors.dividerColor,
              height: 1,
            ),
            SizedBox(height: 10.h),

            // زر طي وتوسيع تفاصيل مميزات VIP
            InkWell(
              onTap: () {
                setState(() {
                  _showVipDetails = !_showVipDetails;
                });
              },
              borderRadius: BorderRadius.circular(8.r),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 2.w),
                child: Row(
                  children: [
                    Icon(
                      _showVipDetails
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _isVip
                          ? Colors.amber.shade800
                          : AppColors.primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _showVipDetails
                          ? AppStrings.vipHideDetails.tr()
                          : AppStrings.vipShowDetails.tr(),
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 12 : 11,
                        fontWeight: FontWeight.bold,
                        color: _isVip
                            ? Colors.amber.shade500
                            : AppColors.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: (_isVip ? goldStart : AppColors.primaryColor)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        AppStrings.vipMajorFeaturesCount.tr(),
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 10 : 9.5,
                          fontWeight: FontWeight.w600,
                          color: _isVip
                              ? Colors.amber.shade900
                              : AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_showVipDetails) ...[
              SizedBox(height: 10.h),
              _buildVipFeatureItem(
                icon: Icons.inventory_2_outlined,
                title: AppStrings.vipFeatureInventoryTitle.tr(),
                description: AppStrings.vipFeatureInventoryDesc.tr(),
                color: AppColors.inventoryCategoryBrown,
                isDesktop: isDesktop,
              ),
              _buildVipFeatureItem(
                icon: Icons.account_balance_wallet_outlined,
                title: AppStrings.vipFeatureVaultTitle.tr(),
                description: AppStrings.vipFeatureVaultDesc.tr(),
                color: AppColors.vaultEmeraldStart,
                isDesktop: isDesktop,
              ),
              _buildVipFeatureItem(
                icon: Icons.badge_outlined,
                title: AppStrings.vipFeatureEmployeesTitle.tr(),
                description: AppStrings.vipFeatureEmployeesDesc.tr(),
                color: AppColors.inventoryPurchasePurple,
                isDesktop: isDesktop,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVipFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isDesktop,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      padding: EdgeInsets.all(isDesktop ? 10 : 8.w),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 6 : 6.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: isDesktop ? 16 : 15),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 12.5 : 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  description,
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 10.5 : 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subTitleColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
