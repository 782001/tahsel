import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/currency/currency_service.dart';
import 'package:tahsel/core/services/currency/data/world_currencies.dart';
import 'package:tahsel/core/services/currency/domain/entities/currency_entity.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/toast/custom_toast.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';

class CurrencySelectionBottomSheet extends StatefulWidget {
  final CurrencyEntity? initialCurrency;
  final ValueChanged<CurrencyEntity>? onCurrencySelected;

  const CurrencySelectionBottomSheet({
    super.key,
    this.initialCurrency,
    this.onCurrencySelected,
  });

  static Future<CurrencyEntity?> show(
    BuildContext context, {
    CurrencyEntity? initialCurrency,
    ValueChanged<CurrencyEntity>? onCurrencySelected,
  }) {
    return showModalBottomSheet<CurrencyEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CurrencySelectionBottomSheet(
        initialCurrency: initialCurrency,
        onCurrencySelected: onCurrencySelected,
      ),
    );
  }

  @override
  State<CurrencySelectionBottomSheet> createState() =>
      _CurrencySelectionBottomSheetState();
}

class _CurrencySelectionBottomSheetState
    extends State<CurrencySelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CurrencyEntity> _filteredCurrencies = WorldCurrencies.allCurrencies;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredCurrencies = WorldCurrencies.search(_searchController.text);
    });
  }

  Future<void> _selectCurrency(CurrencyEntity currency) async {
    final isOffline = context.read<ConnectivityCubit>().state is ConnectivityDisconnected;
    if (isOffline) {
      showfailureToast(AppStrings.noInternetConnection.tr());
      return;
    }
    if (!mounted) return;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (widget.onCurrencySelected != null) {
      // Pop first to release navigator lock, then invoke callback
      nav.pop(currency);
      widget.onCurrencySelected!(currency);
      return;
    }

    await CurrencyService.instance.updateCurrency(currency);
    if (!mounted) return;
    nav.pop(currency);

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                AppStrings.currencyUpdatedSuccess.tr(),
                style: TextStyles.customStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveLayout.isDesktop(context);
    final currentLang = AppStrings.currentLang;
    final activeCurrency =
        widget.initialCurrency ?? CurrencyService.instance.currentCurrency;

    return Container(
      height: MediaQuery.of(context).size.height * (isDesktop ? 0.75 : 0.82),
      padding: EdgeInsets.only(
        left: isDesktop ? 24 : 20.w,
        right: isDesktop ? 24 : 20.w,
        top: isDesktop ? 16 : 14.h,
        bottom: isDesktop ? 20 : 16.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.disabledColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 16 : 14.h),

          // Smart Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.selectCurrency.tr(),
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 19 : 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${AppStrings.currencyLabel.tr()}: ${activeCurrency.getName(currentLang)} (${activeCurrency.getSymbol(currentLang)})',
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 12 : 12,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.stitchSurfaceHigh.withValues(
                    alpha: 0.5,
                  ),
                  shape: const CircleBorder(),
                ),
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.blackLight,
                  size: isDesktop ? 20 : 20,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 16 : 14.h),

          // Search Field with Result Count Badge
          TextField(
            controller: _searchController,
            cursorColor: AppColors.primaryColor,
            style: TextStyles.customStyle(
              fontSize: isDesktop ? 14 : 14,
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: AppStrings.searchCurrencyHint.tr(),
              hintStyle: TextStyles.customStyle(
                fontSize: isDesktop ? 13 : 13,
                color: AppColors.disabledColor,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.primaryColor,
                size: isDesktop ? 22 : 22,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${_filteredCurrencies.length}',
                      style: TextStyles.customStyle(
                        fontSize: isDesktop ? 11 : 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => _searchController.clear(),
                    ),
                  SizedBox(width: 8.w),
                ],
              ),
              filled: true,
              fillColor: AppColors.stitchSurfaceHigh.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 14 : 12.h),

          // Smart Currency Cards List
          Expanded(
            child: _filteredCurrencies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.disabledColor.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          AppStrings.noData.tr(),
                          style: TextStyles.customStyle(
                            fontSize: isDesktop ? 14 : 14,
                            color: AppColors.disabledColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredCurrencies.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: isDesktop ? 8 : 8.h),
                    itemBuilder: (context, index) {
                      final currency = _filteredCurrencies[index];
                      final isSelected = currency.code == activeCurrency.code;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectCurrency(currency),
                          borderRadius: BorderRadius.circular(16.r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.all(isDesktop ? 14 : 12.w),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryColor.withValues(
                                      alpha: 0.08,
                                    )
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.veryLightGrey,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Symbol Avatar Container
                                Container(
                                  width: isDesktop ? 46 : 44.w,
                                  height: isDesktop ? 46 : 44.w,
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [
                                              AppColors.primaryColor,
                                              AppColors.primaryColor.withValues(
                                                alpha: 0.85,
                                              ),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isSelected
                                        ? null
                                        : AppColors.stitchSurfaceHigh
                                              .withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primaryColor
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    currency.getSymbol(currentLang),
                                    style: TextStyles.customStyle(
                                      fontSize: isDesktop ? 15 : 15,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.black,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 14.w),

                                // Currency Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              currency.getName(currentLang),
                                              style: TextStyles.customStyle(
                                                fontSize: 15,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                color: isSelected
                                                    ? AppColors.primaryColor
                                                    : AppColors.black,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 2.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.primaryColor
                                                        .withValues(alpha: 0.12)
                                                  : AppColors.stitchSurfaceHigh
                                                        .withValues(alpha: 0.5),
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                            ),
                                            child: Text(
                                              currency.code,
                                              style: TextStyles.customStyle(
                                                fontSize: isDesktop ? 11 : 11,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? AppColors.primaryColor
                                                    : AppColors.blackLight,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 3.h),
                                      Text(
                                        '${currency.arabicSymbol}  •  ${currency.englishSymbol}  •  ${currentLang == "ar" ? currency.englishName : currency.arabicName}',
                                        style: TextStyles.customStyle(
                                          fontSize: isDesktop ? 12 : 12,
                                          color: AppColors.sandText,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Selection Checkmark Badge
                                if (isSelected) ...[
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.all(4.r),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
