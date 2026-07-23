import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

import '../../domain/entities/inventory_category_entity.dart';
import '../cubits/inventory_categories_cubit.dart';
import '../widgets/add_edit_category_dialog.dart';
import '../widgets/inventory_empty_state.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InventoryCategoriesCubit>().fetchCategories();
  }

  void _openAddEditCategoryDialog([InventoryCategoryEntity? category]) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditCategoryDialog(
        category: category,
        onSave: (savedCategory) {
          context
              .read<InventoryCategoriesCubit>()
              .saveCategory(savedCategory)
              .then((success) {
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.categorySavedSuccess.tr()),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              });
        },
      ),
    );
  }

  void _confirmDeleteCategory(
    BuildContext context,
    InventoryCategoryEntity cat,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          AppStrings.confirmDelete.tr(),
          style: TextStyles.customStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.blackReal,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppStrings.delete.tr()} "${cat.name}"؟',
              style: TextStyles.customStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.blackReal,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppStrings.deleteCategoryWarning.tr(),
              style: TextStyles.customStyle(
                fontSize: 13,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              AppStrings.cancel.tr(),
              style: TextStyles.customStyle(
                fontSize: 14,
                color: AppColors.sandText,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deleteRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<InventoryCategoriesCubit>().deleteCategory(cat.id);
            },
            child: Text(
              AppStrings.delete.tr(),
              style: TextStyles.customStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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

    return Scaffold(
      backgroundColor: AppColors.scafoldBackGround,
      appBar: AppBar(
        backgroundColor: AppColors.scafoldBackGround,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          AppStrings.inventoryCategories.tr(),
          style: TextStyles.customStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryColor,
        onPressed: () => _openAddEditCategoryDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          AppStrings.addCategory.tr(),
          style: TextStyles.customStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 800 : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 24 : 16.w),
              child:
                  BlocBuilder<
                    InventoryCategoriesCubit,
                    InventoryCategoriesState
                  >(
                    builder: (context, state) {
                      if (state is InventoryCategoriesLoading) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                            strokeWidth: 4,
                          ),
                        );
                      }
                      if (state is InventoryCategoriesLoaded) {
                        final categories = state.categories;

                        if (categories.isEmpty) {
                          return InventoryEmptyState(
                            icon: Icons.category_outlined,
                            title: AppStrings.noCategoriesFound.tr(),
                            description: AppStrings.emptyCategoriesDesc.tr(),
                            actionLabel: AppStrings.addCategory.tr(),
                            onAction: () => _openAddEditCategoryDialog(),
                          );
                        }

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: categories.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: isDesktop ? 12 : 12.h),
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            return Container(
                              padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  isDesktop ? 14 : 14.r,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors
                                        .inventoryCategoryBrown
                                        .withValues(alpha: 0.12),
                                    radius: isDesktop ? 22 : 22.r,
                                    child: Icon(
                                      Icons.category_rounded,
                                      color: AppColors.inventoryCategoryBrown,
                                    ),
                                  ),
                                  SizedBox(width: isDesktop ? 16 : 16.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat.name,
                                          style: TextStyles.customStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.blackReal,
                                          ),
                                        ),
                                        if (cat.description != null &&
                                            cat.description!.isNotEmpty) ...[
                                          SizedBox(height: isDesktop ? 4 : 4.h),
                                          Text(
                                            cat.description!,
                                            style: TextStyles.customStyle(
                                              fontSize: 13,
                                              color: AppColors.sandText,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_rounded,
                                      color: AppColors.primaryColor,
                                    ),
                                    onPressed: () =>
                                        _openAddEditCategoryDialog(cat),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: AppColors.deleteRed,
                                    ),
                                    onPressed: () =>
                                        _confirmDeleteCategory(context, cat),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
