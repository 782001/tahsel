import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_indicator/loading_indicator.dart';

import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/services/injection_container.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/styles.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../cubit/shipping_reconciliation_cubit.dart';
import '../cubit/shipping_reconciliation_state.dart';
import '../widgets/column_mapping_step.dart';
import '../widgets/file_upload_step.dart';
import '../widgets/reconciliation_result_step.dart';

class ShippingReconciliationScreen extends StatelessWidget {
  const ShippingReconciliationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShippingReconciliationCubit>(
      create: (context) => sl<ShippingReconciliationCubit>(),
      child: const _ShippingReconciliationScreenContent(),
    );
  }
}

class _ShippingReconciliationScreenContent extends StatelessWidget {
  const _ShippingReconciliationScreenContent();

  void _handleBack(BuildContext context, ShippingReconciliationState state) {
    final cubit = context.read<ShippingReconciliationCubit>();

    if (state is ShippingReconciliationSuccessState) {
      // Step 3 -> Step 2 (Mapping Review)
      cubit.openMappingReviewScreen();
    } else if (state is ShippingReconciliationMappingReviewState) {
      // Step 2 -> Step 1 (File Upload)
      cubit.backToFilesStep();
    } else if (state is ShippingReconciliationFilesLoaded &&
        (state.internalFile != null || state.shippingFile != null)) {
      // Step 1 with files -> reset files
      cubit.resetSession();
    } else {
      // Initial state / Empty -> Exit to Settings
      Navigator.of(context).pop();
    }
  }

  int _getCurrentStep(ShippingReconciliationState state) {
    if (state is ShippingReconciliationMappingReviewState) return 2;
    if (state is ShippingReconciliationSuccessState) return 3;
    return 1;
  }

  String _getStepTitle(ShippingReconciliationState state) {
    final step = _getCurrentStep(state);
    switch (step) {
      case 2:
        return AppStrings.reviewColumnMapping.tr();
      case 3:
        return AppStrings.shippingReportsReconciliation.tr();
      case 1:
      default:
        return AppStrings.shippingReconciliationTitle.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocConsumer<
      ShippingReconciliationCubit,
      ShippingReconciliationState
    >(
      listener: (context, state) {
        if (state is ShippingReconciliationFailureState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final currentStep = _getCurrentStep(state);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBack(context, state);
          },
          child: Scaffold(
            backgroundColor: AppColors.scafoldBackGround,
            appBar: AppBar(
              scrolledUnderElevation: 0,
              backgroundColor: AppColors.scafoldBackGround,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primaryColor,
                ),
                onPressed: () => _handleBack(context, state),
              ),
              title: Column(
                children: [
                  Text(
                    _getStepTitle(state),
                    style: TextStyles.customStyle(
                      fontSize: isDesktop ? 20 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // Step Indicator Dots / Badges
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStepDot(1, currentStep, isDesktop),
                      _buildStepLine(1, currentStep, isDesktop),
                      _buildStepDot(2, currentStep, isDesktop),
                      _buildStepLine(2, currentStep, isDesktop),
                      _buildStepDot(3, currentStep, isDesktop),
                    ],
                  ),
                ],
              ),
              centerTitle: true,
            ),
            body: RefreshIndicator(
              color: AppColors.primaryColor,
              backgroundColor: Theme.of(context).cardColor,
              onRefresh: () async {
                context.read<ShippingReconciliationCubit>().resetSession();
              },
              child: _buildBodyState(context, state, isDesktop),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepDot(int stepNumber, int currentStep, bool isDesktop) {
    final bool isActive = currentStep >= stepNumber;
    final bool isCurrent = currentStep == stepNumber;

    return Container(
      width: isDesktop ? 20 : 18.r,
      height: isDesktop ? 20 : 18.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? AppColors.primaryColor
            : AppColors.sandText.withValues(alpha: 0.2),
        border: isCurrent
            ? Border.all(color: AppColors.vipGoldStart, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '$stepNumber',
          style: TextStyles.customStyle(
            fontSize: isDesktop ? 10 : 9,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : AppColors.sandText,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(int fromStep, int currentStep, bool isDesktop) {
    final bool isPassed = currentStep > fromStep;

    return Container(
      width: isDesktop ? 24 : 16.w,
      height: isDesktop ? 2 : 2.h,
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 2 : 2.w),
      color: isPassed
          ? AppColors.primaryColor
          : AppColors.sandText.withValues(alpha: 0.2),
    );
  }

  Widget _buildBodyState(
    BuildContext context,
    ShippingReconciliationState state,
    bool isDesktop,
  ) {
    Widget content;

    if (state is ShippingReconciliationProcessingState) {
      content = LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 24.w,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: isDesktop ? 70 : 70.w,
                        height: isDesktop ? 70 : 70.h,
                        child: LoadingIndicator(
                          indicatorType: Indicator.ballSpinFadeLoader,
                          colors: [
                            AppColors.primaryColor,
                            AppColors.vipGoldStart,
                          ],
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 24 : 24.h),
                      Text(
                        state.message,
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 16 : 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isDesktop ? 12 : 10.h),
                      Text(
                        AppStrings.offlineProcessingHint.tr(),
                        style: TextStyles.customStyle(
                          fontSize: isDesktop ? 13 : 12,
                          color: AppColors.sandText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else if (state is ShippingReconciliationMappingReviewState) {
      content = const ColumnMappingStep();
    } else if (state is ShippingReconciliationSuccessState) {
      content = ReconciliationResultStep(successState: state);
    } else {
      // Default File Upload Step
      content = const FileUploadStep();
    }

    if (isDesktop) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: content,
        ),
      );
    }

    return content;
  }
}
