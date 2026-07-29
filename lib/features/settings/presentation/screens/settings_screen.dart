import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/currency/currency_service.dart';
import 'package:tahsel/core/services/currency/domain/entities/currency_entity.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/storage/secure_storage_helper.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/assets.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/delete_account_confirmation_dialog.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:tahsel/features/auth/presentation/cubit/auth_state.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import 'package:tahsel/features/settings/presentation/widgets/appearance_card.dart';
import 'package:tahsel/features/settings/presentation/widgets/currency_selection_bottom_sheet.dart';
import 'package:tahsel/features/settings/presentation/widgets/language_option.dart';
import 'package:tahsel/features/settings/presentation/widgets/logout_button.dart';
import 'package:tahsel/features/settings/presentation/widgets/section_header.dart';
import 'package:tahsel/features/settings/presentation/widgets/subscription_info_widget.dart';
import 'package:tahsel/features/standard_features/localization/presentation/cubit/locale_cubit.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_cubit.dart';
import 'package:tahsel/features/standard_features/theme/presentation/cubit/theme_state.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void _shareApp() {
    SharePlus.instance.share(ShareParams(text: AppStrings.shareMessage.tr()));
  }

  void _showVipNoticeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.scafoldBackGround,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.amber,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.vipAccount.tr(),
              style: TextStyles.customStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.blackReal,
              ),
            ),
          ],
        ),
        content: Text(
          AppStrings.vipOnlyNotice.tr(),
          style: TextStyles.customStyle(
            fontSize: 14,
            color: AppColors.sandText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'حسناً',
              style: TextStyles.customStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
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

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, authState) {
        if (authState is AuthDeleteFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authState.message,
                style: TextStyles.customStyle(color: AppColors.white),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, state) {
          final currentLang = context.read<LocaleCubit>().currentLangCode;
          final isArabic = currentLang == AppStrings.arabicCode;
          final isShop = context.read<MainLayoutCubit>().isShop;
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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

                              if (!Platform.isIOS ||
                                  (AppStrings.isVip && isShop))
                                SizedBox(height: isDesktop ? 16 : 16.h),
                              // Inventory Management (VIP) Section
                              if (!Platform.isIOS ||
                                  (AppStrings.isVip && isShop))
                                SectionHeader(
                                  title: AppStrings.inventoryManagementVIP.tr(),
                                ),
                              if (!Platform.isIOS ||
                                  (AppStrings.isVip && isShop))
                                SizedBox(height: isDesktop ? 5 : 5.h),
                              if (!Platform.isIOS ||
                                  (AppStrings.isVip && isShop))
                                InkWell(
                                  onTap: () {
                                    if (!(AppStrings.isVip && isShop)) {
                                      _showVipNoticeDialog(context);
                                      return;
                                    }
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.inventoryMain,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20.r),
                                  child: Container(
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.r),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryColor,
                                          AppColors.primaryColor.withValues(
                                            alpha: 0.82,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryColor
                                              .withValues(alpha: 0.3),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Decorative Background Glow Circles
                                        Positioned(
                                          right: -30,
                                          top: -30,
                                          child: Container(
                                            width: 130.w,
                                            height: 130.h,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.vipGoldStart
                                                  .withValues(alpha: 0.12),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: -20,
                                          bottom: -20,
                                          child: Container(
                                            width: 100.w,
                                            height: 100.h,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(
                                            isDesktop ? 22 : 18.w,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  // Icon with Golden Ring Effect
                                                  Container(
                                                    padding: EdgeInsets.all(
                                                      isDesktop ? 14 : 12.w,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          AppColors.whiteColor
                                                              .withValues(
                                                                alpha: 0.25,
                                                              ),
                                                          AppColors.whiteColor
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            isDesktop
                                                                ? 16
                                                                : 14.r,
                                                          ),
                                                      border: Border.all(
                                                        color: AppColors
                                                            .whiteColor
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.inventory_2_rounded,
                                                      color: AppColors
                                                          .vipGoldStart,
                                                      size: 28,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: isDesktop
                                                        ? 16
                                                        : 14.w,
                                                  ),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          AppStrings
                                                              .inventoryManagementVIP
                                                              .tr(),
                                                          style:
                                                              TextStyles.customStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: AppColors
                                                                    .whiteColor,
                                                              ),
                                                        ),
                                                        SizedBox(
                                                          height: isDesktop
                                                              ? 4
                                                              : 4.h,
                                                        ),
                                                        Text(
                                                          AppStrings
                                                              .inventoryManagementVIPDesc
                                                              .tr(),
                                                          style:
                                                              TextStyles.customStyle(
                                                                fontSize: 12,
                                                                color: AppColors
                                                                    .whiteColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.85,
                                                                    ),
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // VIP Golden Metallic Badge
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: isDesktop
                                                              ? 12
                                                              : 10.w,
                                                          vertical: isDesktop
                                                              ? 6
                                                              : 5.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                            colors: [
                                                              Color(0xFFFFD700),
                                                              Color(0xFFFFA500),
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            isDesktop
                                                                ? 20
                                                                : 20.r,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              const Color(
                                                                0xFFFFD700,
                                                              ).withValues(
                                                                alpha: 0.4,
                                                              ),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .workspace_premium_rounded,
                                                          size: 16,
                                                          color: Colors.black87,
                                                        ),
                                                        SizedBox(
                                                          width: isDesktop
                                                              ? 4
                                                              : 4.w,
                                                        ),
                                                        Text(
                                                          'VIP',
                                                          style:
                                                              TextStyles.customStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: isDesktop ? 14 : 12.h,
                                              ),
                                              // Sub-features Quick Chips
                                              SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                                  children: [
                                                    _buildVipFeatureChip(
                                                      context,
                                                      label: AppStrings
                                                          .inventoryProducts
                                                          .tr(),
                                                      icon: Icons
                                                          .shopping_bag_outlined,
                                                    ),
                                                    SizedBox(
                                                      width: isDesktop
                                                          ? 8
                                                          : 6.w,
                                                    ),
                                                    _buildVipFeatureChip(
                                                      context,
                                                      label: AppStrings
                                                          .inventorySuppliers
                                                          .tr(),
                                                      icon: Icons
                                                          .local_shipping_outlined,
                                                    ),
                                                    SizedBox(
                                                      width: isDesktop
                                                          ? 8
                                                          : 6.w,
                                                    ),
                                                    _buildVipFeatureChip(
                                                      context,
                                                      label: AppStrings
                                                          .inventoryPurchases
                                                          .tr(),
                                                      icon: Icons
                                                          .receipt_outlined,
                                                    ),
                                                  ],
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

                              // Employee Management Section
                              SectionHeader(
                                title: AppStrings.employeeManagement.tr(),
                              ),
                              SizedBox(height: isDesktop ? 5 : 5.h),
                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.employeeList,
                                  );
                                },
                                borderRadius: BorderRadius.circular(16.r),
                                child: Container(
                                  padding: EdgeInsets.all(
                                    isDesktop ? 20 : 18.w,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryColor,
                                        AppColors.primaryColor.withValues(
                                          alpha: 0.8,
                                        ),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryColor
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                          isDesktop ? 12 : 12.w,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.whiteColor
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            isDesktop ? 12 : 12.r,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.groups_rounded,
                                          color: AppColors.whiteColor,
                                          size: 28,
                                        ),
                                      ),
                                      SizedBox(width: isDesktop ? 16 : 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppStrings.employeeManagement
                                                  .tr(),
                                              style: TextStyles.customStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.whiteColor,
                                              ),
                                            ),
                                            SizedBox(
                                              height: isDesktop ? 6 : 6.h,
                                            ),
                                            Text(
                                              AppStrings.employeeManagementDesc
                                                  .tr(),
                                              style: TextStyles.customStyle(
                                                fontSize: 13,
                                                color: AppColors.whiteColor
                                                    .withValues(alpha: 0.9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isDesktop ? 12 : 12.w,
                                          vertical: isDesktop ? 8 : 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.whiteColor
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            isDesktop ? 20 : 20.r,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star_rounded,
                                              size: 16,
                                              color: AppColors.whiteColor,
                                            ),
                                            SizedBox(
                                              width: isDesktop ? 4 : 4.w,
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 14,
                                              color: AppColors.whiteColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              if (!Platform.isIOS)
                                SizedBox(height: isDesktop ? 32 : 32.h),

                              // Subscription Section
                              if (!Platform.isIOS)
                                SectionHeader(
                                  title: AppStrings.subscriptionSection.tr(),
                                ),
                              if (!Platform.isIOS)
                                const SubscriptionInfoWidget(),

                              SizedBox(height: isDesktop ? 32 : 32.h),
                              // Currency Section
                              SectionHeader(
                                title: AppStrings.changeCurrency.tr(),
                              ),
                              SizedBox(height: isDesktop ? 12 : 12.h),
                              ValueListenableBuilder<CurrencyEntity>(
                                valueListenable:
                                    CurrencyService.instance.currencyNotifier,
                                builder: (context, activeCurrency, child) {
                                  return InkWell(
                                    onTap: () async {
                                      final hasConn = await sl<
                                        InternetConnectionChecker
                                      >().hasConnection;
                                      if (!hasConn) {
                                        showfailureToast(
                                          AppStrings.noInternetConnection.tr(),
                                        );
                                        return;
                                      }
                                      if (context.mounted) {
                                        CurrencySelectionBottomSheet.show(
                                          context,
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(16.r),
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        isDesktop ? 16 : 16.w,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: isDesktop ? 50 : 50.w,
                                            height: isDesktop ? 50 : 50.w,
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryColor
                                                  .withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              activeCurrency.getSymbol(
                                                currentLang,
                                              ),
                                              style: TextStyles.customStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  activeCurrency.getName(
                                                    currentLang,
                                                  ),
                                                  style: TextStyles.customStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.black,
                                                  ),
                                                ),
                                                SizedBox(height: 2.h),
                                                Text(
                                                  '${activeCurrency.code} (${activeCurrency.arabicSymbol} / ${activeCurrency.englishSymbol})',
                                                  style: TextStyles.customStyle(
                                                    fontSize: 13,
                                                    color: AppColors.sandText,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: AppColors.disabledColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Account Section
                              SectionHeader(title: AppStrings.account.tr()),
                              InkWell(
                                onTap: () async {
                                  final hasConn = await sl<
                                    InternetConnectionChecker
                                  >().hasConnection;
                                  if (!hasConn) {
                                    showfailureToast(
                                      AppStrings.noInternetConnection.tr(),
                                    );
                                    return;
                                  }
                                  if (!context.mounted) return;
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) =>
                                        const DeleteAccountConfirmationDialog(),
                                  );

                                  if (shouldDelete ?? false) {
                                    if (context.mounted) {
                                      context.read<AuthCubit>().deleteAccount();
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(12.r),
                                child: Container(
                                  padding: EdgeInsets.all(
                                    isDesktop ? 16 : 14.w,
                                  ),
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
                                        backgroundColor: AppColors.error
                                            .withValues(alpha: 0.1),
                                        radius: 20.r,
                                        child: Icon(
                                          Icons.person_remove_rounded,
                                          color: AppColors.error,
                                        ),
                                      ),
                                      SizedBox(width: isDesktop ? 16 : 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppStrings.deleteAccount.tr(),
                                              style: TextStyles.customStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.blackReal,
                                              ),
                                            ),
                                            SizedBox(
                                              height: isDesktop ? 4 : 4.h,
                                            ),
                                            Text(
                                              AppStrings.deleteAccountWarning
                                                  .tr(),
                                              style: TextStyles.customStyle(
                                                fontSize: 12,
                                                color: AppColors.error,
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

                              // Official Website Section
                              if (!Platform.isIOS)
                                SectionHeader(
                                  title: AppStrings.officialWebsite.tr(),
                                ),

                              if (!Platform.isIOS)
                                InkWell(
                                  onTap: () async {
                                    final uri = Uri.parse(
                                      AppStrings.tahselWebsiteUrl,
                                    );

                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Container(
                                    padding: EdgeInsets.all(
                                      isDesktop ? 16 : 14.w,
                                    ),
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
                                          backgroundColor: AppColors
                                              .primaryColor
                                              .withValues(alpha: 0.1),
                                          radius: 20.r,
                                          child: Icon(
                                            Icons.language_rounded,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                        SizedBox(width: isDesktop ? 16 : 16.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppStrings.officialWebsite.tr(),
                                                style: TextStyles.customStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.blackReal,
                                                ),
                                              ),
                                              SizedBox(
                                                height: isDesktop ? 4 : 4.h,
                                              ),
                                              Text(
                                                AppStrings.officialWebsiteDesc
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
                                          Icons.open_in_new_rounded,
                                          size: isDesktop ? 18 : 18.sp,
                                          color: AppColors.sandText,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              SizedBox(height: isDesktop ? 32 : 32.h),

                              // Facebook Page Section
                              SectionHeader(
                                title: AppStrings.facebookPage.tr(),
                              ),
                              InkWell(
                                onTap: () async {
                                  final uri = Uri.parse(
                                    "https://www.facebook.com/profile.php?id=61591493902471",
                                  );

                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                borderRadius: BorderRadius.circular(12.r),
                                child: Container(
                                  padding: EdgeInsets.all(
                                    isDesktop ? 16 : 14.w,
                                  ),
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
                                        backgroundColor: const Color(
                                          0xFF1877F2,
                                        ).withValues(alpha: 0.1),
                                        radius: 20.r,
                                        child: const Icon(
                                          Icons.facebook_rounded,
                                          color: Color(0xFF1877F2),
                                        ),
                                      ),
                                      SizedBox(width: isDesktop ? 16 : 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppStrings.facebookPage.tr(),
                                              style: TextStyles.customStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.blackReal,
                                              ),
                                            ),
                                            SizedBox(
                                              height: isDesktop ? 4 : 4.h,
                                            ),
                                            Text(
                                              AppStrings.facebookPageDesc.tr(),
                                              style: TextStyles.customStyle(
                                                fontSize: 12,
                                                color: AppColors.sandText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.open_in_new_rounded,
                                        size: isDesktop ? 18 : 18.sp,
                                        color: AppColors.sandText,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: isDesktop ? 32 : 32.h),

                              // WhatsApp Group Section
                              SectionHeader(
                                title: AppStrings.whatsappGroup.tr(),
                              ),
                              InkWell(
                                onTap: () async {
                                  final uri = Uri.parse(
                                    "https://chat.whatsapp.com/IjVqDWB2MSJ60nottOAVba?s=cl&p=a&mlu=0&ilr=0&amv=0",
                                  );

                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                borderRadius: BorderRadius.circular(12.r),
                                child: Container(
                                  padding: EdgeInsets.all(
                                    isDesktop ? 16 : 14.w,
                                  ),
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
                                        backgroundColor: const Color(
                                          0xFF25D366,
                                        ).withValues(alpha: 0.1),
                                        radius: 20.r,
                                        child: Image.asset(
                                          Assets.imagesWhatsapp,
                                          width: isDesktop ? 22 : 22.w,
                                          height: isDesktop ? 22 : 22.w,
                                        ),
                                      ),
                                      SizedBox(width: isDesktop ? 16 : 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppStrings.whatsappGroup.tr(),
                                              style: TextStyles.customStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.blackReal,
                                              ),
                                            ),
                                            SizedBox(
                                              height: isDesktop ? 4 : 4.h,
                                            ),
                                            Text(
                                              AppStrings.whatsappGroupDesc.tr(),
                                              style: TextStyles.customStyle(
                                                fontSize: 12,
                                                color: AppColors.sandText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.open_in_new_rounded,
                                        size: isDesktop ? 18 : 18.sp,
                                        color: AppColors.sandText,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: isDesktop ? 32 : 32.h),
                              SectionHeader(title: AppStrings.shareApp.tr()),
                              InkWell(
                                onTap: _shareApp,
                                borderRadius: BorderRadius.circular(12.r),
                                child: Container(
                                  padding: EdgeInsets.all(
                                    isDesktop ? 16 : 14.w,
                                  ),
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
                                          Icons.share_rounded,
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
                                              AppStrings.shareAppWithFriends
                                                  .tr(),
                                              style: TextStyles.customStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.blackReal,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              AppStrings.shareAppDesc.tr(),
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
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20.r),
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(text: userEmail),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppStrings.copiedSuccessfully.tr(),
                                            style: TextStyles.customStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: AppColors.success,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isDesktop ? 16 : 16.w,
                                        vertical: isDesktop ? 8 : 8.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor
                                            .withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        border: Border.all(
                                          color: AppColors.primaryColor
                                              .withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.copy_rounded,
                                            size: isDesktop ? 14 : 14.sp,
                                            color: AppColors.primaryColor,
                                          ),
                                          SizedBox(width: isDesktop ? 6 : 6.w),
                                          Text(
                                            userEmail,
                                            style: TextStyles.customStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
      ),
    );
  }

  Widget _buildVipFeatureChip(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFFFD700)),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyles.customStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.whiteColor.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}
