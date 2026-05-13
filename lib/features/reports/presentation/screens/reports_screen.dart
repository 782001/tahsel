import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/navigator_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/customer_debts/presentation/widgets/skeletons/customer_debt_skeleton.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import 'package:tahsel/features/reports/domain/entities/profit_insight.dart';
import 'package:tahsel/features/reports/presentation/cubit/reports_cubit/reports_cubit.dart';
import 'package:tahsel/features/reports/presentation/cubit/reports_cubit/reports_state.dart';
import 'package:tahsel/features/reports/presentation/widgets/build_report_insight_detail_row.dart';
import 'package:tahsel/features/reports/presentation/widgets/profit_insight_ui_extension.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_dashboard_card.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_net_profit_card.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_operational_margin_card.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_time_range_selector.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_view.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/routes/app_routes.dart';
import 'package:tahsel/shared/widgets/no_internet_view.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<ReportsCubit>();
    if (cubit.state is ReportsInitial) {
      cubit.fetchToday();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const ReportsView();
  }
}

