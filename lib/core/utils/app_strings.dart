import 'package:firebase_auth/firebase_auth.dart';
import 'package:tahsel/core/services/injection_container.dart';

class AppStrings {
  static const String noRouteFound = 'No Route Found';
  static const String cachedRandomQuote = 'CACHED_RANDOM_QUOTE';
  static const String contentType = 'Content-Type';
  static const String applicationJson = 'application/json';
  static const String serverFailure = 'Server Failure';
  static const String cacheFailure = 'Cache Failure';
  static const String unexpectedError = 'Unexpected Error';
  static const String arabicCode = "ar";
  static const String englishCode = "en";
  static const String locale = "locale";

  // Auth Screen
  static const String login = "login";
  static const String noData = "no_data";
  static String currentLang = "ar";
  static String get userToken =>
      sl<FirebaseAuth>().currentUser?.uid ?? '';

  ///-----------------------------
  ///-----------------------------
  ///---------Language-------------

  static const String language = "language";
  static String no_data = "no_data";
  static String sorry_no_data = "sorry_no_data";
  static const String swipe_down = "swipe_down";
  static const String download_failed = "download_failed";
  static const String slide_to_load_more = "slide_to_load_more";

  // Security Warning Screen
  static const String securityWarningTitle = "security_warning_title";
  static const String securityWarningDescription =
      "security_warning_description";
  static const String securityWarningRootedTitle =
      "security_warning_rooted_title";
  static const String securityWarningRootedSubtitle =
      "security_warning_rooted_subtitle";
  static const String securityWarningDevModeTitle =
      "security_warning_dev_mode_title";
  static const String securityWarningDevModeSubtitle =
      "security_warning_dev_mode_subtitle";
  static const String securityWarningFooter = "security_warning_footer";

  // Error Screen
  static const String errorScreenTitle = "error_screen_title";
  static const String errorScreenDetailsLabel = "error_screen_details_label";
  static const String errorScreenGoBackButton = "error_screen_go_back_button";

  // Settings Screen
  static const String settings = "settings";
  static const String changeLanguage = "change_language";
  static const String changeLanguageDesc = "change_language_desc";
  static const String arabic = "arabic";
  static const String arabicDesc = "arabic_desc";
  static const String english = "english";
  static const String englishDesc = "english_desc";
  static const String languageChangeInfo = "language_change_info";

  // Expenses Screen
  static const String expenses = "expenses";
  static const String addExpense = "add_expense";
  static const String addNewExpense = "add_new_expense";
  static const String amountLabel = "amount_label";
  static const String expenseNameLabel = "expense_name_label";
  static const String descriptionLabel = "description_label";
  static const String dateLabel = "date_label";
  static const String expenseNamePlaceholder = "expense_name_placeholder";
  static const String descriptionPlaceholder = "description_placeholder";
  static const String dashboard = "dashboard";
  static const String totalMonthlyExpenses = "total_monthly_expenses";
  static const String totalExpensesThisMonth = "total_expenses_this_month";
  static const String expenseIncreaseHint = "expense_increase_hint";
  static const String allExpenses = "all_expenses";
  static const String noPreviousMonths = "no_previous_months";
  static const String supplies = "supplies";
  static const String operations = "operations";
  static const String employees = "employees";
  static const String rents = "rents";
  static const String salaries = "salaries";
  static const String payrollDesc = "payroll_desc";
  static const String rent = "rent";
  static const String electricityBill = "electricity_bill";
  static const String mainOfficeServices = "main_office_services";

  // Customer Debts Screen
  static const String customerDebts = "customer_debts";
  static const String customerDebtsDesc = "customer_debts_desc";
  static const String searchCustomer = "search_customer";
  static const String partialPayment = "partial_payment";
  static const String amountPaid = "amount_paid";
  static const String currencyEgp = "currency_egp";
  static const String confirm = "confirm";
  static const String cancel = "cancel";
  static const String partialPayLabel = "partial_pay_label";
  static const String fullPaymentLabel = "full_payment_label";
  static const String lastTransactionPrefix = "last_transaction_prefix";
  // Debt status labels
  static const String debtStatusOverdue = "debt_status_overdue";
  static const String debtStatusBalance = "debt_status_balance";
  static const String debtStatusCritical = "debt_status_critical";
  static const String debtStatusMinor = "debt_status_minor";
  static const String transactionCount = "transaction_count";
  static const String requiredField = "required_field";
  static const String invalidValue = "invalid_value";
  static const String paymentExceedsRemaining = "payment_exceeds_remaining";
  static const String paymentSuccess = "payment_success";
  static const String fullSettlement = "full_settlement";

