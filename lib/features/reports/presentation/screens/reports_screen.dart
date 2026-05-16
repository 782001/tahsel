import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/reports/presentation/cubit/reports_cubit/reports_cubit.dart';
import 'package:tahsel/features/reports/presentation/cubit/reports_cubit/reports_state.dart';
import 'package:tahsel/features/reports/presentation/widgets/reports_view.dart';

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
