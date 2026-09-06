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
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

import 'edit_profile_dialog.dart';

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileInitial) {
          return _buildLoadingCard(isDesktop);
        }

        if (state is ProfileError) {
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
  }

  Widget _buildLoadingCard(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 18.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.veryLightGrey.withValues(alpha: 0.5),
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String message, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 20 : 16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error),
          SizedBox(width: isDesktop ? 12 : 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyles.customStyle(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ),
          TextButton(
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
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(
    BuildContext context,
    UserProfileModel profile,
    bool isDesktop,
  ) {
    final hasCrn = profile.crn.isNotEmpty;
    final hasVat = profile.vat.isNotEmpty;
    final hasAddress = profile.address.isNotEmpty;
    final hasPhone = profile.phoneNumber.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle top-right decorative radial glow
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isDesktop ? 22 : 18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Icon + Project Name + Edit Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand / Store Icon or Custom Logo
                    ValueListenableBuilder<String?>(
                      valueListenable: ProjectLogoService.instance.logoNotifier,
                      builder: (context, logoPath, _) {
                        final hasLogo =
                            logoPath != null && File(logoPath).existsSync();

                        return Container(
                          width: isDesktop ? 54 : 48.w,
                          height: isDesktop ? 54 : 48.w,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: hasLogo ? AppColors.surface : null,
                            gradient: hasLogo
                                ? null
                                : LinearGradient(
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
                            border: hasLogo
                                ? Border.all(
                                    color: AppColors.primaryColor.withValues(
                                      alpha: 0.25,
                                    ),
                                    width: 1.5,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: hasLogo
                              ? Image.file(
                                  File(logoPath),
                                  fit: BoxFit.cover,
                                  key: ValueKey(logoPath),
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.storefront_rounded,
                                    color: Colors.white,
                                    size: isDesktop ? 28 : 24,
                                  ),
                                )
                              : Icon(
                                  Icons.storefront_rounded,
                                  color: Colors.white,
                                  size: isDesktop ? 28 : 24,
                                ),
                        );
                      },
                    ),
                    SizedBox(width: isDesktop ? 16 : 14.w),

                    // Project & Owner Names
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.projectName.isNotEmpty
                                ? profile.projectName
                                : AppStrings.projectName.tr(),
                            style: TextStyles.customStyle(
                              fontSize: isDesktop ? 18 : 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor,
                            ),
                          ),
                          SizedBox(height: isDesktop ? 4 : 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: AppColors.subTitleColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                profile.fullName.isNotEmpty
                                    ? profile.fullName
                                    : AppStrings.fullName.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 13,
                                  color: AppColors.subTitleColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Edit Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final isOffline =
                              context.read<ConnectivityCubit>().state
                                  is ConnectivityDisconnected;
                          if (isOffline) {
                            showfailureToast(
                              AppStrings.noInternetConnection.tr(),
                            );
                            return;
                          }
                          EditProfileDialog.show(context, profile);
                        },
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 14 : 12.w,
                            vertical: isDesktop ? 8 : 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: isDesktop ? 16 : 15,
                                color: AppColors.primaryColor,
                              ),
                              SizedBox(width: isDesktop ? 6 : 4.w),
                              Text(
                                AppStrings.editProfile.tr(),
                                style: TextStyles.customStyle(
                                  fontSize: 12,
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

                SizedBox(height: isDesktop ? 18 : 16.h),
                const Divider(height: 1, thickness: 0.8),
                SizedBox(height: isDesktop ? 16 : 14.h),

                // Details Grid / List
                // 1. Email with lock badge
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: AppStrings.emailAddress.tr(),
                  value: profile.email,
                  isDesktop: isDesktop,
                  badge: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sandText.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 10,
                          color: AppColors.sandText,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          AppStrings.nonEditable.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Phone
                if (hasPhone) ...[
                  SizedBox(height: isDesktop ? 10 : 8.h),
                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    label: AppStrings.phone.tr(),
                    value: profile.phoneNumber,
                    isDesktop: isDesktop,
                  ),
                ],

                // 3. CRN (Commercial Registration)
                SizedBox(height: isDesktop ? 10 : 8.h),
                _buildInfoRow(
                  icon: Icons.badge_outlined,
                  label: AppStrings.commercialRegistration.tr(),
                  value: hasCrn ? profile.crn : AppStrings.notSpecified.tr(),
                  isDesktop: isDesktop,
                  isDimmed: !hasCrn,
                ),

                // 4. VAT Number
                SizedBox(height: isDesktop ? 10 : 8.h),
                _buildInfoRow(
                  icon: Icons.receipt_long_outlined,
                  label: AppStrings.vatNumber.tr(),
                  value: hasVat ? profile.vat : AppStrings.notSpecified.tr(),
                  isDesktop: isDesktop,
                  isDimmed: !hasVat,
                ),

                // 5. Address
                SizedBox(height: isDesktop ? 10 : 8.h),
                _buildInfoRow(
                  icon: Icons.location_on_outlined,
                  label: AppStrings.businessAddress.tr(),
                  value: hasAddress
                      ? profile.address
                      : AppStrings.notSpecified.tr(),
                  isDesktop: isDesktop,
                  isDimmed: !hasAddress,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDesktop,
    Widget? badge,
    bool isDimmed = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: AppColors.primaryColor),
        ),
        SizedBox(width: isDesktop ? 10 : 8.w),
        Text(
          '$label: ',
          style: TextStyles.customStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.subTitleColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyles.customStyle(
              fontSize: 13,
              fontWeight: isDimmed ? FontWeight.normal : FontWeight.w600,
              color: isDimmed
                  ? AppColors.subTitleColor.withValues(alpha: 0.7)
                  : AppColors.textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (badge != null) ...[const SizedBox(width: 6), badge],
      ],
    );
  }
}
