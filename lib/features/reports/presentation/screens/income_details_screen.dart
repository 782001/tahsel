import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/features/standard_features/localization/presentation/cubit/locale_cubit.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import '../cubit/income_details_cubit.dart';
import '../../../operation/domain/entities/operation_entity.dart';

class IncomeDetailsScreen extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String? type; // AppStrings.shop, AppStrings.playStation, or null

  const IncomeDetailsScreen({
    Key? key,
    required this.startDate,
    required this.endDate,
    this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<IncomeDetailsCubit>()..fetchIncomeDetails(startDate, endDate, type: type),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _getScreenTitle(context, type),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<IncomeDetailsCubit, IncomeDetailsState>(
          builder: (context, state) {
            if (state is IncomeDetailsLoading) {
              return Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
            } else if (state is IncomeDetailsError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              );
            } else if (state is IncomeDetailsLoaded) {
              if (state.operations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.insert_chart_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.noIncomeData.tr(),
                        style: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primaryColor,
                onRefresh: () => context.read<IncomeDetailsCubit>().fetchIncomeDetails(startDate, endDate, type: type),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.operations.length,
                  itemBuilder: (context, index) {
                    return _buildOperationCard(context, state.operations[index]);
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  String _getScreenTitle(BuildContext context, String? type) {
    if (type == null) {
      return AppStrings.totalIncomeDetails.tr();
    } else if (type.toLowerCase() == AppStrings.shop.toLowerCase()) {
      return AppStrings.cafeIncomeDetails.tr();
    } else if (type.toLowerCase() == AppStrings.playStation.toLowerCase()) {
      return AppStrings.playstationIncomeDetails.tr();
    }
    return AppStrings.incomeDetails.tr();
  }

  Widget _buildOperationCard(BuildContext context, OperationEntity operation) {
    final bool isArabic = context.read<LocaleCubit>().state.locale.languageCode == 'ar';
    final DateFormat timeFormat = isArabic ? DateFormat('hh:mm a', 'ar') : DateFormat('hh:mm a', 'en');
    final DateFormat dateFormat = isArabic ? DateFormat('yyyy/MM/dd', 'ar') : DateFormat('yyyy/MM/dd', 'en');

    final bool isPlaystation = operation.type.toLowerCase() == AppStrings.playStation.toLowerCase();
    
    String subtitleText = '';
    if (isPlaystation) {
      if (operation.subType == 'time') {
        final durationStr = AppStrings.durationMins.tr().replaceAll('{mins}', '${operation.durationMinutes ?? 0}');
        subtitleText = "${AppStrings.psSessionTime.tr()} - $durationStr";
      } else {
        subtitleText = "${AppStrings.psSessionTurn.tr()} - ${operation.turnCount ?? 0} ادوار";
      }
    } else {
      subtitleText = operation.productName ?? AppStrings.shop.tr();
    }

    final String customerName = (operation.customerName != null && operation.customerName!.isNotEmpty) 
        ? operation.customerName! 
        : AppStrings.walkingCustomer.tr();

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  "${operation.totalAmount.toStringAsFixed(0)} ${AppStrings.currencyEgp.tr()}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isPlaystation ? Icons.sports_esports : Icons.local_cafe,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subtitleText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      operation.timestamp != null ? dateFormat.format(operation.timestamp!) : 'N/A',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      operation.timestamp != null ? timeFormat.format(operation.timestamp!) : 'N/A',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
