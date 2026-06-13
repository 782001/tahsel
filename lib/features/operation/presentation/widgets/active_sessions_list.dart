import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/customer/presentation/widgets/customer_autocomplete_field.dart';
import 'package:tahsel/features/operation/domain/entities/ps_session_entity.dart';
import 'package:tahsel/features/operation/presentation/cubit/ps_session_cubit.dart';
import 'package:tahsel/shared/widgets/fields/quick_text_field.dart';

class ActiveSessionsList extends StatelessWidget {
  final List<PsSessionEntity> sessions;

  const ActiveSessionsList({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.stitchSurfaceHigh.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 48,
              color: AppColors.blackLight.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.noActiveSessions.tr(),
              style: TextStyles.customStyle(
                color: AppColors.blackLight,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${AppStrings.activeSessionsTitle.tr()} (${sessions.length})",
                style: TextStyles.customStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return ActiveSessionCard(session: sessions[index]);
          },
        ),
      ],
    );
  }
}

class ActiveSessionCard extends StatefulWidget {
  final PsSessionEntity session;

  const ActiveSessionCard({super.key, required this.session});

  @override
  State<ActiveSessionCard> createState() => _ActiveSessionCardState();
}

class _ActiveSessionCardState extends State<ActiveSessionCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Update every second for smooth, real-time ticking
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatDigitalTimer(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatElapsed(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return AppStrings.sessionElapsedFormat.tr(
      namedArgs: {'hours': hours.toString(), 'minutes': minutes.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final elapsed = session.elapsed;
    final elapsedText = _formatElapsed(elapsed);
    final digitalTimerText = _formatDigitalTimer(elapsed);
    final calculatedCost = session.calculatedAmount;

    // Determine target label (Device or Room or both)
    String targetLabel = '';
    IconData targetIcon = Icons.sports_esports;
    if (session.deviceId != null && session.roomId != null) {
      targetLabel = '${session.deviceId} • ${session.roomId}';
      targetIcon = Icons.videogame_asset;
    } else if (session.deviceId != null) {
      targetLabel = session.deviceId!;
      targetIcon = Icons.sports_esports;
    } else if (session.roomId != null) {
      targetLabel = session.roomId!;
      targetIcon = Icons.meeting_room;
    } else {
      targetLabel = AppStrings.byTime.tr();
      targetIcon = Icons.access_time;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Colored Accent Bar representing running session
            Container(width: 6, color: AppColors.primaryColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Row: Device/Room Badge & Live Ticker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Room / Device Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                targetIcon,
                                size: 16,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                targetLabel,
                                style: TextStyles.customStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Breathing active badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _BreathingDot(),
                              const SizedBox(width: 6),
                              Text(
                                AppStrings.sessionRunning.tr(),
                                style: TextStyles.customStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Customer Name & Rate Details
                    if (session.customerName != null &&
                        session.customerName!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: AppColors.blackLight,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              session.customerName!,
                              style: TextStyles.customStyle(
                                color: AppColors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],

                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on_outlined,
                          size: 16,
                          color: AppColors.blackLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${AppStrings.hourlyRateKey.tr()}: ${session.rate.toSmartAmount()} ${AppStrings.currencyEgpPerHour.tr()}',
                          style: TextStyles.customStyle(
                            color: AppColors.blackLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 28, thickness: 1),

                    // Timer Display & Live Cost Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Digital Clock Ticker
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.sessionElapsed.tr(),
                              style: TextStyles.customStyle(
                                color: AppColors.blackLight,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              digitalTimerText,
                              style: TextStyle(
                                color: AppColors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                fontFamily:
                                    'monospace', // Monospaced digital clock style
                              ),
                            ),
                            Text(
                              elapsedText,
                              style: TextStyles.customStyle(
                                color: AppColors.blackLight,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        // Live Cost
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppStrings.sessionCalculatedAmount.tr(),
                              style: TextStyles.customStyle(
                                color: AppColors.blackLight,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${calculatedCost.toStringAsFixed(2)} ${AppStrings.currencyEgp.tr()}",
                              style: TextStyles.customStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // End Session Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showEndSessionDialog(context),
                        icon: const Icon(
                          Icons.stop_circle_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          AppStrings.endSession.tr(),
                          style: TextStyles.customStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEndSessionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _EndSessionSheet(
          session: widget.session,
          psSessionCubit: context.read<PsSessionCubit>(),
        );
      },
    );
  }
}

class _BreathingDot extends StatefulWidget {
  const _BreathingDot();

  @override
  State<_BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<_BreathingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _EndSessionSheet extends StatefulWidget {
  final PsSessionEntity session;
  final PsSessionCubit psSessionCubit;

  const _EndSessionSheet({required this.session, required this.psSessionCubit});

  @override
  State<_EndSessionSheet> createState() => _EndSessionSheetState();
}

class _EndSessionSheetState extends State<_EndSessionSheet> {
  final _customerController = TextEditingController();
  final _paidController = TextEditingController();
  final _ledgerController = TextEditingController();
  final _turnCountController = TextEditingController();
  final _customerFocus = FocusNode();
  final _paidFocus = FocusNode();
  final _ledgerFocus = FocusNode();
  final _turnCountFocus = FocusNode();

  late double _totalAmount;
  int _turnCount = 1;
  bool _customerTouched = false; // tracks if user interacted with name field
  bool _customerNameTapped = false;
  String _lastSelectedCustomerName = '';

  @override
  void initState() {
    super.initState();

    // Pre-fill customer name if session already has one
    final initialName = widget.session.customerName ?? '';
    _customerController.text = initialName;
    if (initialName.isNotEmpty) {
      _customerNameTapped = true;
      _lastSelectedCustomerName = initialName;
    }

    _turnCount = widget.session.turnCount ?? 1;
    _turnCountController.text = _turnCount.toString();
    _updateTotalAmount();

    // Default to 0 — operator must explicitly enter amount or tap "Full Payment"
    _paidController.text = '0';

    _turnCountController.addListener(() {
      final parsed = int.tryParse(_turnCountController.text) ?? 1;
      if (parsed != _turnCount) {
        setState(() {
          _turnCount = parsed;
          _updateTotalAmount();
          // Reset paid to 0 when turn count changes so operator re-confirms
          _paidController.text = '0';
        });
      }
    });

    // Mark field as touched when customer name changes and reset tapped if typed
    _customerController.addListener(() {
      if (_customerController.text != _lastSelectedCustomerName) {
        if (_customerNameTapped) {
          setState(() {
            _customerNameTapped = false;
          });
        }
      }
      if (!_customerTouched && _customerController.text.isNotEmpty) {
        setState(() => _customerTouched = true);
      } else {
        setState(() {});
      }
    });
  }

  void _updateTotalAmount() {
    if (widget.session.subType == 'turn') {
      _totalAmount = _turnCount * widget.session.rate;
    } else {
      _totalAmount = double.parse(
        widget.session.calculatedAmount.toStringAsFixed(2),
      );
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _paidController.dispose();
    _ledgerController.dispose();
    _turnCountController.dispose();
    _customerFocus.dispose();
    _paidFocus.dispose();
    _ledgerFocus.dispose();
    _turnCountFocus.dispose();
    super.dispose();
  }

  /// Returns true when the form is valid and submission is allowed.
  bool get _canSubmit {
    final paid = double.tryParse(_paidController.text) ?? 0.0;
    final hasDebt = paid < _totalAmount;
    if (hasDebt) {
      // Any non-empty name is accepted — new or existing
      if (_customerController.text.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  /// Whether to show the "customer name required" error.
  String? get _customerError {
    final paid = double.tryParse(_paidController.text) ?? 0.0;
    final hasDebt = paid < _totalAmount;
    // Show error only when field is touched AND has debt AND name is empty
    if (_customerTouched && hasDebt && _customerController.text.trim().isEmpty) {
      return AppStrings.validationCustomerNameRequired.tr();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isTurn = widget.session.subType == 'turn';
    final elapsed = widget.session.elapsed;
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final elapsedText = AppStrings.sessionElapsedFormat.tr(
      namedArgs: {'hours': hours.toString(), 'minutes': minutes.toString()},
    );

    final paid = double.tryParse(_paidController.text) ?? 0.0;
    final hasDebt = paid < _totalAmount;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.endSessionConfirm.tr(),
                style: TextStyles.customStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 16),

              // Session summary
              if (widget.session.deviceId != null)
                _buildSummaryItem(
                  AppStrings.deviceLabel.tr(),
                  widget.session.deviceId!,
                ),
              if (widget.session.roomId != null)
                _buildSummaryItem(
                  AppStrings.roomLabel.tr(),
                  widget.session.roomId!,
                ),
              _buildSummaryItem(AppStrings.sessionElapsed.tr(), elapsedText),

              const Divider(height: 24, thickness: 1),

              // Turn counter (only for turn-based sessions)
              if (isTurn) ...[
                Text(
                  AppStrings.turnCount.tr(),
                  style: TextStyles.customStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        if (_turnCount > 1) {
                          _turnCountController.text = (_turnCount - 1)
                              .toString();
                        }
                      },
                    ),
                    Expanded(
                      child: QuickAddTextField(
                        hint: '1',
                        controller: _turnCountController,
                        isNumber: true,
                        focusNode: _turnCountFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _paidFocus.requestFocus(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.green,
                      ),
                      onPressed: () {
                        _turnCountController.text = (_turnCount + 1).toString();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Total Due
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.totalDueLabel.tr(),
                    style: TextStyles.customStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  Text(
                    "${_totalAmount.toStringAsFixed(2)} ${AppStrings.currencyEgp.tr()}",
                    style: TextStyles.customStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Paid Amount Field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.paidAmount.tr(),
                    style: TextStyles.customStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _paidController.text = _totalAmount.toStringAsFixed(2);
                      });
                    },
                    child: Text(
                      AppStrings.paidFull.tr(),
                      style: TextStyles.customStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
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
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _customerFocus.requestFocus(),
              ),
              const SizedBox(height: 20),

              // ── Customer Name Autocomplete ────────────────────────────────
              Row(
                children: [
                  Text(
                    AppStrings.customerName.tr(),
                    style: TextStyles.customStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (hasDebt) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppStrings.requiredField.tr(),
                        style: TextStyles.customStyle(
                          color: Colors.red[700],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              CustomerAutocompleteField(
                hint: AppStrings.customerNameHint.tr(),
                controller: _customerController,
                errorText: _customerError,
                icon: Icons.person_outline,
                focusNode: _customerFocus,
                textInputAction: TextInputAction.done,
                onSelected: (customer) {
                  setState(() {
                    _customerNameTapped = true;
                    _lastSelectedCustomerName = customer.name;
                    _customerTouched = true;
                  });
                },
                onSubmitted: (_) {
                  setState(() => _customerTouched = true);
                  if (_canSubmit) _submit();
                },
              ),
              // Hint when debt exists and name field is empty
              if (hasDebt && _customerController.text.trim().isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.red[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          AppStrings.validationCustomerNameRequired.tr(),
                          style: TextStyles.customStyle(
                            color: Colors.red[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Confirm button — disabled when customer name is required but missing
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _customerTouched = true);
                    if (_canSubmit) _submit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit ? Colors.green : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    AppStrings.confirmOperation.tr(),
                    style: TextStyles.customStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.customStyle(
              color: AppColors.blackLight,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyles.customStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    // Cap paid at total — never accept overpayment
    final rawPaid = double.tryParse(_paidController.text) ?? 0.0;
    final paid = rawPaid > _totalAmount ? _totalAmount : rawPaid;

    final customerName = _customerController.text.trim().isNotEmpty
        ? _customerController.text.trim()
        : widget.session.customerName;

    widget.psSessionCubit.endSession(
      uid: AppStrings.userToken,
      sessionId: widget.session.id!,
      endTime: DateTime.now(),
      totalAmount: _totalAmount,
      paidAmount: paid,
      customerName: customerName,
      phoneNumber: widget.session.phoneNumber,
      ledgerNumber: null,
      subType: widget.session.subType,
      turnCount: widget.session.subType == 'turn' ? _turnCount : null,
    );

    Navigator.pop(context);
  }
}
