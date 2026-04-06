import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/services/injection_container.dart';
import 'package:tahsel/core/storage/cashhelper.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_logger.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/home/presentation/widgets/quick_add_mode_selector.dart';
import 'package:tahsel/features/home/presentation/widgets/quick_add_shop_form.dart';
import 'package:tahsel/features/home/presentation/widgets/quick_add_sub_tab_header.dart';
import 'package:tahsel/features/home/presentation/widgets/quick_add_summary_card.dart';
import 'package:tahsel/features/home/presentation/widgets/quick_add_time_form.dart';
import 'package:tahsel/features/home/presentation/widgets/quick_add_turn_form.dart';
import 'package:tahsel/shared/widgets/buttons/quick_action_button.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

import '../../../../features/customer/presentation/cubit/customer_cubit.dart';
import '../../../../features/debt/domain/entities/debt_entity.dart';
import '../../../../features/debt/presentation/cubit/debt_cubit.dart';
import '../../../../features/debt/presentation/cubit/debt_state.dart';
import '../../../../features/operation/domain/entities/operation_entity.dart';
import '../../../../features/operation/presentation/cubit/operation_cubit.dart';
import '../../../../features/operation/presentation/cubit/operation_state.dart';

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
  final _hourlyRateController = TextEditingController();
  final _turnRateController = TextEditingController();

  // Controllers for Shop mode
  final _productController = TextEditingController();
  final _debtController = TextEditingController();

  // Temporary constants for calculation prototypes
  int _matchCount = 1;
  int _durationMinutes = 60; // Default to 60 mins (1 hour)

  @override
  void initState() {
    super.initState();

    final uid = sl<FirebaseAuth>().currentUser?.uid;
    if (uid != null) {
      context.read<CustomerCubit>().fetchCustomers(uid);
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
    _debtController.dispose();
    _hourlyRateController.dispose();
    _turnRateController.dispose();
    super.dispose();
  }

  void _clearFields() {
    _customerController.clear();
    _paidController.clear();
    _productController.clear();
    _debtController.clear();
    setState(() {
      _matchCount = 1;
      _durationMinutes = 60;
    });
  }

  void _submitOperation(BuildContext context) {
    final uid = sl<FirebaseAuth>().currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(milliseconds: 500),
          content: Text(AppStrings.userNotFound.tr()),
        ),
      );
      return;
    }

    String? validationMsg;
    double paid = double.tryParse(_paidController.text) ?? 0.0;
    OperationEntity operation;

    if (_selectedMode == QuickAddMode.shop) {
      final productName = _productController.text.trim();
      final customerName = _customerController.text.trim();
      double remainingDebt = double.tryParse(_debtController.text) ?? 0.0;

      if (productName.isEmpty) {
        validationMsg = AppStrings.validationProductNameRequired.tr();
      } else if (customerName.isEmpty) {
        validationMsg = AppStrings.validationCustomerNameRequired.tr();
      } else if (remainingDebt > 0 && customerName.isEmpty) {
        validationMsg = AppStrings.validationCustomerNameRequired.tr();
      } else if (paid == 0 && remainingDebt == 0) {
        validationMsg = AppStrings.validationInvalidAmount.tr();
      }

      if (validationMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(milliseconds: 500),
            content: Text(validationMsg),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      operation = OperationEntity(
        uid: uid,
        type: 'shop',
        customerName: customerName,
        productName: productName,
        totalAmount: paid + remainingDebt,
        paidAmount: paid,
        remainingDebt: remainingDebt,
      );
    } else {
      final customerName = _customerController.text.trim();
      if (totalDue <= 0) {
        validationMsg = AppStrings.validationSessionRequired.tr();
      } else if (customerName.isEmpty) {
        validationMsg = AppStrings.validationCustomerNameRequired.tr();
      } else if (totalDue > paid && customerName.isEmpty) {
        validationMsg = AppStrings.validationCustomerNameRequired.tr();
      }

      if (validationMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(milliseconds: 500),
            content: Text(validationMsg),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      operation = OperationEntity(
        uid: uid,
        type: 'playStation',
        subType: _psSubMode == PlayStationMode.time ? 'time' : 'turn',
        customerName: customerName,
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
      );
    }

    context.read<OperationCubit>().addOperation(operation);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<OperationCubit>()),
        BlocProvider(create: (context) => sl<DebtCubit>()),
      ],
      child: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<DebtCubit, DebtState>(
              listener: (context, state) {
                if (state is DebtAddSuccess) {
                  // Optional: show a small toast or just log it
                  AppLogger.printMessage(
                    'Debt recorded with ID: ${state.debtId}',
                  );
                } else if (state is DebtFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: Duration(milliseconds: 500),
                      content: Text(
                        '${AppStrings.operationFailed.tr()}: ${state.message}',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
            BlocListener<OperationCubit, OperationState>(
              listener: (context, state) {
                if (state is OperationSuccess) {
                  // Check if there is debt before clearing
                  final double paid =
                      double.tryParse(_paidController.text) ?? 0.0;
                  final double remaining = _selectedMode == QuickAddMode.shop
                      ? (double.tryParse(_debtController.text) ?? 0.0)
                      : (totalDue - paid);

                  if (remaining > 0) {
                    final uid = sl<FirebaseAuth>().currentUser?.uid;
                    if (uid != null) {
                      context.read<DebtCubit>().addDebt(
                        DebtEntity(
                          uid: uid,
                          operationId: state.operationId,
                          totalAmount: _selectedMode == QuickAddMode.shop
                              ? (paid + remaining)
                              : totalDue,
                          paidAmount: paid,
                          remainingAmount: remaining,
                          customerName: _customerController.text.trim(),
                          productOrSessionDetails:
                              _selectedMode == QuickAddMode.shop
                              ? _productController.text.trim()
                              : (_psSubMode == PlayStationMode.time
                                    ? 'PS Session (Time)'
                                    : 'PS Session (Turn)'),
                          operationType: _selectedMode == QuickAddMode.shop
                              ? 'shop'
                              : 'playStation',
                        ),
                      );
                    }
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: Duration(milliseconds: 500),
                      content: Text(state.message.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Save customer for autocomplete
                  final uid = sl<FirebaseAuth>().currentUser?.uid;
                  final customerName = _customerController.text.trim();
                  if (uid != null && customerName.isNotEmpty) {
                    context.read<CustomerCubit>().saveCustomer(
                      uid,
                      customerName,
                    );
                  }

                  _clearFields();
                } else if (state is OperationFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: Duration(milliseconds: 500),
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
              return Stack(
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
                              onDurationAdd: () =>
                                  setState(() => _durationMinutes += 5),
                              onDurationRemove: () => setState(
                                () => _durationMinutes > 5
                                    ? _durationMinutes -= 5
                                    : null,
                              ),
                            )
                          else
                            QuickAddTurnForm(
                              customerController: _customerController,
                              turnRateController: _turnRateController,
                              matchCount: _matchCount,
                              onAdd: () => setState(() => _matchCount++),
                              onRemove: () => setState(
                                () => _matchCount > 1 ? _matchCount-- : null,
                              ),
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
                          ),
                        ] else ...[
                          // Shop Mode Body (Simplified Form)
                          QuickAddShopForm(
                            customerController: _customerController,
                            productController: _productController,
                            paidController: _paidController,
                            debtController: _debtController,
                          ),
                          const SizedBox(height: 32),
                        ],

                        const SizedBox(height: 32),

                        // Confirm Action Button
                        QuickActionButton(
                          label: AppStrings.confirmOperation.tr(),
                          icon: Icons.check_circle_outline,
                          onPressed: state is OperationLoading
                              ? () {}
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
                  if (state is OperationLoading)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
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
