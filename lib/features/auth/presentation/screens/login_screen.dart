// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/services/whatsapp_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/offline_sync/presentation/widgets/offline_banner.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/text_fields/custom_text_form_field.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 24.sp),
            SizedBox(width: 12.w),
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
        margin: EdgeInsets.all(16.w),
        elevation: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveLayout.isDesktop(context);
    return Scaffold(
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
                                    color: Colors.black.withValues(alpha: 0.04),
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
                            SizedBox(height: isDesktop ? 4 : 4.h),
                            Text(
                              AppStrings.loginSubtitle.tr(),
                              style: TextStyles.customStyle(
                                color: AppColors.disabledColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: isDesktop ? 40 : 40.h),

                            // Login Card
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isDesktop ? 32 : 32.w),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.scafoldBackGround ==
                                        const Color(0xFFF8F8F8)
                                    ? Colors.white
                                    : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.welcomeBack.tr(),
                                      style: TextStyles.customStyle(
                                        color: AppColors.textColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: isDesktop ? 24 : 24.h),

                                    // Email Field
                                    CustomTextFormField(
                                      labelText: AppStrings.emailAddress.tr(),
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
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
                                    SizedBox(height: isDesktop ? 32 : 32.h),

                                    // Login Button
                                    BlocConsumer<AuthCubit, AuthState>(
                                      listener: (context, state) {
                                        if (state is AuthSuccess) {
                                          sl<NavigatorService>()
                                              .navigatorKey
                                              .currentState
                                              ?.pushReplacementNamed(
                                                AppRoutes.mainLayout,
                                              );
                                        } else if (state is AuthFailure) {
                                          _showError(state.message);
                                        }
                                      },
                                      builder: (context, state) {
                                        if (state is AuthLoading) {
                                          return Center(
                                            child: CircularProgressIndicator(
                                              color: AppColors.primaryColor,
                                            ),
                                          );
                                        }
                                        return GestureDetector(
                                          onTap: () {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              final email = _emailController
                                                  .text
                                                  .trim();
                                              final password =
                                                  _passwordController.text;
                                              context.read<AuthCubit>().login(
                                                email,
                                                password,
                                              );
                                            }
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            height: isDesktop ? 56 : 56.h,
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primaryColor
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  AppStrings.login.tr(),
                                                  style: TextStyles.customStyle(
                                                    color: Colors.white,
                                                    fontSize: isDesktop
                                                        ? 16
                                                        : 16.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: isDesktop ? 8 : 8.w,
                                                ),
                                                Icon(
                                                  Icons.arrow_forward,
                                                  color: Colors.white,
                                                  size: isDesktop ? 20 : 20.sp,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: 24.h),

                                    // Contact Manager text
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.only(
                                        top: isDesktop ? 024 : 24.h,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: AppColors.disabledColor
                                                .withValues(alpha: 0.1),
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            AppStrings.noAccount.tr(),
                                            style: TextStyles.customStyle(
                                              color: AppColors.disabledColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () async {
                                              final success =
                                                  await WhatsAppService.sendMessage(
                                                    phoneNumber: AppStrings
                                                        .supportPhoneNumber,
                                                    message:
                                                        "مرحبا اريد الحصول علي حساب في برنامج تحصيل",
                                                  );
                                              if (mounted && !success) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      AppStrings
                                                          .whatsappNotInstalled
                                                          .tr(),
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Text(
                                              AppStrings.contactManager.tr(),
                                              style:
                                                  TextStyles.customStyle(
                                                    color:
                                                        AppColors.primaryColor,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ).copyWith(
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isDesktop ? 32 : 32.h),
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
    );
  }
}
