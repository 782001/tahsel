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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomerDebtsHeader(),
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
            ],
          ),
        ),
      ),
    );
  }
}
