import 'package:flutter/material.dart';
import 'package:tahsel/features/customer_debts/data/models/debt_item_model.dart';
import 'package:tahsel/features/debt/presentation/screens/customer_global_payments_screen.dart';
import 'package:tahsel/features/debt/presentation/screens/monthly_collected_screen.dart';
import 'package:tahsel/features/debt/presentation/screens/monthly_collected_transactions_screen.dart';
import 'package:tahsel/features/debt/domain/entities/monthly_collected_amount.dart';
import 'package:tahsel/features/reports/presentation/cubit/reports_cubit/reports_cubit.dart';
import 'package:tahsel/features/standard_features/security/presentation/screens/security_warning_screen.dart';
import 'package:tahsel/features/splash/splash_screen.dart';
import 'package:tahsel/features/main_layout/presentation/screens/main_layout_screen.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import 'package:tahsel/features/auth/presentation/screens/login_screen.dart';
import 'package:tahsel/core/services/injection_container.dart' as di;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';
import 'package:tahsel/features/expenses/presentation/screens/add_expense_screen.dart';
import 'package:tahsel/features/reports/presentation/screens/income_details_screen.dart';
import 'package:tahsel/features/debt/presentation/screens/debt_details_report_screen.dart';
import 'package:tahsel/features/debt/presentation/cubit/debt_details/debt_details_cubit.dart';
import 'package:tahsel/features/debt/presentation/cubit/global_payments/global_payments_cubit.dart';
import 'package:tahsel/features/customer/presentation/screens/customers_list_screen.dart';
import 'package:tahsel/features/customer/presentation/screens/customer_report_details_screen.dart';
import 'package:tahsel/features/my_debts/presentation/screens/add_my_debt_screen.dart';
import 'package:tahsel/features/my_debts/presentation/screens/my_debt_details_screen.dart';
import 'package:tahsel/features/my_debts/presentation/screens/my_debt_details_report_screen.dart';
import 'package:tahsel/features/my_debts/domain/entities/my_debt_person_entity.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_cubit.dart';
import 'package:tahsel/features/my_debts/presentation/cubit/my_debt_details_report_cubit.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String mainLayout = '/main-layout';
  static const String login = '/login';
  static const String securityWarning = '/security-warning';
  static const String addExpense = '/add-expense';
  static const String incomeDetails = '/income-details';
  static const String debtDetails = '/debt-details';
  static const String customerGlobalPayments = '/customer-global-payments';
  static const String customersList = '/customers-list';
  static const String customerReportDetails = '/customer-report-details';
  static const String addMyDebt = '/add-my-debt';
  static const String myDebtDetails = '/my-debt-details';
  static const String myDebtDetailsReport = '/my-debt-details-report';
  static const String monthlyCollected = '/monthly-collected';
  static const String monthlyCollectedTransactions = '/monthly-collected-transactions';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case mainLayout:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => di.sl<MainLayoutCubit>()),
              BlocProvider.value(value: di.sl<ReportsCubit>()),
            ],
            child: const MainLayoutScreen(),
          ),
        );
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case securityWarning:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SecurityWarningScreen(
            isRooted: args?['isRooted'] ?? false,
            isDevMode: args?['isDevMode'] ?? false,
          ),
        );
      case addExpense:
        return MaterialPageRoute(builder: (_) => const AddExpenseScreen());
      case incomeDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => IncomeDetailsScreen(
            startDate: args['startDate'] as DateTime,
            endDate: args['endDate'] as DateTime,
            period: args['period'] as String,
            isShop: args['isShop'] as bool,
            type: args['type'] as String?,
          ),
        );
      case debtDetails:
        final debtId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => di.sl<DebtDetailsCubit>(),
            child: DebtDetailsReportScreen(debtId: debtId),
          ),
        );
      case customerGlobalPayments:
        final customerDetail = settings.arguments as CustomerDebtDetail;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => di.sl<GlobalPaymentsCubit>(),
            child: CustomerGlobalPaymentsScreen(customerDetail: customerDetail),
          ),
        );
      case customersList:
        final uid = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => CustomersListScreen(uid: uid));
      case customerReportDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CustomerReportDetailsScreen(
            uid: args['uid'],
            customerName: args['customerName'],
          ),
        );
      case addMyDebt:
        return MaterialPageRoute(builder: (_) => const AddMyDebtScreen());
      case myDebtDetails:
        final person = settings.arguments as MyDebtPersonEntity;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => di.sl<MyDebtDetailsCubit>(),
            child: MyDebtDetailsScreen(person: person),
          ),
        );
      case myDebtDetailsReport:
        final debtId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => di.sl<MyDebtDetailsReportCubit>(),
            child: MyDebtDetailsReportScreen(debtId: debtId),
          ),
        );
      case monthlyCollected:
        final uid = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => MonthlyCollectedScreen(uid: uid),
        );
      case monthlyCollectedTransactions:
        final data = settings.arguments as MonthlyCollectedAmount;
        return MaterialPageRoute(
          builder: (_) => MonthlyCollectedTransactionsScreen(monthlyData: data),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: TextWidget('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (_) => const SplashScreen(),
      mainLayout: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => di.sl<MainLayoutCubit>()),
          BlocProvider.value(value: di.sl<ReportsCubit>()),
        ],
        child: const MainLayoutScreen(),
      ),
      login: (_) => const LoginScreen(),
      securityWarning: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return SecurityWarningScreen(
          isRooted: args?['isRooted'] ?? false,
          isDevMode: args?['isDevMode'] ?? false,
        );
      },
      addExpense: (_) => const AddExpenseScreen(),
    };
  }
}
