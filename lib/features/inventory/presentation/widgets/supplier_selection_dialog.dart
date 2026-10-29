import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/permission_guard.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import '../../domain/entities/inventory_supplier_entity.dart';

class SupplierSelectionDialog extends StatefulWidget {
  final List<InventorySupplierEntity> suppliers;
  final InventorySupplierEntity? selectedSupplier;
  final ValueChanged<InventorySupplierEntity> onSelected;
  final VoidCallback? onCleared;
  final ValueChanged<String?>? onAddNewSupplier;

  const SupplierSelectionDialog({
    super.key,
    required this.suppliers,
    this.selectedSupplier,
    required this.onSelected,
    this.onCleared,
    this.onAddNewSupplier,
  });

  @override
  State<SupplierSelectionDialog> createState() =>
      _SupplierSelectionDialogState();
}

class _SupplierSelectionDialogState extends State<SupplierSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InventorySupplierEntity> get _filteredSuppliers {
    if (_searchQuery.trim().isEmpty) {
      return widget.suppliers;
    }
    final q = _searchQuery.trim().toLowerCase();
    return widget.suppliers.where((s) {
      final nameMatches = s.name.toLowerCase().contains(q);
      final phoneMatches = s.phone.toLowerCase().contains(q);
      final companyMatches = s.companyName?.toLowerCase().contains(q) ?? false;
      final addressMatches = s.address.toLowerCase().contains(q);
      return nameMatches || phoneMatches || companyMatches || addressMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final filtered = _filteredSuppliers;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 16.r),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 16.w,
        vertical: isDesktop ? 40 : 24.h,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 540 : double.infinity,
          maxHeight: isDesktop
              ? 640
              : MediaQuery.of(context).size.height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header
            _buildHeader(isDesktop),

            // 2. Search & Quick Actions Bar
            _buildSearchBar(isDesktop),

            // 3. Suppliers List
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(isDesktop)
                  : _buildSuppliersList(filtered, isDesktop),
            ),

