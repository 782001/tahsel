import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/storage/cashhelper.dart';
import 'package:tahsel/core/storage/secure_storage_helper.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_state.dart';
import 'package:tahsel/features/my_debts/presentation/screens/unified_debts_screen.dart';
import 'package:tahsel/features/operation/presentation/screens/home_screen.dart';
import 'package:tahsel/features/reports/domain/usecases/cleanup_old_reports_usecase.dart';
import 'package:tahsel/features/reports/presentation/screens/reports_screen.dart';
import 'package:tahsel/features/settings/presentation/screens/settings_screen.dart';

class MainLayoutCubit extends Cubit<MainLayoutState> {
  final CleanupOldReportsUseCase cleanupOldReportsUseCase;
  final CashHelper cashHelper;
  final SecureStorageHelper secureStorage;
  final FirebaseFirestore firestore;

  MainLayoutCubit({
    required this.cleanupOldReportsUseCase,
    required this.cashHelper,
    required this.secureStorage,
    required this.firestore,
  }) : super(MainLayoutInitial()) {
    _init();
  }

  String _userType = AppStrings.cafe;
  String get userType => _userType;

  bool get isShop => _userType == AppStrings.shop;
  bool get isCafe => _userType == AppStrings.cafe;

  void _init() async {
    await _loadUserType();
    if (!isShop) {
      _initCleanup();
    }
  }

  Future<void> _loadUserType() async {
    final storedType = await secureStorage.getData(key: AppStrings.userTypeKey);
    if (storedType != null) {
      _userType = storedType;
      emit(MainLayoutUserTypeLoaded(_userType));
    } else {
      // Fallback: Fetch from Firestore if we have a current token
      final uid = AppStrings.userToken;
      if (uid.isNotEmpty) {
        try {
          final doc = await firestore.collection('users').doc(uid).get();
          if (doc.exists) {
            final type = doc.get(AppStrings.userTypeKey) ?? AppStrings.cafe;
            _userType = type;
            await secureStorage.saveData(
              key: AppStrings.userTypeKey,
              value: type,
            );
            emit(MainLayoutUserTypeLoaded(_userType));
          }
        } catch (e) {
          AppLogger.printMessage('Error fetching user type from Firestore: $e');
        }
      }
    }
  }

  void _initCleanup() async {
    await cleanupOldReportsUseCase();
  }

  int currentIndex = 0;

  List<Widget> get screens => [
    const HomeScreen(),
    const ExpensesScreen(),
    const UnifiedDebtsScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  void changeBottomNav(int index) {
    currentIndex = index;
    emit(MainLayoutChangeBottomNavIndex(currentIndex));
  }
}
