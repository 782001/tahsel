import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/text_fields/custom_text_form_field.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:url_launcher/url_launcher.dart';
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
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        body: Stack(
          children: [
            // Background Decoration
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 384,
                height: 384,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 48.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Branding Area
                      Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.account_balance,
                          color: Colors.white,
                          size: 32.sp,
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
                      SizedBox(height: 4.h),
                      Text(
                        AppStrings.loginSubtitle.tr(),
                        style: TextStyles.customStyle(
                          color: AppColors.disabledColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 40.h),

                      // Login Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(32.w),
                        decoration: BoxDecoration(
                          color:
                              AppColors.scafoldBackGround ==
                                  const Color(0xFFF8F8F8)
                              ? Colors.white
                              : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
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
                              SizedBox(height: 24.h),

                              // Email Field
                              CustomTextFormField(
                                labelText: AppStrings.emailAddress.tr(),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                            hintText: 'name@company.com',
                                prefixIcon: Icons.email_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppStrings.validationEmailRequired.tr();
                                  }
                                  if (!value.isValidEmail()) {
                                    return AppStrings.validationEmailInvalid.tr();
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 24.h),

                              // Password Field
                              CustomTextFormField(
                                labelText: AppStrings.password.tr(),
                                controller: _passwordController,
                                isPassword: true,
                                hintText: '••••••••',
                                prefixIcon: Icons.lock_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppStrings.validationPasswordRequired.tr();
                                  }
                                  if (value.length < 6) {
                                    return AppStrings.validationPasswordLength.tr();
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 32.h),

                              // Login Button
                              BlocConsumer<AuthCubit, AuthState>(
                                listener: (context, state) {
                                  if (state is AuthSuccess) {
                                    nav().navigatorKey.currentState?.pushReplacementNamed(
                                      AppRoutes.mainLayout,
                                    );
                                  } else if (state is AuthFailure) {
                                    _showError(state.message);
                                  }
                                },
                                builder: (context, state) {
                                  if (state is AuthLoading) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  return GestureDetector(
                                    onTap: () {
                                      if (_formKey.currentState!.validate()) {
                                        final email = _emailController.text.trim();
                                        final password = _passwordController.text;
                                        context.read<AuthCubit>().login(email, password);
                                      }
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: 56.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        borderRadius: BorderRadius.circular(12.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryColor.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            AppStrings.login.tr(),
                                            style: TextStyles.customStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                            size: 20.sp,
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
                                padding: EdgeInsets.only(top: 24.h),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: AppColors.disabledColor.withOpacity(
                                        0.1,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                        final Uri url = Uri.parse(
                                          'https://api.whatsapp.com/send?phone=+201028341201',
                                        );
                                        if (!await launchUrl(url)) {
                                          if (context.mounted) {
                                            _showError('Could not open WhatsApp');
                                          }
                                        }
                                      },
                                      child: Text(
                                        AppStrings.contactManager.tr(),
                                        style:
                                            TextStyles.customStyle(
                                              color: AppColors.primaryColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ).copyWith(
                                              decoration: TextDecoration.underline,
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
                      SizedBox(height: 32.h),

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
