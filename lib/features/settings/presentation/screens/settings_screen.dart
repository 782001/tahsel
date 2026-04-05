import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/settings/presentation/widgets/appearance_card.dart';
import 'package:tahsel/features/settings/presentation/widgets/language_info_box.dart';
import 'package:tahsel/features/settings/presentation/widgets/language_option.dart';
import 'package:tahsel/features/settings/presentation/widgets/logout_button.dart';
import 'package:tahsel/features/settings/presentation/widgets/section_header.dart';
import 'package:tahsel/features/standard_features/localization/presentation/cubit/locale_cubit.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_cubit.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
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
                    color: AppColors.primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20.h),
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
                        SizedBox(height: 32.h),

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
                                      context.read<ThemeCubit>().toLightMode();
                                    },
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: AppearanceCard(
                                    title: AppStrings.darkMode.tr(),
                                    icon: Icons.dark_mode_rounded,
                                    isSelected: isDark,
                                    onTap: () {
                                      context.read<ThemeCubit>().toDarkMode();
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 32.h),

                        // Language Section
                        SectionHeader(title: AppStrings.changeLanguage.tr()),
                        Text(
                          AppStrings.changeLanguageDesc.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.sandText,
                          ),
                        ),
                        SizedBox(height: 24.h),

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
                        SizedBox(height: 16.h),
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

                        SizedBox(height: 32.h),

                        // Info Box
                        const LanguageInfoBox(),
                        SizedBox(height: 48.h),

                        // Logout button
                        const LogoutButton(),

                        // Space for bottom nav
                        SizedBox(height: 100.h),
                      ],
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
