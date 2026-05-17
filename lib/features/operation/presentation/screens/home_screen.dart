import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/contact_service.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/storage/cashhelper.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_cubit.dart';
import 'package:tahsel/features/main_layout/presentation/cubit/main_layout_state.dart';
import 'package:tahsel/features/operation/presentation/widgets/quick_add_mode_selector.dart';
import 'package:tahsel/features/operation/presentation/widgets/quick_add_shop_form.dart';
import 'package:tahsel/features/operation/presentation/widgets/quick_add_sub_tab_header.dart';
import 'package:tahsel/features/operation/presentation/widgets/quick_add_summary_card.dart';
import 'package:tahsel/features/operation/presentation/widgets/quick_add_time_form.dart';
import 'package:tahsel/features/operation/presentation/widgets/quick_add_turn_form.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/buttons/quick_action_button.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

import '../../../customer/presentation/cubit/customer_cubit.dart';
import '../../../debt/presentation/cubit/debt_cubit.dart';
import '../../../debt/presentation/cubit/debt_state.dart';
import '../../../product/presentation/cubit/product_cubit.dart';
import '../../domain/entities/operation_entity.dart';
import '../cubit/operation_cubit.dart';
import '../cubit/operation_state.dart';
import '../utils/operation_validator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State variables for navigation between modes
  QuickAddMode _selectedMode = QuickAddMode.shop;
  PlayStationMode _psSubMode = PlayStationMode.time;

  // Controllers for PlayStation modes
  final _customerController = TextEditingController();
  final _paidController = TextEditingController();
  final _ledgerController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _turnRateController = TextEditingController();

  // Controllers for Shop mode
  final _productController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _debtController = TextEditingController();

  // FocusNodes for navigation
  final _customerFocus = FocusNode();
  final _paidFocus = FocusNode();
  final _hourlyRateFocus = FocusNode();
  final _turnRateFocus = FocusNode();
  final _productFocus = FocusNode();
  final _totalAmountFocus = FocusNode();
  final _debtFocus = FocusNode();
  final _ledgerFocus = FocusNode();

  // Temporary constants for calculation prototypes
  int _matchCount = 1;
  int _durationMinutes = 60; // Default to 60 mins (1 hour)
  String? _customerError;
  String? _selectedPhoneNumber;

  void _onContactPickerPressed() async {
    final result = await ContactService.pickContact(context);
    if (result != null) {
      setState(() {
        _customerController.text = result['name'] ?? '';
        _selectedPhoneNumber = result['phone'];
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Check user type from MainLayoutCubit
    final layoutCubit = context.read<MainLayoutCubit>();
    if (layoutCubit.isShop) {
      _selectedMode = QuickAddMode.shop;
    }

    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      context.read<CustomerCubit>().fetchCustomers(uid);
      context.read<ProductCubit>().fetchProducts(uid);
    }

    // Load persisted rates
    final hourlyRate = sl<CashHelper>().getData(key: AppStrings.hourlyRateKey);
    final slotRate = sl<CashHelper>().getData(key: AppStrings.slotRateKey);

    _hourlyRateController.text = (hourlyRate ?? '10.0').toString();
    _turnRateController.text = (slotRate ?? '5.0').toString();

    // Listeners to save data automatically
    _hourlyRateController.addListener(() {
      sl<CashHelper>().saveData(
        key: AppStrings.hourlyRateKey,
        value: _hourlyRateController.text,
      );
      setState(() {}); // Recalculate totalDue
    });

    _turnRateController.addListener(() {
      sl<CashHelper>().saveData(
        key: AppStrings.slotRateKey,
        value: _turnRateController.text,
      );
      setState(() {}); // Recalculate totalDue
    });

    _totalAmountController.addListener(_updateShopDebt);
    _paidController.addListener(_updateShopDebt);
  }

  void _updateShopDebt() {
    if (_selectedMode != QuickAddMode.shop) return;
    // Only auto-calculate debt if in Shop mode.
    // In Cafe mode, debt is entered manually.
    if (!context.read<MainLayoutCubit>().isShop) return;

    final totalText = _totalAmountController.text;
    final paidText = _paidController.text;

    final total = double.tryParse(totalText) ?? 0.0;
    final paid = double.tryParse(paidText) ?? 0.0;

    final remaining = (total - paid) > 0 ? (total - paid) : 0.0;

    if (mounted && _debtController.text != remaining.toStringAsFixed(1)) {
      setState(() {
        _debtController.text = remaining.toStringAsFixed(1);
      });
    }
  }

  double get totalDue {
    if (_selectedMode == QuickAddMode.shop) return 0.0;
    if (_psSubMode == PlayStationMode.turn) {
      double rate = double.tryParse(_turnRateController.text) ?? 0.0;
      return rate * _matchCount;
    }
    double rate = double.tryParse(_hourlyRateController.text) ?? 0.0;
    return (rate / 60) * _durationMinutes;
  }

  @override
  void dispose() {
    _customerController.dispose();
    _paidController.dispose();
    _productController.dispose();
    _totalAmountController.dispose();
    _debtController.dispose();
    _hourlyRateController.dispose();
    _turnRateController.dispose();
    _ledgerController.dispose();

    _customerFocus.dispose();
    _paidFocus.dispose();
    _hourlyRateFocus.dispose();
    _turnRateFocus.dispose();
    _productFocus.dispose();
    _totalAmountFocus.dispose();
    _debtFocus.dispose();
    _ledgerFocus.dispose();
    super.dispose();
  }

  void _clearFields() {
    _customerController.clear();
    _paidController.clear();
    _productController.clear();
    _totalAmountController.clear();
    _debtController.clear();
    _ledgerController.clear();
    setState(() {
      _matchCount = 1;
      _durationMinutes = 60;
      _customerError = null;
      _selectedPhoneNumber = null;
    });
  }

  void _submitOperation(BuildContext context) {
    final uid = AppStrings.userToken;
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 500),
          content: Text(AppStrings.userNotFound.tr()),
        ),
      );
      return;
    }

    String? validationMsg;
    double paid = double.tryParse(_paidController.text) ?? 0.0;
    OperationEntity operation;
    final isShopAccount = context.read<MainLayoutCubit>().isShop;

    if (_selectedMode == QuickAddMode.shop) {
      String productName = _productController.text.trim();
      final customerName = _customerController.text.trim();
      double totalAmount = 0.0;
      double paidAmount = double.tryParse(_paidController.text) ?? 0.0;
      double remainingDebt = 0.0;

      if (isShopAccount) {
        totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;
        remainingDebt = (totalAmount - paidAmount) > 0
            ? (totalAmount - paidAmount)
            : 0.0;

        if (productName.isEmpty) {
          validationMsg = AppStrings.validationProductNameRequired.tr();
        } else if (totalAmount <= 0) {
          validationMsg = AppStrings.validationInvalidAmount.tr();
        }
      } else {
        // Cafe mode logic
        if (productName.isEmpty) {
          productName = AppStrings.defaultProductName.tr();
        }
        remainingDebt = double.tryParse(_debtController.text) ?? 0.0;
        totalAmount = paidAmount + remainingDebt;

        if (paidAmount <= 0 && remainingDebt <= 0) {
          validationMsg = AppStrings.validationInvalidAmount.tr();
        }
      }

      if (validationMsg == null) {
        final errorKey = OperationValidator.validateCustomerName(
          name: customerName,
          totalAmount: totalAmount,
          paidAmount: paidAmount,
        );
        if (errorKey != null) {
          setState(() => _customerError = errorKey.tr());
          return;
        }
        setState(() => _customerError = null);
      }

      if (validationMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 500),
            content: Text(validationMsg),
            backgroundColor: AppColors.orange,
          ),
        );
        return;
      }

      operation = OperationEntity(
        uid: uid,
        type: AppStrings.shop,
        customerName: customerName,
        phoneNumber: _selectedPhoneNumber,
        productName: productName,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        remainingDebt: remainingDebt,
        ledgerNumber: _ledgerController.text.trim().isNotEmpty
            ? _ledgerController.text.trim()
            : null,
        lastUpdatedAt: DateTime.now(),
      );
    } else {
      final customerName = _customerController.text.trim();
      if (totalDue <= 0) {
        validationMsg = AppStrings.validationSessionRequired.tr();
      } else {
        final errorKey = OperationValidator.validateCustomerName(
          name: customerName,
          totalAmount: totalDue,
          paidAmount: paid,
        );
        if (errorKey != null) {
          setState(() => _customerError = errorKey.tr());
          return;
        }
        setState(() => _customerError = null);
      }

      if (validationMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 500),
            content: Text(validationMsg),
            backgroundColor: AppColors.orange,
          ),
        );
        return;
      }

      operation = OperationEntity(
        uid: uid,
        type: AppStrings.playStation,
        subType: _psSubMode == PlayStationMode.time ? 'time' : 'turn',
        customerName: customerName,
        phoneNumber: _selectedPhoneNumber,
        totalAmount: totalDue,
        paidAmount: paid,
        remainingDebt: (totalDue - paid) > 0 ? (totalDue - paid) : 0,
        durationMinutes: _psSubMode == PlayStationMode.time
            ? _durationMinutes
            : null,
        turnCount: _psSubMode == PlayStationMode.turn ? _matchCount : null,
        rate: double.tryParse(
          _psSubMode == PlayStationMode.time
              ? _hourlyRateController.text
              : _turnRateController.text,
        ),
        lastUpdatedAt: DateTime.now(),
      );
    }

    context.read<OperationCubit>().addOperation(operation);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MainLayoutCubit, MainLayoutState>(
          listener: (context, state) {
            if (state is MainLayoutUserTypeLoaded) {
              if (context.read<MainLayoutCubit>().isShop) {
                setState(() => _selectedMode = QuickAddMode.shop);
              }
            }
          },
        ),
        BlocListener<DebtCubit, DebtState>(
          listener: (context, state) {
            if (state is DebtAddSuccess) {
              AppLogger.printMessage('Debt recorded with ID: ${state.debtId}');
            } else if (state is DebtFailure) {
              if (context.read<ConnectivityCubit>().state
                  is ConnectivityConnected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(milliseconds: 500),
                    content: Text(
                      '${AppStrings.operationFailed.tr()}: ${state.message}',
                    ),
                    backgroundColor: AppColors.orange,
                  ),
                );
              }
            }
          },
        ),
        BlocListener<OperationCubit, OperationState>(
          listener: (context, state) {
            if (state is OperationSuccess) {
              final uid = AppStrings.userToken;
              if (uid.isNotEmpty) {
                // Refresh debts since AddOperationUseCase now handles side-effect creation of debts
                context.read<DebtCubit>().getDebts(uid, forceRefresh: true);
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(milliseconds: 500),
                  content: Text(AppStrings.operationSuccess.tr()),
                  backgroundColor: AppColors.green,
                ),
              );

              // Save customer for autocomplete
              final customerName = _customerController.text.trim();
              if (uid.isNotEmpty && customerName.isNotEmpty) {
                context.read<CustomerCubit>().saveCustomer(
                  uid,
                  customerName,
                  ledgerNumber: _ledgerController.text.trim().isNotEmpty
                      ? _ledgerController.text.trim()
                      : null,
                  phoneNumber: _selectedPhoneNumber,
                );
              }

              // Save product for autocomplete (Shop Mode only)
              final productName = _productController.text.trim();
              if (uid.isNotEmpty &&
                  _selectedMode == QuickAddMode.shop &&
                  productName.isNotEmpty) {
                context.read<ProductCubit>().saveProduct(uid, productName);
              }

              _clearFields();
            } else if (state is OperationFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(milliseconds: 500),
                  content: Text(state.message.tr()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<OperationCubit, OperationState>(
        builder: (context, state) {
          final isDesktop = ResponsiveLayout.isDesktop(context);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 800 : double.infinity,
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            AppStrings.quickAdd.tr(),
                            style: TextStyles.customStyle(
                              color: AppColors.black,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        20.verticalSpace,
                        // Mode Selection
                        if (context.read<MainLayoutCubit>().isCafe &&
                            !context.watch<MainLayoutCubit>().isShop)
                          QuickAddModeSelector(
                            selectedMode: _selectedMode,
                            onModeChanged: (mode) {
                              setState(() {
                                _selectedMode = mode;
                                if (_selectedMode == QuickAddMode.playStation) {
                                  _psSubMode = PlayStationMode.time;
                                }
                              });
                            },
                          ),
                        const SizedBox(height: 24),

                        // Mode Body
                        if (_selectedMode == QuickAddMode.playStation) ...[
                          // PS Mode Sub-tabs
                          QuickAddSubTabHeader(
                            selectedMode: _psSubMode,
                            onModeChanged: (mode) =>
                                setState(() => _psSubMode = mode),
                          ),
                          const SizedBox(height: 24),

                          // Form based on sub-mode
                          if (_psSubMode == PlayStationMode.time)
                            QuickAddTimeForm(
                              customerController: _customerController,
                              hourlyRateController: _hourlyRateController,
                              durationMinutes: _durationMinutes,
                              customerError: _customerError,
                              customerFocus: _customerFocus,
                              hourlyRateFocus: _hourlyRateFocus,
                              nextFocus: _paidFocus,
                              onCustomerSubmitted: (_) =>
                                  _hourlyRateFocus.requestFocus(),
                              onHourlyRateSubmitted: (_) =>
                                  _paidFocus.requestFocus(),
                              onDurationAdd: () =>
                                  setState(() => _durationMinutes += 5),
                              onDurationRemove: () => setState(
                                () => _durationMinutes > 5
                                    ? _durationMinutes -= 5
                                    : null,
                              ),
                              onContactPickerPressed: _onContactPickerPressed,
                            )
                          else
                            QuickAddTurnForm(
                              customerController: _customerController,
                              turnRateController: _turnRateController,
                              matchCount: _matchCount,
                              customerError: _customerError,
                              customerFocus: _customerFocus,
                              turnRateFocus: _turnRateFocus,
                              nextFocus: _paidFocus,
                              onCustomerSubmitted: (_) =>
                                  _turnRateFocus.requestFocus(),
                              onTurnRateSubmitted: (_) =>
                                  _paidFocus.requestFocus(),
                              onAdd: () => setState(() => _matchCount++),
                              onRemove: () => setState(
                                () => _matchCount > 1 ? _matchCount-- : null,
                              ),
                              onContactPickerPressed: _onContactPickerPressed,
                            ),

                          const SizedBox(height: 24),

                          // Total Calculation Card
                          QuickAddSummaryCard(totalDue: totalDue),

                          const SizedBox(height: 24),

                          // Paid Field
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.paidAmount.tr(),
                                style: TextStyles.customStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _paidController.text = totalDue
                                        .toStringAsFixed(1);
                                  });
                                },
                                child: Text(
                                  AppStrings.paidFull.tr(),
                                  style: TextStyles.customStyle(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          QuickAddTextField(
                            hint: '0.00',
                            controller: _paidController,
                            suffixText: AppStrings.currencyEgp.tr(),
                            isNumber: true,
                            focusNode: _paidFocus,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submitOperation(context),
                          ),
                        ] else ...[
                          // Shop Mode Body (Simplified Form)
                          QuickAddShopForm(
                            totalAmountController: _totalAmountController,
                            customerController: _customerController,
                            productController: _productController,
                            paidController: _paidController,
                            debtController: _debtController,
                            ledgerController: _ledgerController,
                            isShop: context.read<MainLayoutCubit>().isShop,
                            customerError: _customerError,
                            totalAmountFocus: _totalAmountFocus,
                            customerFocus: _customerFocus,
                            ledgerFocus: _ledgerFocus,
                            productFocus: _productFocus,
                            paidFocus: _paidFocus,
                            debtFocus: _debtFocus,
                            onDebtSubmitted: (_) => _submitOperation(context),
                            onContactPickerPressed: _onContactPickerPressed,
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Confirm Action Button
                        QuickActionButton(
                          label: AppStrings.confirmOperation.tr(),
                          icon: Icons.check_circle_outline,
                          onPressed:
                              (state is OperationLoading ||
                                  context.watch<DebtCubit>().state
                                      is DebtLoading)
                              ? null
                              : () => _submitOperation(context),
                        ),

                        const SizedBox(height: 20),

                        // Footer Info
                        Center(
                          child: Text(
                            AppStrings.quickAddDesc.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyles.customStyle(
                              color: AppColors.blackLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 100), // Padding for bottom nav
                      ],
                    ),
                  ),
                  if (state is OperationLoading ||
                      context.watch<DebtCubit>().state is DebtLoading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