  // General Nav
  static const String home = "home";
  static const String reports = "reports";

  // Login Screen
  static const String financialEngineer = "financial_engineer";
  static const String loginSubtitle = "login_subtitle";
  static const String welcomeBack = "welcome_back";
  static const String emailAddress = "email_address";
  static const String password = "password";
  static const String contactManager = "contact_manager";
  static const String noAccount = "no_account";
  static const String noCustomerDebts = "no_customer_debts";
  static const String validationEmailRequired = "validation_email_required";
  static const String validationEmailInvalid = "validation_email_invalid";
  static const String validationPasswordRequired = "validation_password_required";
  static const String validationPasswordLength = "validation_password_length";
  static const String helpCenter = "help_center";
  static const String termsOfService = "terms_of_service";
  static const String privacyPolicy = "privacy_policy";
  static const String appearance = "appearance";
  static const String lightMode = "light_mode";
  static const String darkMode = "dark_mode";
  static const String account = "account";
  static const String profile = "profile";
  static const String notifications = "notifications";
  static const String security = "security";
  static const String support = "support";
  static const String logout = "logout";

  // Quick Add Feature
  static const String quickAdd = "quick_add";
  static const String playStation = "playstation";
  static const String shop = "shop";
  static const String byTime = "by_time";
  static const String byTurn = "by_turn";
  static const String customerName = "customer_name";
  static const String paidAmount = "paid_amount";
  static const String totalDueLabel = "total_due_label";
  static const String confirmOperation = "confirm_operation";
  static const String productName = "product_name";
  static const String remainingDebt = "remaining_debt";
  static const String pricePerHour = "price_per_hour";
  static const String pricePerTurn = "price_per_turn";
  static const String turnCount = "turn_count";
  static const String timeDuration = "time_duration";
  static const String customerNameHint = "customer_name_hint";
  static const String productNameHint = "product_name_hint";
  static const String quickAddDesc = "quick_add_desc";
  static const String operationSuccess = "operation_success";
  static const String operationFailed = "operation_failed";
  static const String userNotFound = "user_not_found";
  static const String validationFieldRequired = "validation_field_required";
  static const String validationInvalidAmount = "validation_invalid_amount";
  static const String validationCustomerNameRequired = "validation_customer_name_required";
  static const String validationProductNameRequired = "validation_product_name_required";
  static const String validationSessionRequired = "validation_session_required";
  static const String paidFull = "paid_full";
  // Storage Keys
  static const String hourlyRateKey = "hourly_rate_key";
  static const String slotRateKey = "slot_rate_key";

  // Reports Screen
  static const String daily = "daily";
  static const String weekly = "weekly";
  static const String monthly = "monthly";
  static const String netProfit = "net_profit";
  static const String totalIncome = "total_income";
  static const String totalExpenses = "total_expenses";
  static const String activityDetails = "activity_details";
  static const String operationalMargin = "operational_margin";
  static const String cafeIncome = "cafe_income";
  static const String playstationIncome = "playstation_income";
  static const String debts = "debts";
  static const String activeSessions = "active_sessions";
  static const String comparisonLastWeek = "comparison_last_week";
  static const String comparisonYesterday = "comparison_yesterday";
  static const String comparisonLastMonth = "comparison_last_month";
  static const String withinBudget = "within_budget";
  static const String alert = "alert";
  static const String delete = "delete";
  static const String confirmDeleteTitle = "confirm_delete_title";
  static const String confirmDeleteMessage = "confirm_delete_message";
  static const String confirmDeleteMonthMessage = "confirm_delete_month_message";
  static const String deleteSuccess = "delete_success";
}
