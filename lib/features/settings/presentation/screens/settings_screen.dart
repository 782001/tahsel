import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/storage/secure_storage_helper.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/settings/presentation/widgets/appearance_card.dart';
import 'package:tahsel/features/settings/presentation/widgets/language_option.dart';
import 'package:tahsel/features/settings/presentation/widgets/logout_button.dart';
import 'package:tahsel/features/settings/presentation/widgets/section_header.dart';
import 'package:tahsel/features/settings/presentation/widgets/subscription_info_widget.dart';
import 'package:tahsel/features/standard_features/localization/presentation/cubit/locale_cubit.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_cubit.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_state.dart';
import 'package:tahsel/routes/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userEmail = '';
  @override
  void initState() {
    sl<SecureStorageHelper>().getData(key: 'email').then((value) {
      setState(() {
        userEmail = value!;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) {
        final currentLang = context.read<LocaleCubit>().currentLangCode;
        final isArabic = currentLang == AppStrings.arabicCode;

        return Scaffold(
          backgroundColor: AppColors.scafoldBackGround,
          body: Stack(
            children: [
              // Background Decoration
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 600 : double.infinity,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 24 : 24.w,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: isDesktop ? 20 : 20.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.settings.tr(),
                                  style: TextStyles.customStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isDesktop ? 32 : 32.h),

                            // Appearance Section
                            SectionHeader(title: AppStrings.appearance.tr()),
                            BlocBuilder<ThemeCubit, ThemeState>(
                              builder: (context, themeState) {
                                final isDark =
                                    themeState.themeMode == ThemeMode.dark;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: AppearanceCard(
                                        title: AppStrings.lightMode.tr(),
                                        icon: Icons.light_mode_rounded,
                                        isSelected: !isDark,
                                        onTap: () {
                                          setState(() {});
                                          context
                                              .read<ThemeCubit>()
                                              .toLightMode();
                                        },
                                      ),
                                    ),
                                    SizedBox(width: isDesktop ? 16 : 16.w),
                                    Expanded(
                                      child: AppearanceCard(
                                        title: AppStrings.darkMode.tr(),
                                        icon: Icons.dark_mode_rounded,
                                        isSelected: isDark,
                                        onTap: () {
                                          context
                                              .read<ThemeCubit>()
                                              .toDarkMode();
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: isDesktop ? 32 : 32.h),

                            // Language Section
                            SectionHeader(
                              title: AppStrings.changeLanguage.tr(),
                            ),
                            Text(
                              AppStrings.changeLanguageDesc.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: AppColors.sandText,
                              ),
                            ),
                            SizedBox(height: isDesktop ? 24 : 24.h),

                            LanguageOption(
                              title: AppStrings.arabic.tr(),
                              subtitle: AppStrings.arabicDesc.tr(),
                              isSelected: isArabic,
                              onTap: () {
                                if (!isArabic) {
                                  context.read<LocaleCubit>().toArabic();
                                }
                              },
                            ),
                            SizedBox(height: isDesktop ? 16 : 16.h),
                            LanguageOption(
                              title: AppStrings.english.tr(),
                              subtitle: AppStrings.englishDesc.tr(),
                              isSelected: !isArabic,
                              onTap: () {
                                if (isArabic) {
                                  context.read<LocaleCubit>().toEnglish();
                                }
                              },
                            ),

                            SizedBox(height: isDesktop ? 32 : 32.h),

                            // Subscription Section
                            SectionHeader(
                              title: AppStrings.subscriptionSection.tr(),
                            ),
                            const SubscriptionInfoWidget(),

                            SizedBox(height: isDesktop ? 32 : 32.h),

                            // Employee Management Section
                            SectionHeader(
                              title: AppStrings.employeeManagement.tr(),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.employeeList,
                                );
                              },
                              borderRadius: BorderRadius.circular(12.r),
                              child: Container(
                                padding: EdgeInsets.all(isDesktop ? 16 : 14.w),
                                decoration: BoxDecoration(
                                  color: AppColors.whiteColor,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: AppColors.veryLightGrey,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primaryColor
                                          .withValues(alpha: 0.1),
                                      radius: 20.r,
                                      child: Icon(
                                        Icons.people_rounded,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    SizedBox(width: 16.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppStrings.employeeManagement.tr(),
                                            style: TextStyles.customStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.blackReal,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            AppStrings.employeeManagementDesc
                                                .tr(),
                                            style: TextStyles.customStyle(
                                              fontSize: 12,
                                              color: AppColors.sandText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: AppColors.sandText,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: isDesktop ? 32 : 32.h),

                            // Logout button
                            const LogoutButton(),

                            SizedBox(height: isDesktop ? 16 : 16.h),

                            // Display email
                            Center(
                              child: Text(
                                userEmail,
                                style: TextStyles.customStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.sandText,
                                ),
                              ),
                            ),

                            // Space for bottom nav
                            SizedBox(height: isDesktop ? 40 : 100.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
