import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/features/expenses/domain/usecases/delete_month_expenses_usecase.dart';
import 'package:tahsel/features/expenses/presentation/cubit/expense_cubit.dart';
import '../data/datasources/expense_remote_data_source.dart';
import '../data/repositories/expense_repository_impl.dart';
import '../domain/repositories/expense_repository.dart';
import '../domain/usecases/add_expense_usecase.dart';
import '../domain/usecases/calculate_expense_stats_usecase.dart';
import '../domain/usecases/get_expenses_usecase.dart';
import '../domain/usecases/get_monthly_expenses_usecase.dart';
import '../domain/usecases/get_expenses_by_month_usecase.dart';
import '../domain/usecases/delete_expense_usecase.dart';  
import '../domain/usecases/get_pending_expenses_usecase.dart';

Future<void> initExpense() async {
  // Cubit
  sl.registerLazySingleton(() => ExpenseCubit(
        addExpenseUseCase: sl(),
        getExpensesUseCase: sl(),
        getMonthlyExpensesUseCase: sl(),
        getExpensesByMonthUseCase: sl(),
        calculateStatsUseCase: sl(),
        deleteExpenseUseCase: sl(),
        deleteMonthExpensesUseCase: sl(),
        getPendingExpensesUseCase: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => AddExpenseUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetExpensesUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetMonthlyExpensesUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetExpensesByMonthUseCase(repository: sl()));
  sl.registerLazySingleton(() => CalculateExpenseStatsUseCase());
  sl.registerLazySingleton(() => DeleteExpenseUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMonthExpensesUseCase(sl()));
  sl.registerLazySingleton(() => GetPendingExpensesUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ExpenseRepository>(
      () => ExpenseRepositoryImpl(
            remoteDataSource: sl(),
            offlineSyncRepository: sl(),
            connectionChecker: sl(),
          ));

  // Data sources
  sl.registerLazySingleton<ExpenseRemoteDataSource>(
      () => ExpenseRemoteDataSourceImpl(firestore: sl()));

  // External
  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton(() => FirebaseFirestore.instance);
  }
}
