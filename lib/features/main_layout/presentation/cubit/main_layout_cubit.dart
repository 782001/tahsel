import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/features/customer_debts/presentation/screens/customer_debts_screen.dart';
import 'package:tahsel/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:tahsel/features/home/presentation/screens/home_screen.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_state.dart';
import 'package:tahsel/features/reports/presentation/screens/reports_screen.dart';
import 'package:tahsel/features/settings/presentation/screens/settings_screen.dart';

class MainLayoutCubit extends Cubit<MainLayoutState> {
  MainLayoutCubit() : super(MainLayoutInitial());

  int currentIndex = 0;

  List<Widget> bottomScreens = const [
    HomeScreen(),
    ExpensesScreen(),
    CustomerDebtsScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  void changeBottomNav(int index) {
    currentIndex = index;
    emit(MainLayoutChangeBottomNavIndex(currentIndex));
  }
}
