import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/customer_debts_header.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/customer_debts_list.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../shared/widgets/text_fields/custom_search_field.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/services/injection_container.dart';
import '../../../debt/presentation/cubit/debt_cubit.dart';

import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';

class CustomerDebtsScreen extends StatefulWidget {
  const CustomerDebtsScreen({super.key});

  @override
  State<CustomerDebtsScreen> createState() => _CustomerDebtsScreenState();
}

class _CustomerDebtsScreenState extends State<CustomerDebtsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<DebtCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        body: SafeArea(
          child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
            builder: (context, connectivityState) {
              final bool isOffline = connectivityState is ConnectivityDisconnected;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomerDebtsHeader(),
                  if (!isOffline) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: CustomSearchField(
                        controller: _searchController,
                        hintText: AppStrings.searchCustomer.tr(),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: CustomerDebtsList(searchQuery: _searchQuery),
                    ),
                  ] else
                    Expanded(
                      child: NoInternetView(
                        onRetry: () {
                          context.read<ConnectivityCubit>().checkConnectivity();
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
