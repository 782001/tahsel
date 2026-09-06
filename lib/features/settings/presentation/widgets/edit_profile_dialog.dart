import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/logo/project_logo_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/settings/data/models/user_profile_model.dart';
import 'package:tahsel/features/settings/presentation/cubit/profile_cubit.dart';
import 'package:tahsel/features/settings/presentation/cubit/profile_state.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/text_fields/custom_text_form_field.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';

class EditProfileDialog extends StatefulWidget {
  final UserProfileModel profile;

  const EditProfileDialog({
    super.key,
    required this.profile,
  });

  static Future<void> show(BuildContext context, UserProfileModel profile) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ProfileCubit>(),
        child: EditProfileDialog(profile: profile),
      ),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _projectNameController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _crnController;
  late final TextEditingController _vatController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _projectNameController = TextEditingController(text: widget.profile.projectName);
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber);
    _crnController = TextEditingController(text: widget.profile.crn);
    _vatController = TextEditingController(text: widget.profile.vat);
    _addressController = TextEditingController(text: widget.profile.address);
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _crnController.dispose();
    _vatController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _onPickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null && path.isNotEmpty) {
          final saved = await ProjectLogoService.instance.saveLogo(path);
          if (saved != null) {
            showSuccessToast(AppStrings.logoUpdatedSuccessfully.tr());
          }
        }
      }
    } catch (e) {
      AppLogger.printMessage('Error picking logo: $e');
    }
  }

  Future<void> _onRemoveLogo() async {
    await ProjectLogoService.instance.deleteLogo();
    showSuccessToast(AppStrings.logoRemovedSuccessfully.tr());
  }

  void _onSave(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final isOffline = context.read<ConnectivityCubit>().state is ConnectivityDisconnected;
    if (isOffline) {
      showfailureToast(AppStrings.noInternetConnection.tr());
      return;
    }

    final navigator = Navigator.of(context);
    final success = await context.read<ProfileCubit>().updateProfile(
      fullName: _fullNameController.text,
      projectName: _projectNameController.text,
      phoneNumber: _phoneController.text,
      crn: _crnController.text,
      address: _addressController.text,
      vat: _vatController.text,
    );

    if (!mounted) return;

    if (success) {
      showSuccessToast(AppStrings.profileUpdatedSuccessfully.tr());
      navigator.pop();
    } else {
      showfailureToast(AppStrings.failedToUpdateUser.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final isSaving = state is ProfileUpdating;

        return Dialog(
          backgroundColor: AppColors.surface,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40 : 16.w,
            vertical: 24.h,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 620 : double.infinity,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog Header
                _buildHeader(context, isDesktop),

                const Divider(height: 1, thickness: 1),

                // Form Content
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(isDesktop ? 24 : 18.w),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Project Logo Section
                          _buildLogoSection(isDesktop),
                          SizedBox(height: isDesktop ? 22 : 18.h),

                          // Project Name
                          CustomTextFormField(
                            labelText: AppStrings.projectName.tr(),
                            controller: _projectNameController,
                            keyboardType: TextInputType.text,
                            hintText: AppStrings.projectNameHint.tr(),
                            prefixIcon: Icons.storefront_rounded,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppStrings.validationFieldRequired.tr();
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isDesktop ? 18 : 16.h),

                          // Full Name
                          CustomTextFormField(
                            labelText: AppStrings.fullName.tr(),
                            controller: _fullNameController,
                            keyboardType: TextInputType.name,
                            hintText: AppStrings.fullNameHint.tr(),
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppStrings.validationFieldRequired.tr();
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isDesktop ? 18 : 16.h),

                          // Phone Number
                          CustomTextFormField(
                            labelText: AppStrings.phone.tr(),
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            hintText: '01xxxxxxxxx',
                            prefixIcon: Icons.phone_outlined,
                          ),
                          SizedBox(height: isDesktop ? 18 : 16.h),

                          // CRN (Commercial Registration)
                          CustomTextFormField(
                            labelText:
                                '${AppStrings.commercialRegistration.tr()} (${AppStrings.optional.tr()})',
                            controller: _crnController,
                            keyboardType: TextInputType.text,
                            hintText: AppStrings.commercialRegistrationHint.tr(),
                            prefixIcon: Icons.badge_outlined,
                          ),
                          SizedBox(height: isDesktop ? 18 : 16.h),

                          // VAT Number
                          CustomTextFormField(
                            labelText:
                                '${AppStrings.vatNumber.tr()} (${AppStrings.optional.tr()})',
                            controller: _vatController,
                            keyboardType: TextInputType.text,
                            hintText: AppStrings.vatNumberHint.tr(),
                            prefixIcon: Icons.receipt_long_outlined,
                          ),
                          SizedBox(height: isDesktop ? 18 : 16.h),

                          // Address
                          CustomTextFormField(
                            labelText:
                                '${AppStrings.businessAddress.tr()} (${AppStrings.optional.tr()})',
                            controller: _addressController,
                            keyboardType: TextInputType.streetAddress,
                            hintText: AppStrings.businessAddressHint.tr(),
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          SizedBox(height: isDesktop ? 20 : 18.h),

                          // Email Section (Non-editable Notice & Field)
                          _buildReadOnlyEmailCard(isDesktop),
                        ],
                      ),
                    ),
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // Dialog Actions
                _buildActions(context, isDesktop, isSaving),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoSection(bool isDesktop) {
    return ValueListenableBuilder<String?>(
      valueListenable: ProjectLogoService.instance.logoNotifier,
      builder: (context, logoPath, _) {
        final hasLogo = logoPath != null && File(logoPath).existsSync();

        return Center(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _onPickLogo,
                    child: Container(
                      width: isDesktop ? 88 : 80.w,
                      height: isDesktop ? 88 : 80.w,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: hasLogo
                            ? AppColors.surface
                            : AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(22.r),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.15),
                            blurRadius: 10,
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
                                size: isDesktop ? 42 : 38,
                                color: AppColors.primaryColor,
                              ),
                            )
                          : Icon(
                              Icons.add_photo_alternate_outlined,
                              size: isDesktop ? 40 : 36,
                              color: AppColors.primaryColor,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _onPickLogo,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? 10 : 8.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: _onPickLogo,
                    icon: Icon(
                      hasLogo
                          ? Icons.sync_rounded
                          : Icons.add_photo_alternate_rounded,
                      size: 16,
                      color: AppColors.primaryColor,
                    ),
                    label: Text(
                      hasLogo
                          ? AppStrings.changeLogo.tr()
                          : AppStrings.uploadLogo.tr(),
                      style: TextStyles.customStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  if (hasLogo) ...[
                    SizedBox(width: isDesktop ? 8 : 6.w),
                    TextButton.icon(
                      onPressed: _onRemoveLogo,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                      label: Text(
                        AppStrings.removeLogo.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 18.w,
        vertical: isDesktop ? 18 : 14.h,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 10 : 8.w),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.edit_note_rounded,
              color: AppColors.primaryColor,
              size: isDesktop ? 24 : 22,
            ),
          ),
          SizedBox(width: isDesktop ? 12 : 10.w),
          Expanded(
            child: Text(
              AppStrings.editProfileTitle.tr(),
              style: TextStyles.customStyle(
                fontSize: isDesktop ? 18 : 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: AppColors.subTitleColor,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyEmailCard(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 16 : 14.w),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF252525) : const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.veryLightGrey.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: isDesktop ? 16 : 15,
                color: AppColors.sandText,
              ),
              SizedBox(width: isDesktop ? 8 : 6.w),
              Text(
                AppStrings.emailAddress.tr(),
                style: TextStyles.customStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.subTitleColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 8 : 6.w,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sandText.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  AppStrings.nonEditable.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 8 : 6.h),
          Text(
            widget.profile.email,
            style: TextStyles.customStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          SizedBox(height: isDesktop ? 6 : 4.h),
          Text(
            AppStrings.emailCannotBeChanged.tr(),
            style: TextStyles.customStyle(
              fontSize: 11,
              color: AppColors.subTitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDesktop, bool isSaving) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 18.w,
        vertical: isDesktop ? 16 : 14.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: isSaving ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 20 : 16.w,
                vertical: isDesktop ? 12 : 10.h,
              ),
            ),
            child: Text(
              AppStrings.cancel.tr(),
              style: TextStyles.customStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.subTitleColor,
              ),
            ),
          ),
          SizedBox(width: isDesktop ? 12 : 10.w),
          ElevatedButton(
            onPressed: isSaving ? null : () => _onSave(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 20.w,
                vertical: isDesktop ? 12 : 10.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded, size: 18),
                      SizedBox(width: isDesktop ? 6 : 6.w),
                      Text(
                        AppStrings.saveChanges.tr(),
                        style: TextStyles.customStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
