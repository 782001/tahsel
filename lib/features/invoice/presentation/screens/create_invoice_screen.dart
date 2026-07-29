import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/services/contact_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer/domain/entities/customer_entity.dart';
import 'package:tahsel/features/customer/presentation/cubit/customer_cubit.dart';
import 'package:tahsel/features/customer/presentation/widgets/customer_autocomplete_field.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_cubit.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_state.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_item_row.dart';
import 'package:tahsel/features/invoice/presentation/widgets/multi_inventory_picker_bottom_sheet.dart';
import 'package:tahsel/shared/widgets/buttons/quick_action_button.dart';

class _ItemControllers {
  final TextEditingController desc;
  final TextEditingController price;
  final TextEditingController qty;
  final TextEditingController discount;

  /// Pre-fill from an existing InvoiceItem (edit mode).
  _ItemControllers.fromItem(InvoiceItem item)
    : desc = TextEditingController(text: item.description),
      price = TextEditingController(text: item.unitPrice.toString()),
      qty = TextEditingController(text: item.quantity.toString()),
      discount = TextEditingController(
        text: (item.discountRate * 100).toStringAsFixed(
          item.discountRate == 0 ? 0 : 1,
        ),
      );

  _ItemControllers()
    : desc = TextEditingController(),
      price = TextEditingController(),
      qty = TextEditingController(text: '1'),
      discount = TextEditingController(text: '0');

  void dispose() {
    desc.dispose();
    price.dispose();
    qty.dispose();
    discount.dispose();
  }
}

class CreateInvoiceScreen extends StatefulWidget {
  /// If non-null, the screen opens in edit mode pre-filled with this invoice.
  final InvoiceEntity? invoiceToEdit;

  const CreateInvoiceScreen({super.key, this.invoiceToEdit});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  // ── Pending invoice to track during submission ──────────────────────────────
  InvoiceEntity? _pendingInvoice;

  // ── Customer info ──────────────────────────────────────────────────────────
  final _customerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ledgerController = TextEditingController();
  final _notesController = TextEditingController();
  final _overallDiscountController = TextEditingController();

  // ── Line items ─────────────────────────────────────────────────────────────
  final List<_ItemControllers> _itemControllers = [];

  // ── Derived total ──────────────────────────────────────────────────────────
  double get _subtotal {
    double sum = 0;
    for (final ctrl in _itemControllers) {
      final qty = double.tryParse(ctrl.qty.text) ?? 1.0;
      final price = double.tryParse(ctrl.price.text) ?? 0.0;
      final discountPct = double.tryParse(ctrl.discount.text) ?? 0.0;
      final subtotal = qty * price;
      sum += subtotal * (1 - discountPct / 100.0);
    }
    return sum;
  }

  double get _overallDiscount =>
      double.tryParse(_overallDiscountController.text) ?? 0.0;

  double get _grandTotal {
    final net = _subtotal - _overallDiscount;
    return net > 0 ? net : 0.0;
  }

