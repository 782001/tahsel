import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/logo/project_logo_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/settings/data/models/user_profile_model.dart';
import 'package:tahsel/features/settings/presentation/cubit/profile_cubit.dart';
import 'package:tahsel/features/settings/presentation/cubit/profile_state.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/shimmer/shimmer_loading.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

import 'edit_profile_dialog.dart';

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocConsumer<ConnectivityCubit, ConnectivityState>(
      listenWhen: (previous, current) =>
          previous is ConnectivityDisconnected &&
          current is ConnectivityConnected,
      listener: (context, connectivityState) {
        // Automatically reload profile data when connection is restored
        context.read<ProfileCubit>().loadProfile();
      },
      builder: (context, connectivityState) {
        final isOffline = connectivityState is ConnectivityDisconnected;

        if (isOffline) {
          return _buildOfflineCard(context, isDesktop);
        }

        return BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return _buildLoadingCard(isDesktop);
            }

            if (state is ProfileError) {
              if (_isNetworkError(state.message)) {
                return _buildOfflineCard(context, isDesktop);
              }
              return _buildErrorCard(context, state.message, isDesktop);
            }

            UserProfileModel profile;
            if (state is ProfileLoaded) {
              profile = state.profile;
            } else if (state is ProfileUpdating) {
              profile = state.currentProfile;
            } else if (state is ProfileUpdateSuccess) {
              profile = state.updatedProfile;
            } else if (state is ProfileUpdateError) {
              profile = state.currentProfile;
            } else {
              return const SizedBox.shrink();
            }

            return _buildContentCard(context, profile, isDesktop);
          },
        );
      },
    );
  }

  bool _isNetworkError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('failed host lookup') ||
        lower.contains('unavailable') ||
        lower.contains('connection') ||
        lower.contains('timeout');
  }

  /// Compact shimmer loading skeleton matching the new card proportions
  Widget _buildLoadingCard(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 14.w,
        vertical: isDesktop ? 12 : 10.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.dividerColor.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: ShimmerLoading(
        child: Row(
          children: [
            ShimmerPlaceholder(
              width: isDesktop ? 44 : 40.w,
              height: isDesktop ? 44 : 40.w,
              borderRadius: isDesktop ? 12 : 12.r,
            ),
            SizedBox(width: isDesktop ? 12 : 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ShimmerPlaceholder(
                      width: isDesktop ? 130 : 110.w,
                      height: 13,
                      borderRadius: 4,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ShimmerPlaceholder(
                      width: isDesktop ? 90 : 80.w,
                      height: 11,
                      borderRadius: 4,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ShimmerPlaceholder(
                      width: isDesktop ? 150 : 130.w,
                      height: 10,
                      borderRadius: 4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            ShimmerPlaceholder(
              width: isDesktop ? 60 : 52.w,
              height: 28,
              borderRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  /// Reassuring offline card indicating data will appear when online
  Widget _buildOfflineCard(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 14 : 12.w,
        vertical: isDesktop ? 10 : 9.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.dividerColor.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 40 : 36.w,
            height: isDesktop ? 40 : 36.w,
            decoration: BoxDecoration(
              color: AppColors.sandText.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: isDesktop ? 20 : 18,
              color: AppColors.sandText,
            ),
          ),
          SizedBox(width: isDesktop ? 12 : 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.profileInfo.tr(),
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 13.5 : 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  AppStrings.profileOfflineNotice.tr(),
                  style: TextStyles.customStyle(
                    fontSize: isDesktop ? 11.5 : 11,
                    color: AppColors.subTitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String message, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 14 : 12.w,
        vertical: isDesktop ? 10 : 9.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          SizedBox(width: isDesktop ? 10 : 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyles.customStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              final isOffline =
                  context.read<ConnectivityCubit>().state
                      is ConnectivityDisconnected;
              if (isOffline) {
                showfailureToast(AppStrings.noInternetConnection.tr());
                return;
              }
              context.read<ProfileCubit>().loadProfile();
            },
            child: Text(
              'retry'.tr(),
              style: TextStyles.customStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact, modern profile card that saves massive vertical screen space
  Widget _buildContentCard(
    BuildContext context,
    UserProfileModel profile,
    bool isDesktop,
  ) {
    final hasPhone = profile.phoneNumber.trim().isNotEmpty;
    final hasCrn = profile.crn.trim().isNotEmpty;
    final hasVat = profile.vat.trim().isNotEmpty;
    final hasExtraInfo = hasPhone || hasCrn || hasVat;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 14 : 12.w,
        vertical: isDesktop ? 11 : 9.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.15),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Row: Brand / Logo + Names & Email + Edit Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Brand / Store Icon or Custom Logo (compact 40-44)
              ValueListenableBuilder<String?>(
                valueListenable: ProjectLogoService.instance.logoNotifier,
                builder: (context, logoPath, _) {
                  final hasLogo =
                      logoPath != null && File(logoPath).existsSync();

                  return Container(
                    width: isDesktop ? 44 : 40.w,
                    height: isDesktop ? 44 : 40.w,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: hasLogo ? AppColors.surface : null,
                      gradient: hasLogo
                          ? null
                          : LinearGradient(
                              colors: [
                                AppColors.primaryColor,
                                AppColors.primaryColor.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: hasLogo
                          ? Border.all(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.25,
                              ),
                              width: 1.2,
                            )
                          : null,
                    ),
                    child: hasLogo
                        ? Image.file(
                            File(logoPath),
                            fit: BoxFit.cover,
                            key: ValueKey(logoPath),
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: isDesktop ? 22 : 20,
                            ),
                          )
                        : Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                            size: isDesktop ? 22 : 20,
                          ),
                  );
                },
              ),
              SizedBox(width: isDesktop ? 12 : 10.w),

              // Project Name, Owner, Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.projectName.isNotEmpty
                          ? profile.projectName
                          : AppStrings.projectName.tr(),
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 15.5 : 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 12,
                          color: AppColors.subTitleColor,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            profile.fullName.isNotEmpty
                                ? profile.fullName
                                : AppStrings.fullName.tr(),
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 11.5 : 11,
                              color: AppColors.subTitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 10.5,
                          color: AppColors.sandText,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            profile.email,
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 11 : 10.5,
                              color: AppColors.subTitleColor.withValues(
                                alpha: 0.85,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // Compact Edit Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final isOffline =
                        context.read<ConnectivityCubit>().state
                            is ConnectivityDisconnected;
                    if (isOffline) {
                      showfailureToast(AppStrings.noInternetConnection.tr());
                      return;
                    }
                    EditProfileDialog.show(context, profile);
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 10 : 8.w,
                      vertical: isDesktop ? 6 : 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: isDesktop ? 14 : 13,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(width: isDesktop ? 4 : 3.w),
                        Text(
                          AppStrings.edit.tr(),
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 12 : 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Optional micro-badges row for populated commercial info
          if (hasExtraInfo) ...[
            SizedBox(height: isDesktop ? 7 : 6.h),
            Wrap(
              spacing: isDesktop ? 6 : 5.w,
              runSpacing: 4.h,
              children: [
                if (hasPhone)
                  _buildCompactBadge(
                    context: context,
                    icon: Icons.phone_outlined,
                    text: profile.phoneNumber,
                    isDesktop: isDesktop,
                  ),
                if (hasCrn)
                  _buildCompactBadge(
                    context: context,
                    icon: Icons.badge_outlined,
                    text: '${AppStrings.crnShort.tr()}: ${profile.crn}',
                    isDesktop: isDesktop,
                  ),
                if (hasVat)
                  _buildCompactBadge(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    text: '${AppStrings.vatShort.tr()}: ${profile.vat}',
                    isDesktop: isDesktop,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactBadge({
    required BuildContext context,
    required IconData icon,
    required String text,
    required bool isDesktop,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxBadgeWidth = isDesktop
        ? 400.0
        : (screenWidth - 70.w).clamp(100.0, 500.0);

    return Container(
      constraints: BoxConstraints(maxWidth: maxBadgeWidth),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 7 : 6.w,
        vertical: isDesktop ? 2.5 : 2.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.scafoldBackGround,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: AppColors.dividerColor.withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: AppColors.primaryColor),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              text,
              style: TextStyles.customStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.subTitleColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
