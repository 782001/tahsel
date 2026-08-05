import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/styles.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/entities/column_concept.dart';
import '../../domain/entities/column_mapping_entity.dart';
import '../cubit/shipping_reconciliation_cubit.dart';
import '../cubit/shipping_reconciliation_state.dart';
import 'column_mapping_card.dart';

class ColumnMappingStep extends StatefulWidget {
  const ColumnMappingStep({super.key});

  @override
  State<ColumnMappingStep> createState() => _ColumnMappingStepState();
}

class _ColumnMappingStepState extends State<ColumnMappingStep>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocBuilder<
      ShippingReconciliationCubit,
      ShippingReconciliationState
    >(
      builder: (context, state) {
        FileColumnMappingEntity? internalMapping;
        FileColumnMappingEntity? shippingMapping;

        if (state is ShippingReconciliationFilesLoaded) {
          internalMapping = state.internalMapping;
          shippingMapping = state.shippingMapping;
        } else if (state is ShippingReconciliationMappingReviewState) {
          internalMapping = state.internalMapping;
          shippingMapping = state.shippingMapping;
        }

        if (internalMapping == null || shippingMapping == null) {
          return Center(child: Text(AppStrings.pleaseUploadBothFiles.tr()));
        }

        return Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 600 : double.infinity,
                ),
                child: _buildTabSelector(
                  context: context,
                  selectedIndex: _tabController.index,
                  onTabChanged: (index) {
                    _tabController.animateTo(index);
                    setState(() {});
                  },
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMappingForm(
                    context: context,
                    mapping: internalMapping,
                    isInternal: true,
                  ),
                  _buildMappingForm(
                    context: context,
                    mapping: shippingMapping,
                    isInternal: false,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      context
                          .read<ShippingReconciliationCubit>()
                          .backToFilesStep();
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    label: Text(AppStrings.changeFile.tr()),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48.h),
                      foregroundColor: AppColors.primaryColor,
                      side: BorderSide(color: AppColors.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<ShippingReconciliationCubit>()
                          .startReconciliation();
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: Text(AppStrings.saveAndReconcile.tr()),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48.h),
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabSelector({
    required BuildContext context,
    required int selectedIndex,
    required Function(int index) onTabChanged,
  }) {
    final bool isDesktop = ResponsiveLayout.isDesktop(context);
    final tabs = [
      AppStrings.internalFileColumns.tr(),
      AppStrings.shippingFileColumns.tr(),
    ];

    return Container(
      height: isDesktop ? 50 : 46.h,
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 16.w,
        vertical: isDesktop ? 10 : 10.h,
      ),
      padding: EdgeInsets.all(isDesktop ? 4 : 4.r),
      decoration: BoxDecoration(
        color: AppColors.stitchSurfaceLow,
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tabWidth = constraints.maxWidth / tabs.length;

          return Stack(
            children: [
              // Animated Indicator
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: AlignmentDirectional(
                  -1.0 + (selectedIndex * 2 / (tabs.length - 1)),
                  0,
                ),
                child: Container(
                  width: tabWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Interaction Layer
              Row(
                children: List.generate(
                  tabs.length,
                  (index) => Expanded(
                    child: GestureDetector(
                      onTap: () => onTabChanged(index),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          tabs[index],
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 13 : 13,
                            fontWeight: selectedIndex == index
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: selectedIndex == index
                                ? AppColors.primaryColor
                                : AppColors.blackLight.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMappingForm({
    required BuildContext context,
    required FileColumnMappingEntity mapping,
    required bool isInternal,
  }) {
    final cubit = context.read<ShippingReconciliationCubit>();
    final state = cubit.state;

    final sampleRows = isInternal
        ? (state is ShippingReconciliationFilesLoaded
              ? state.internalFile?.rows
              : null)
        : (state is ShippingReconciliationFilesLoaded
              ? state.shippingFile?.rows
              : null);

    final conceptsToDisplay = isInternal
        ? [
            ColumnConcept.orderNumber,
            ColumnConcept.customerName,
            ColumnConcept.phone,
            ColumnConcept.requiredAmount,
            ColumnConcept.product,
            ColumnConcept.governorate,
            ColumnConcept.address,
            ColumnConcept.date,
          ]
        : [
            ColumnConcept.orderNumber,
            ColumnConcept.customerName,
            ColumnConcept.phone,
            ColumnConcept.collectedAmount,
            ColumnConcept.expectedAmount,
            ColumnConcept.shippingStatus,
            ColumnConcept.collectionStatus,
            ColumnConcept.returnStatus,
            ColumnConcept.product,
          ];

    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ListView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16.r),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          '${AppStrings.confirmMappingFor.tr()} (${mapping.fileName}):',
          style: TextStyles.customStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.blackReal,
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 12.h),

        ...conceptsToDisplay.map((concept) {
          final mappedColIndex = mapping.getIndex(concept);

          return ColumnMappingCard(
            concept: concept,
            mappedColIndex: mappedColIndex,
            rawHeaders: mapping.rawHeaders,
            sampleRows: sampleRows,
            onChanged: (newColIndex) {
              if (isInternal) {
                cubit.updateInternalMapping(concept, newColIndex);
              } else {
                cubit.updateShippingMapping(concept, newColIndex);
              }
            },
          );
        }),
      ],
    );
  }
}