            // 4. Bottom Footer (Clear Selection & Cancel)
            _buildFooter(isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20 : 16.w,
        vertical: isDesktop ? 14 : 12.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.scafoldBackGround,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isDesktop ? 16 : 16.r),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 8 : 8.r),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.business_rounded,
              color: AppColors.primaryColor,
              size: isDesktop ? 20 : 18,
            ),
          ),
          SizedBox(width: isDesktop ? 12 : 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      AppStrings.supplier.tr(),
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 16 : 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackReal,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '${widget.suppliers.length}',
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  AppStrings.selectSupplierDialogSubtitle.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 11,
                    color: AppColors.sandText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.sandText,
              size: isDesktop ? 22 : 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 14 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.dividerColor.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.scafoldBackGround,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.dividerColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: false,
                    style: TextStyles.customStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blackReal,
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchSupplierPlaceholder.tr(),
                      hintStyle: TextStyles.customStyle(
                        fontSize: 12,
                        color: AppColors.blackLight.withValues(alpha: 0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              color: AppColors.sandText,
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 14 : 12.w,
                        vertical: isDesktop ? 12 : 10.h,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                  ),
                ),
              ),
              if (widget.onAddNewSupplier != null) ...[
                SizedBox(width: isDesktop ? 8 : 8.w),
                PermissionGuard(
                  permission: AppPermissions.inventoryManageSuppliers,
                  child: InkWell(
                    onTap: () {
                      final name = _searchQuery.trim();
                      widget.onAddNewSupplier?.call(
                        name.isNotEmpty ? name : null,
                      );
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      height: 44,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 12 : 10.w,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_alt_1_rounded,
                            color: AppColors.primaryColor,
                            size: 18,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            AppStrings.addSupplier.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 11.5,
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliersList(
    List<InventorySupplierEntity> suppliers,
    bool isDesktop,
  ) {
    return ListView.separated(
      padding: EdgeInsets.all(isDesktop ? 14 : 12.w),
      physics: const BouncingScrollPhysics(),
      itemCount: suppliers.length,
      separatorBuilder: (_, __) => SizedBox(height: isDesktop ? 8 : 8.h),
      itemBuilder: (context, index) {
        final supplier = suppliers[index];
        final bool isSelected = widget.selectedSupplier?.id == supplier.id;

        return InkWell(
          onTap: () {
            widget.onSelected(supplier);
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(12.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.all(isDesktop ? 12 : 10.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryColor.withValues(alpha: 0.08)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.dividerColor.withValues(alpha: 0.6),
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Avatar / Initials
                Container(
                  width: isDesktop ? 44 : 40,
                  height: isDesktop ? 44 : 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.scafoldBackGround,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      supplier.name.isNotEmpty
                          ? supplier.name.characters.first.toUpperCase()
                          : 'م',
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isDesktop ? 12 : 10.w),

                // Name & details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              supplier.name,
                              style: TextStyles.customStyle(
                                fontSize: isDesktop ? 14 : 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.blackReal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (supplier.companyName != null &&
                              supplier.companyName!.trim().isNotEmpty) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.scafoldBackGround,
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: AppColors.dividerColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                supplier.companyName!,
                                style: TextStyles.customStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.sandText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          if (supplier.phone.isNotEmpty) ...[
                            Icon(
                              Icons.phone_outlined,
                              size: 13,
                              color: AppColors.sandText,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              supplier.phone,
                              style: TextStyles.customStyle(
                                fontSize: 11,
                                color: AppColors.sandText,
                              ),
                            ),
                            if (supplier.address.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                ),
                                child: Text(
                                  '•',
                                  style: TextStyle(color: AppColors.sandText),
                                ),
                              ),
                          ],
                          if (supplier.address.isNotEmpty)
                            Flexible(
                              child: Text(
                                supplier.address,
                                style: TextStyles.customStyle(
                                  fontSize: 11,
                                  color: AppColors.sandText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (supplier.phone.isEmpty &&
                              supplier.address.isEmpty)
                            Text(
                              AppStrings.registeredSupplier.tr(),
                              style: TextStyles.customStyle(
                                fontSize: 11,
                                color: AppColors.sandText,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Trailing selection checkmark
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryColor,
                          size: 15,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          AppStrings.currentlySelected.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.sandText.withValues(alpha: 0.6),
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDesktop) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.scafoldBackGround,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_outlined,
                size: 40,
                color: AppColors.sandText,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              _searchQuery.isNotEmpty
                  ? '${AppStrings.noSupplierMatches.tr()} "$_searchQuery"'
                  : AppStrings.noSuppliersRegisteredYet.tr(),
              style: TextStyles.customStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.blackReal,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              _searchQuery.isNotEmpty
                  ? AppStrings.addSupplierWithThisNameHint.tr()
                  : AppStrings.addFirstSupplierHint.tr(),
              style: TextStyles.customStyle(
                fontSize: 11.5,
                color: AppColors.sandText,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.onAddNewSupplier != null) ...[
              SizedBox(height: 14.h),
              PermissionGuard(
                permission: AppPermissions.inventoryManageSuppliers,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final name = _searchQuery.trim();
                    widget.onAddNewSupplier?.call(
                      name.isNotEmpty ? name : null,
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    _searchQuery.isNotEmpty
                        ? '${AppStrings.addAsNewSupplier.tr()} "$_searchQuery"'
                        : AppStrings.addSupplier.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 16 : 14.w,
                      vertical: isDesktop ? 10 : 8.h,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 14.w,
        vertical: isDesktop ? 10 : 10.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.scafoldBackGround,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(isDesktop ? 16 : 16.r),
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.selectedSupplier != null && widget.onCleared != null)
            TextButton.icon(
              onPressed: () {
                widget.onCleared?.call();
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.clear_rounded,
                size: 16,
                color: AppColors.error,
              ),
              label: Text(
                AppStrings.clearSupplierSelection.tr(),
                style: TextStyles.customStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppStrings.cancel.tr(),
              style: TextStyles.customStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.sandText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