  bool get _isEditMode => widget.invoiceToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final inv = widget.invoiceToEdit!;
      _customerController.text = inv.customerName ?? '';
      _phoneController.text = inv.customerPhone ?? '';
      _ledgerController.text = inv.ledgerNumber ?? '';
      _notesController.text = inv.notes ?? '';
      _overallDiscountController.text = inv.discountAmount > 0
          ? inv.discountAmount.toSmartAmount()
          : '';
      for (final item in inv.items) {
        _itemControllers.add(_ItemControllers.fromItem(item));
      }
      if (_itemControllers.isEmpty) _addItem();
    } else {
      _addItem(); // Start with one empty item row
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    _ledgerController.dispose();
    _notesController.dispose();
    _overallDiscountController.dispose();
    for (final c in _itemControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _itemControllers.add(_ItemControllers());
    });
  }

  void _removeItem(int index) {
    if (_itemControllers.length <= 1) return; // keep at least one
    setState(() {
      _itemControllers[index].dispose();
      _itemControllers.removeAt(index);
    });
  }

  void _pickContact() async {
    final result = await ContactService.pickContact(context);
    if (result != null) {
      setState(() {
        _customerController.text = result['name'] ?? '';
        _phoneController.text = result['phone'] ?? '';
      });
    }
  }

  void _openMultiInventoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MultiInventoryPickerBottomSheet(
        onItemsConfirmed: (selectedItems) {
          setState(() {
            if (_itemControllers.length == 1 &&
                _itemControllers.first.desc.text.trim().isEmpty &&
                _itemControllers.first.price.text.trim().isEmpty) {
              _itemControllers.clear();
            }

            for (final item in selectedItems) {
              final newCtrl = _ItemControllers();
              newCtrl.desc.text = item.product.name;
              newCtrl.price.text = item.product.sellingPrice.toSmartAmount();
              newCtrl.qty.text = item.quantity.toSmartAmount();
              _itemControllers.add(newCtrl);
            }

            if (_itemControllers.isEmpty) {
              _addItem();
            }
          });
        },
      ),
    );
  }

  void _submit(BuildContext context) {
    final uid = AppStrings.userToken;
    if (uid.isEmpty) return;

    final customerName = _customerController.text.trim();
    if (customerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.invoiceCustomerNameRequired.tr()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Validate: at least one non-empty description with a price
    final validItems = _itemControllers.where((c) {
      final desc = c.desc.text.trim();
      final price = double.tryParse(c.price.text) ?? 0.0;
      return desc.isNotEmpty && price > 0;
    }).toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.invoiceValidationItems.tr()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final items = validItems.asMap().entries.map((entry) {
      final ctrl = entry.value;
      final discountPct = double.tryParse(ctrl.discount.text) ?? 0.0;
      return InvoiceItem(
        id: _isEditMode
            ? (widget.invoiceToEdit!.items.length > entry.key
                  ? widget.invoiceToEdit!.items[entry.key].id
                  : 'item_${entry.key}')
            : 'item_${entry.key}',
        description: ctrl.desc.text.trim(),
        unitPrice: double.tryParse(ctrl.price.text) ?? 0.0,
        quantity: double.tryParse(ctrl.qty.text) ?? 1.0,
        discountRate: (discountPct / 100.0).clamp(0.0, 1.0),
      );
    }).toList();

    final overallDiscount =
        double.tryParse(_overallDiscountController.text) ?? 0.0;

    if (_isEditMode) {
      // Edit mode — patch mutable fields, preserve payments/status/createdAt
      final updated = widget.invoiceToEdit!.copyWith(
        customerName: customerName,
        customerPhone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        ledgerNumber: _ledgerController.text.trim().isNotEmpty
            ? _ledgerController.text.trim()
            : null,
        items: items,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        discountAmount: overallDiscount,
        lastUpdatedAt: DateTime.now(),
      );
      context.read<InvoiceCubit>().updateInvoice(
        updated,
        previous: widget.invoiceToEdit,
      );
    } else {
      // Create mode
      final invoice = InvoiceEntity(
        id: '',
        uid: uid,
        customerName: customerName,
        customerPhone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        ledgerNumber: _ledgerController.text.trim().isNotEmpty
            ? _ledgerController.text.trim()
            : null,
        items: items,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        discountAmount: overallDiscount,
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      _pendingInvoice = invoice;
      context.read<InvoiceCubit>().createInvoice(invoice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocListener<InvoiceCubit, InvoiceState>(
      listener: (context, state) {
        if (state is InvoiceCreateSuccess) {
          // ── Auto-save customer to the shared customers collection ──────────
          // Mirrors the Quick Add flow so both features share one source of truth.
          final uid = AppStrings.userToken;
          final name = _customerController.text.trim();
          if (uid.isNotEmpty && name.isNotEmpty) {
            context.read<CustomerCubit>().saveCustomer(
              uid,
              name,
              phoneNumber: _phoneController.text.trim().isNotEmpty
                  ? _phoneController.text.trim()
                  : null,
              ledgerNumber: _ledgerController.text.trim().isNotEmpty
                  ? _ledgerController.text.trim()
                  : null,
            );
          }
          // ──────────────────────────────────────────────────────────────────

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.invoiceCreateSuccess.tr()),
              backgroundColor: AppColors.success,
            ),
          );
          if (_pendingInvoice != null) {
            Navigator.of(context).pop({
              'invoice': _pendingInvoice!.copyWith(id: state.invoiceId),
              'showPaymentImmediately': true,
            });
          } else {
            Navigator.of(context).pop(true);
          }
        } else if (state is InvoiceUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.invoiceUpdateSuccess.tr()),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true); // signal success to caller
        } else if (state is InvoiceFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scafoldBackGround,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text(
            _isEditMode
                ? AppStrings.invoiceEditTitle.tr()
                : AppStrings.createInvoice.tr(),
            style: TextStyles.customStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primaryColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 700 : double.infinity,
              ),
              child: BlocBuilder<InvoiceCubit, InvoiceState>(
                builder: (context, state) {
                  final isLoading = state is InvoiceLoading;
                  return Stack(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 32 : 20.w,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Section: Customer Info ───────────────────────
                            _SectionHeader(
                              title: AppStrings.invoiceCustomerSection.tr(),
                            ),
                            const SizedBox(height: 12),
                            _CustomerField(
                              controller: _customerController,
                              hint: AppStrings.customerNameHint.tr(),
                              label: AppStrings.customerName.tr(),
                              onContactTap: _pickContact,
                              onSelected: (customer) {
                                setState(() {
                                  _phoneController.text =
                                      customer.phoneNumber ?? '';
                                  _ledgerController.text =
                                      customer.ledgerNumber ?? '';
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            _SimpleField(
                              controller: _phoneController,
                              hint: AppStrings.invoicePhoneHint.tr(),
                              label: AppStrings.customerPhone.tr(),
                              isNumber: true,
                            ),
                            const SizedBox(height: 10),
                            _SimpleField(
                              controller: _ledgerController,
                              hint: AppStrings.invoiceLedgerHint.tr(),
                              label: AppStrings.ledgerNumber.tr(),
                            ),
                            const SizedBox(height: 24),

                            // ── Section: Line Items ──────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _SectionHeader(
                                  title: AppStrings.invoiceItemsSection.tr(),
                                ),
                                if (AppStrings.isVip &&
                                    AppStrings.userType == AppStrings.shop)
                                  TextButton.icon(
                                    onPressed: _openMultiInventoryPicker,
                                    icon: Icon(
                                      Icons.storefront_outlined,
                                      color: AppColors.primaryColor,
                                      size: 18,
                                    ),
                                    label: Text(
                                      AppStrings.selectFromInventory.tr(),
                                      style: TextStyles.customStyle(
                                        color: AppColors.primaryColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Line item rows
                            for (int i = 0; i < _itemControllers.length; i++)
                              InvoiceItemRow(
                                key: ValueKey(i),
                                index: i,
                                descController: _itemControllers[i].desc,
                                priceController: _itemControllers[i].price,
                                qtyController: _itemControllers[i].qty,
                                discountController:
                                    _itemControllers[i].discount,
                                onRemove: () => _removeItem(i),
                                onChanged: () => setState(() {}),
                              ),

                            const SizedBox(height: 16),
                            Center(
                              child: TextButton.icon(
                                onPressed: _addItem,
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                                label: Text(
                                  AppStrings.invoiceAddItem.tr(),
                                  style: TextStyles.customStyle(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _SimpleField(
                              controller: _overallDiscountController,
                              hint: '0',
                              label: AppStrings.overallDiscountLabel.tr(),
                              isNumber: true,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),

                            // ── Grand Total ──────────────────────────────────
                            _TotalCard(
                              subtotal: _subtotal,
                              discountAmount: _overallDiscount,
                              grandTotal: _grandTotal,
                            ),
                            const SizedBox(height: 24),

                            // ── Notes ────────────────────────────────────────
                            _SectionHeader(
                              title: AppStrings.invoiceNotesSection.tr(),
                            ),
                            const SizedBox(height: 12),
                            _NotesField(controller: _notesController),
                            const SizedBox(height: 32),

                            // ── Submit Button ────────────────────────────────
                            QuickActionButton(
                              label: _isEditMode
                                  ? AppStrings.invoiceSaveEdit.tr()
                                  : AppStrings.invoiceSubmit.tr(),
                              icon: _isEditMode
                                  ? Icons.save_rounded
                                  : Icons.receipt_long_rounded,
                              onPressed: isLoading
                                  ? null
                                  : () => _submit(context),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      if (isLoading)
                        Container(
                          color: Colors.black.withValues(alpha: 0.3),
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
        ),
      ),
    );
  }
}

// ── Private sub-widgets ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyles.customStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
    );
  }
}

class _CustomerField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final VoidCallback onContactTap;
  final ValueChanged<CustomerEntity>? onSelected;

  const _CustomerField({
    required this.controller,
    required this.hint,
    required this.label,
    required this.onContactTap,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 6),
        CustomerAutocompleteField(
          controller: controller,
          hint: hint,
          suffixIcon: Icons.contact_phone_rounded,
          onSuffixIconPressed: onContactTap,
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _SimpleField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final bool isNumber;
  final ValueChanged<String>? onChanged;

  const _SimpleField({
    required this.controller,
    required this.hint,
    required this.label,
    this.isNumber = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.customStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          cursorColor: AppColors.primaryColor,
          controller: controller,
          keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
          onChanged: onChanged,
          style: TextStyles.customStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyles.customStyle(color: AppColors.disabledColor),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotesField extends StatelessWidget {
  final TextEditingController controller;

  const _NotesField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: AppColors.primaryColor,
      controller: controller,
      maxLines: 3,
      style: TextStyles.customStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: AppStrings.invoiceNotesHint.tr(),
        hintStyle: TextStyles.customStyle(color: AppColors.disabledColor),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double subtotal;
  final double discountAmount;
  final double grandTotal;

  const _TotalCard({
    required this.subtotal,
    required this.discountAmount,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.75),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (discountAmount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.subtotalBeforeDiscount.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  '${subtotal.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.overallDiscountAmount.tr(),
                  style: TextStyles.customStyle(
                    fontSize: 13,
                    color: Colors.yellowAccent.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  '-${discountAmount.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                  style: TextStyles.customStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.invoiceGrandTotal.tr(),
                style: TextStyles.customStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '${grandTotal.toSmartAmount()} ${AppStrings.currencyEgp.tr()}',
                style: TextStyles.customStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
