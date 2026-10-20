import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/constants/app_permissions.dart';
import 'package:tahsel/core/extensions/extensions.dart';
import 'package:tahsel/core/services/contact_service.dart';
import 'package:tahsel/core/services/permission_service.dart';
import 'package:tahsel/core/services/profile/business_profile_service.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/customer_data_masker.dart';
import 'package:tahsel/core/utils/date_formatter.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/core/widgets/responsive_layout.dart';
import 'package:tahsel/features/customer/domain/entities/customer_entity.dart';
import 'package:tahsel/features/customer/presentation/cubit/customer_cubit.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_entity.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_cubit.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_state.dart';
import 'package:tahsel/features/invoice/presentation/widgets/convert_quotation_dialog.dart';
import 'package:tahsel/features/invoice/presentation/widgets/create_invoice_customer_field.dart';
import 'package:tahsel/features/invoice/presentation/widgets/create_invoice_notes_field.dart';
import 'package:tahsel/features/invoice/presentation/widgets/create_invoice_section_header.dart';
import 'package:tahsel/features/invoice/presentation/widgets/create_invoice_simple_field.dart';
import 'package:get_it/get_it.dart';
import 'package:tahsel/features/inventory/data/datasources/inventory_local_data_source.dart';
import 'package:tahsel/features/inventory/domain/entities/inventory_product_entity.dart';
import 'package:tahsel/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:tahsel/features/invoice/presentation/widgets/create_invoice_total_card.dart';
import 'package:tahsel/features/invoice/presentation/widgets/invoice_item_row.dart';
import 'package:tahsel/features/invoice/presentation/widgets/multi_inventory_picker_bottom_sheet.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_cubit.dart';
import 'package:tahsel/features/standard_features/no-internet/logic/connectivity_state.dart';
import 'package:tahsel/shared/widgets/buttons/quick_action_button.dart';
import 'package:tahsel/shared/widgets/quick_due_date_selector.dart';

class _ConsolidatedInvoiceItem {
  final String description;
  final double unitPrice;
  double quantity;
  final String? unit;
  double discount;
  final double? purchasePrice;

  _ConsolidatedInvoiceItem({
    required this.description,
    required this.unitPrice,
    required this.quantity,
    this.unit,
    required this.discount,
    this.purchasePrice,
  });
}

class _ItemControllers {
  String? productId;
  final TextEditingController desc;
  final TextEditingController price;
  final TextEditingController qty;
  final TextEditingController unit;
  final TextEditingController discount;
  final FocusNode descFocus;
  final FocusNode priceFocus;
  final FocusNode qtyFocus;
  final FocusNode discountFocus;
  final FocusNode unitFocus;
  double? purchasePrice;
  double? maxQuantity;

  /// Pre-fill from an existing InvoiceItem (edit mode).
  _ItemControllers.fromItem(InvoiceItem item)
    : productId = null,
      desc = TextEditingController(text: item.description),
      price = TextEditingController(text: item.unitPrice.toSmartAmount()),
      qty = TextEditingController(text: item.quantity.toSmartAmount()),
      unit = TextEditingController(text: item.unit ?? ''),
      discount = TextEditingController(
        text: item.discountAmount > 0
            ? item.discountAmount.toSmartAmount()
            : '0',
      ),
      descFocus = FocusNode(),
      priceFocus = FocusNode(),
      qtyFocus = FocusNode(),
      discountFocus = FocusNode(),
      unitFocus = FocusNode(),
      purchasePrice = item.purchasePrice,
      maxQuantity = null;

  _ItemControllers({
    this.productId,
    this.purchasePrice,
    this.maxQuantity,
    String? initialUnit,
  }) : desc = TextEditingController(),
       price = TextEditingController(),
       qty = TextEditingController(text: '1'),
       unit = TextEditingController(text: initialUnit ?? ''),
       discount = TextEditingController(text: '0'),
       descFocus = FocusNode(),
       priceFocus = FocusNode(),
       qtyFocus = FocusNode(),
       discountFocus = FocusNode(),
       unitFocus = FocusNode();

  void dispose() {
    desc.dispose();
    price.dispose();
    qty.dispose();
    unit.dispose();
    discount.dispose();
    descFocus.dispose();
    priceFocus.dispose();
    qtyFocus.dispose();
    discountFocus.dispose();
    unitFocus.dispose();
  }
}

class CreateInvoiceScreen extends StatefulWidget {
  /// If non-null, the screen opens in edit mode pre-filled with this invoice.
  final InvoiceEntity? invoiceToEdit;
  final bool isQuotation;

  const CreateInvoiceScreen({
    super.key,
    this.invoiceToEdit,
    this.isQuotation = false,
  });

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  // ── Pending invoice to track during submission ──────────────────────────────
  InvoiceEntity? _pendingInvoice;

  // ── Customer info ──────────────────────────────────────────────────────────
  CustomerEntity? _selectedCustomer;
  final _customerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ledgerController = TextEditingController();
  final _notesController = TextEditingController();
  final _overallDiscountController = TextEditingController();
  final FocusNode _customerFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _ledgerFocus = FocusNode();
  DateTime? _dueDate;
  DateTime? _invoiceDate;

  // ── Line items ─────────────────────────────────────────────────────────────
  final List<_ItemControllers> _itemControllers = [];
  List<InventoryProductEntity> _availableProducts = [];

  // ── Derived totals ─────────────────────────────────────────────────────────
  /// Raw subtotal of all items before ANY discounts (sum of qty * price).
  double get _rawSubtotal {
    double sum = 0;
    for (final ctrl in _itemControllers) {
      final qty = double.tryParse(ctrl.qty.text) ?? 1.0;
      final price = double.tryParse(ctrl.price.text) ?? 0.0;
      sum += (qty * price);
    }
    return sum;
  }

  /// Sum of all discounts applied individually to line items.
  double get _itemsDiscount {
    double sum = 0;
    for (final ctrl in _itemControllers) {
      final qty = double.tryParse(ctrl.qty.text) ?? 1.0;
      final price = double.tryParse(ctrl.price.text) ?? 0.0;
      final itemDiscount = double.tryParse(ctrl.discount.text) ?? 0.0;
      final itemSubtotal = qty * price;
      sum += itemDiscount.clamp(0.0, itemSubtotal);
    }
    return sum;
  }

  double get _overallDiscount =>
      double.tryParse(_overallDiscountController.text) ?? 0.0;

  /// Combined total discount (item discounts + overall discount).
  double get _totalDiscount => _itemsDiscount + _overallDiscount;

  double get _grandTotal {
    final net = _rawSubtotal - _totalDiscount;
    return net > 0 ? net : 0.0;
  }

  bool get _isEditMode => widget.invoiceToEdit != null;
  bool get _isQuotation =>
      widget.isQuotation || (widget.invoiceToEdit?.isQuotation ?? false);

  bool get _isCustomerRestricted {
    if (CustomerDataMasker.canViewCustomerPhone) return false;
    if (_selectedCustomer != null) return true;
    if (_isEditMode &&
        widget.invoiceToEdit?.customerName != null &&
        widget.invoiceToEdit!.customerName!.trim().isNotEmpty &&
        _customerController.text.trim() ==
            widget.invoiceToEdit!.customerName!.trim()) {
      return true;
    }
    return false;
  }

  void _onCustomerTextChanged() {
    if (_selectedCustomer != null &&
        _customerController.text.trim() != _selectedCustomer!.name.trim()) {
      setState(() {
        _selectedCustomer = null;
        if (!CustomerDataMasker.canViewCustomerPhone) {
          _phoneController.clear();
          _ledgerController.clear();
        }
      });
    } else if (_isEditMode &&
        widget.invoiceToEdit?.customerName != null &&
        _customerController.text.trim() !=
            widget.invoiceToEdit!.customerName!.trim()) {
      if (!CustomerDataMasker.canViewCustomerPhone &&
          (_phoneController.text.contains('•') ||
              _ledgerController.text.contains('•'))) {
        setState(() {
          _phoneController.clear();
          _ledgerController.clear();
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _customerController.addListener(_onCustomerTextChanged);
    final uid = AppStrings.userToken;
    if (uid.isNotEmpty) {
      context.read<CustomerCubit>().fetchCustomers(uid);
    }
    if (BusinessProfileService.instance.cachedProfile == null) {
      BusinessProfileService.instance.getProfile().then((profile) {
        if (mounted && profile != null) {
          setState(() {});
        }
      });
    }
    if (_isEditMode) {
      final inv = widget.invoiceToEdit!;
      _customerController.text = inv.customerName ?? '';
      if (CustomerDataMasker.canViewCustomerPhone) {
        _phoneController.text = inv.customerPhone ?? '';
        _ledgerController.text = inv.ledgerNumber ?? '';
      } else {
        _phoneController.text =
            (inv.customerPhone != null && inv.customerPhone!.isNotEmpty)
            ? '••••••••••'
            : '';
        _ledgerController.text =
            (inv.ledgerNumber != null && inv.ledgerNumber!.isNotEmpty)
            ? '••••••'
            : '';
      }
      _notesController.text = inv.notes ?? '';
      _overallDiscountController.text = inv.discountAmount > 0
          ? inv.discountAmount.toSmartAmount()
          : '';
      _dueDate = inv.dueDate;
      _invoiceDate = inv.createdAt;
      for (final item in inv.items) {
        final ctrl = _ItemControllers.fromItem(item);
        _itemControllers.add(ctrl);
        _initialAllocatedQuantities[item.description.trim().toLowerCase()] =
            item.quantity;
      }
      if (_itemControllers.isEmpty) _addItem();
    } else {
      _addItem(); // Start with one empty item row
    }
    _loadAvailableProducts();
  }

  final Map<String, double> _initialAllocatedQuantities = {};

  double _maxQuantityFor(InventoryProductEntity product) {
    final initial = _initialAllocatedQuantities[product.id] ??
        _initialAllocatedQuantities[product.name.trim().toLowerCase()] ??
        0.0;
    if (_isEditMode) {
      return product.currentQuantity + initial;
    } else {
      return product.currentQuantity >= initial
          ? product.currentQuantity
          : (initial > 0 ? initial : product.currentQuantity);
    }
  }

  String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll(RegExp(r'[إأآا]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ئ', 'ي')
        .replaceAll('ؤ', 'و')
        .trim()
        .toLowerCase();
  }

  InventoryProductEntity? _findProduct(_ItemControllers ctrl) {
    if (ctrl.productId != null && ctrl.productId!.isNotEmpty) {
      final byId = _availableProducts.where((p) => p.id == ctrl.productId);
      if (byId.isNotEmpty) return byId.first;
    }
    final desc = ctrl.desc.text.trim().toLowerCase();
    final normDesc = _normalizeArabic(ctrl.desc.text);
    if (desc.isNotEmpty) {
      final byName = _availableProducts.where(
        (p) =>
            p.name.trim().toLowerCase() == desc ||
            _normalizeArabic(p.name) == normDesc,
      );
      if (byName.isNotEmpty) return byName.first;
    }
    return null;
  }

  Future<void> _loadAvailableProducts() async {
    try {
      final localDataSource = GetIt.I<InventoryLocalDataSource>();
      var products = await localDataSource.getProducts();
      if (products.isEmpty) {
        final repo = GetIt.I<InventoryRepository>();
        await repo.fetchAllProductsFromRemoteWithoutLimit();
        products = await localDataSource.getProducts();
      }
      if (mounted) {
        setState(() {
          _availableProducts = products;
          for (final ctrl in _itemControllers) {
            final p = _findProduct(ctrl);
            if (p != null) {
              ctrl.productId ??= p.id;
              ctrl.purchasePrice ??= p.purchasePrice;
              final descKey = ctrl.desc.text.trim().toLowerCase();
              if (_initialAllocatedQuantities.containsKey(descKey)) {
                _initialAllocatedQuantities[p.id] =
                    _initialAllocatedQuantities[descKey]!;
              }
              ctrl.maxQuantity = _maxQuantityFor(p);
            }
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _customerController.removeListener(_onCustomerTextChanged);
    _customerController.dispose();
    _phoneController.dispose();
    _ledgerController.dispose();
    _notesController.dispose();
    _overallDiscountController.dispose();
    _customerFocus.dispose();
    _phoneFocus.dispose();
    _ledgerFocus.dispose();
    for (final c in _itemControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addItem({bool autoFocus = false}) {
    final newCtrl = _ItemControllers();
    setState(() {
      _itemControllers.add(newCtrl);
    });
    if (autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          newCtrl.descFocus.requestFocus();
        }
      });
    }
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
        _selectedCustomer = null;
      });
      // Smart auto focus after contact selection:
      if (_ledgerController.text.trim().isEmpty) {
        _ledgerFocus.requestFocus();
      } else if (_itemControllers.isNotEmpty) {
        _itemControllers.first.descFocus.requestFocus();
      }
    }
  }

  Map<String, double> get _selectedProductQuantitiesMap {
    final Map<String, double> map = {};
    for (final ctrl in _itemControllers) {
      final pid = ctrl.productId;
      final q = double.tryParse(ctrl.qty.text.trim()) ?? 0.0;
      if (pid != null && pid.isNotEmpty && q > 0) {
        map[pid] = (map[pid] ?? 0.0) + q;
      }
    }
    return map;
  }

  void _handleProductSelected(
    _ItemControllers targetCtrl,
    InventoryProductEntity product, {
    bool isExternalScanner = false,
  }) {
    final index = _itemControllers.indexOf(targetCtrl);
    if (index == -1) {
      // Controller has already been removed or replaced, ignore stale call
      return;
    }

    // Check if this product is already in another row
    int existingIndex = -1;
    final normalizedSelectedName = _normalizeArabic(product.name);

    for (int j = 0; j < _itemControllers.length; j++) {
      if (j == index) continue;
      final ctrl = _itemControllers[j];
      final isSameId = ctrl.productId != null && ctrl.productId == product.id;
      final isSameName =
          ctrl.desc.text.trim().isNotEmpty &&
          _normalizeArabic(ctrl.desc.text) == normalizedSelectedName;
      if (isSameId || isSameName) {
        existingIndex = j;
        break;
      }
    }

    if (existingIndex != -1) {
      // Duplicate product detected -> merge into existing row
      final existingCtrl = _itemControllers[existingIndex];
      final currentCtrl = targetCtrl;

      final existingQty = double.tryParse(existingCtrl.qty.text.trim()) ?? 1.0;
      final currentQty = double.tryParse(currentCtrl.qty.text.trim()) ?? 1.0;
      final addQty = currentQty > 0 ? currentQty : 1.0;
      final maxAllowed = _maxQuantityFor(product);
      final targetQty = existingQty + addQty;

      existingCtrl.productId = product.id;
      existingCtrl.purchasePrice ??= product.purchasePrice;
      existingCtrl.maxQuantity = maxAllowed;
      if (existingCtrl.price.text.trim().isEmpty ||
          existingCtrl.price.text.trim() == '0') {
        existingCtrl.price.text = product.sellingPrice.toSmartAmount();
      }
      if (existingCtrl.unit.text.trim().isEmpty &&
          product.unit.trim().isNotEmpty) {
        existingCtrl.unit.text = product.unit.trim();
      }

      // ignore: unnecessary_null_comparison
      if (!_isQuotation && maxAllowed != null && maxAllowed > 0) {
        if (existingQty >= maxAllowed) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.invoiceItemAlreadyAddedMaxStock.tr(
                  namedArgs: {
                    'name': product.name,
                    'index': '${existingIndex + 1}',
                    'max': maxAllowed.toSmartAmount(),
                  },
                ),
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        } else if (targetQty > maxAllowed) {
          existingCtrl.qty.text = maxAllowed.toSmartAmount();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.invoiceItemAlreadyAddedQtyClamped.tr(
                  namedArgs: {
                    'name': product.name,
                    'index': '${existingIndex + 1}',
                    'max': maxAllowed.toSmartAmount(),
                  },
                ),
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        } else {
          existingCtrl.qty.text = targetQty.toSmartAmount();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.invoiceItemAlreadyAddedQtyUpdated.tr(
                  namedArgs: {
                    'name': product.name,
                    'index': '${existingIndex + 1}',
                    'qty': targetQty.toSmartAmount(),
                  },
                ),
              ),
              backgroundColor: AppColors.primaryColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        existingCtrl.qty.text = targetQty.toSmartAmount();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.invoiceItemAlreadyAddedQtyUpdated.tr(
                namedArgs: {
                  'name': product.name,
                  'index': '${existingIndex + 1}',
                  'qty': targetQty.toSmartAmount(),
                },
              ),
            ),
            backgroundColor: AppColors.primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Remove the redundant current row
      setState(() {
        if (_itemControllers.length > 1) {
          _itemControllers.remove(currentCtrl);
          currentCtrl.dispose();
        } else {
          currentCtrl.desc.clear();
          currentCtrl.price.clear();
          currentCtrl.qty.text = '1';
          currentCtrl.productId = null;
        }
      });

      if (isExternalScanner) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ItemControllers? emptyCtrl;
          for (final c in _itemControllers) {
            if (c.desc.text.trim().isEmpty && c.price.text.trim().isEmpty) {
              emptyCtrl = c;
              break;
            }
          }
          if (emptyCtrl != null && emptyCtrl.descFocus.canRequestFocus) {
            emptyCtrl.descFocus.requestFocus();
          } else {
            _addItem(autoFocus: true);
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (existingCtrl.qtyFocus.canRequestFocus) {
            existingCtrl.qtyFocus.requestFocus();
            existingCtrl.qty.selection = TextSelection(
              baseOffset: 0,
              extentOffset: existingCtrl.qty.text.length,
            );
          }
        });
      }
      return;
    }

    // Normal fresh selection for row
    final ctrl = targetCtrl;
    setState(() {
      ctrl.productId = product.id;
      ctrl.desc.text = product.name;
      ctrl.desc.selection = TextSelection.fromPosition(
        TextPosition(offset: product.name.length),
      );
      ctrl.price.text = product.sellingPrice.toSmartAmount();
      if (product.unit.trim().isNotEmpty) {
        ctrl.unit.text = product.unit.trim();
      }
      final currentQty = double.tryParse(ctrl.qty.text.trim()) ?? 0.0;
      final maxQty = _maxQuantityFor(product);
      if (currentQty <= 0) {
        ctrl.qty.text = '1';
      // ignore: unnecessary_null_comparison
      } else if (maxQty != null && maxQty > 0 && currentQty > maxQty) {
        ctrl.qty.text = maxQty.toSmartAmount();
      }
      ctrl.purchasePrice = product.purchasePrice;
      ctrl.maxQuantity = maxQty;
    });

    if (isExternalScanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentIndex = _itemControllers.indexOf(ctrl);
        if (currentIndex != -1 && currentIndex + 1 < _itemControllers.length) {
          final nextCtrl = _itemControllers[currentIndex + 1];
          if (nextCtrl.descFocus.canRequestFocus) {
            nextCtrl.descFocus.requestFocus();
            return;
          }
        }
        _addItem(autoFocus: true);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ctrl.priceFocus.canRequestFocus) {
          ctrl.priceFocus.requestFocus();
          if (ctrl.price.text.isNotEmpty) {
            ctrl.price.selection = TextSelection(
              baseOffset: 0,
              extentOffset: ctrl.price.text.length,
            );
          }
        }
      });
    }
  }

  void _openMultiInventoryPicker() {
    final Map<String, double> existingQuantities = {};
    final Set<String> initialProductIds = {};
    final Set<String> initialProductNames = {};

    for (final ctrl in _itemControllers) {
      final name = ctrl.desc.text.trim();
      final qty = double.tryParse(ctrl.qty.text.trim()) ?? 0.0;
      if (name.isNotEmpty && qty > 0) {
        if (ctrl.productId != null && ctrl.productId!.isNotEmpty) {
          existingQuantities[ctrl.productId!] =
              (existingQuantities[ctrl.productId!] ?? 0.0) + qty;
          initialProductIds.add(ctrl.productId!);
        }
        existingQuantities[name] =
            (existingQuantities[name] ?? 0.0) + qty;
        initialProductNames.add(_normalizeArabic(name));
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MultiInventoryPickerBottomSheet(
        initialSelectedQuantities: existingQuantities.isNotEmpty
            ? existingQuantities
            : null,
        isEditMode: _isEditMode,
        confirmButtonText: AppStrings.confirmSelection.tr(),
        onItemsConfirmed: (selectedItems) {
          setState(() {
            // Clean up any empty/blank placeholder rows
            _itemControllers.removeWhere((ctrl) {
              final isBlank = ctrl.desc.text.trim().isEmpty &&
                  ctrl.price.text.trim().isEmpty;
              if (isBlank) {
                ctrl.dispose();
                return true;
              }
              return false;
            });

            final returnedProductIds = selectedItems
                .map((e) => e.product.id)
                .toSet();
            final returnedProductNames = selectedItems
                .map((e) => _normalizeArabic(e.product.name))
                .toSet();

            final Map<String, SelectedInventoryItem> itemsByProdId = {
              for (final item in selectedItems) item.product.id: item,
            };
            final Map<String, SelectedInventoryItem> itemsByName = {
              for (final item in selectedItems)
                _normalizeArabic(item.product.name): item,
            };

            // Remove inventory items that were previously passed but user deselected them in picker
            _itemControllers.removeWhere((ctrl) {
              final isInventoryItem =
                  (ctrl.productId != null &&
                      initialProductIds.contains(ctrl.productId)) ||
                  initialProductNames.contains(
                    _normalizeArabic(ctrl.desc.text),
                  );
              if (isInventoryItem) {
                final stillSelected =
                    (ctrl.productId != null &&
                        returnedProductIds.contains(ctrl.productId)) ||
                    returnedProductNames.contains(
                      _normalizeArabic(ctrl.desc.text),
                    );
                if (!stillSelected) {
                  ctrl.dispose();
                  return true;
                }
              }
              return false; // Keep custom manual items intact
            });

            // Update existing matched controllers & remove any duplicate rows
            final matchedProductIds = <String>{};
            final toRemoveIndices = <int>[];

            for (int i = 0; i < _itemControllers.length; i++) {
              final ctrl = _itemControllers[i];
              SelectedInventoryItem? matchedItem;
              if (ctrl.productId != null &&
                  itemsByProdId.containsKey(ctrl.productId)) {
                matchedItem = itemsByProdId[ctrl.productId];
              } else if (itemsByName.containsKey(
                _normalizeArabic(ctrl.desc.text),
              )) {
                matchedItem = itemsByName[_normalizeArabic(ctrl.desc.text)];
              }

              if (matchedItem != null) {
                if (matchedProductIds.contains(matchedItem.product.id)) {
                  // Duplicate row for this product! Mark for removal
                  toRemoveIndices.add(i);
                } else {
                  ctrl.productId = matchedItem.product.id;
                  ctrl.desc.text = matchedItem.product.name;
                  ctrl.qty.text = matchedItem.quantity.toSmartAmount();
                  ctrl.purchasePrice = matchedItem.product.purchasePrice;
                  ctrl.maxQuantity = _maxQuantityFor(matchedItem.product);
                  if (ctrl.price.text.trim().isEmpty ||
                      ctrl.price.text.trim() == '0') {
                    ctrl.price.text = matchedItem.product.sellingPrice
                        .toSmartAmount();
                  }
                  if (ctrl.unit.text.trim().isEmpty &&
                      matchedItem.product.unit.isNotEmpty) {
                    ctrl.unit.text = matchedItem.product.unit;
                  }
                  matchedProductIds.add(matchedItem.product.id);
                }
              }
            }

            // Remove any extra duplicate rows in reverse order
            for (final idx in toRemoveIndices.reversed) {
              _itemControllers[idx].dispose();
              _itemControllers.removeAt(idx);
            }

            // Add newly selected products
            for (final item in selectedItems) {
              if (!matchedProductIds.contains(item.product.id)) {
                final newCtrl = _ItemControllers(
                  productId: item.product.id,
                  purchasePrice: item.product.purchasePrice,
                  maxQuantity: _maxQuantityFor(item.product),
                  initialUnit: item.product.unit,
                );
                newCtrl.desc.text = item.product.name;
                newCtrl.price.text = item.product.sellingPrice.toSmartAmount();
                newCtrl.qty.text = item.quantity.toSmartAmount();
                _itemControllers.add(newCtrl);
                matchedProductIds.add(item.product.id);
              }
            }

            if (_itemControllers.isEmpty) {
              _addItem();
            }
          });
        },
      ),
    );
  }

  Future<void> _submit(
    BuildContext context, {
    bool convertToInvoice = false,
  }) async {
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

    // Consolidate any duplicate items (by productId or normalized description + price + unit)
    final Map<String, _ConsolidatedInvoiceItem> consolidatedMap = {};
    for (final ctrl in validItems) {
      final key = (ctrl.productId != null && ctrl.productId!.isNotEmpty)
          ? 'id_${ctrl.productId}'
          : 'desc_${_normalizeArabic(ctrl.desc.text)}_${ctrl.price.text.trim()}_${ctrl.unit.text.trim()}';

      final price = double.tryParse(ctrl.price.text.trim()) ?? 0.0;
      final qty = double.tryParse(ctrl.qty.text.trim()) ?? 1.0;
      final itemDiscount = double.tryParse(ctrl.discount.text.trim()) ?? 0.0;

      if (consolidatedMap.containsKey(key)) {
        final existing = consolidatedMap[key]!;
        existing.quantity += qty;
        existing.discount += itemDiscount;
      } else {
        consolidatedMap[key] = _ConsolidatedInvoiceItem(
          description: ctrl.desc.text.trim(),
          unitPrice: price,
          quantity: qty,
          unit: ctrl.unit.text.trim().isNotEmpty ? ctrl.unit.text.trim() : null,
          discount: itemDiscount,
          purchasePrice: ctrl.purchasePrice,
        );
      }
    }

    final items = consolidatedMap.values.toList().asMap().entries.map((entry) {
      final item = entry.value;
      final subtotal = item.unitPrice * item.quantity;
      final discountRate = subtotal > 0
          ? (item.discount / subtotal).clamp(0.0, 1.0)
          : 0.0;

      return InvoiceItem(
        id: _isEditMode
            ? (widget.invoiceToEdit!.items.length > entry.key
                  ? widget.invoiceToEdit!.items[entry.key].id
                  : 'item_${entry.key}')
            : 'item_${entry.key}',
        description: item.description,
        unitPrice: item.unitPrice,
        quantity: item.quantity,
        unit: item.unit,
        discountRate: discountRate,
        purchasePrice: item.purchasePrice,
      );
    }).toList();

    final overallDiscount =
        double.tryParse(_overallDiscountController.text) ?? 0.0;

    final bool isRestricted = _isCustomerRestricted;
    final phoneToSave = isRestricted
        ? (_selectedCustomer?.phoneNumber ??
              (_isEditMode ? widget.invoiceToEdit?.customerPhone : null))
        : (_phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null);
    final ledgerToSave = isRestricted
        ? (_selectedCustomer?.ledgerNumber ??
              (_isEditMode ? widget.invoiceToEdit?.ledgerNumber : null))
        : (_ledgerController.text.trim().isNotEmpty
              ? _ledgerController.text.trim()
              : null);

    if (_isEditMode) {
      // Edit mode — patch mutable fields, preserve payments/status
      final updated = widget.invoiceToEdit!.copyWith(
        customerName: customerName,
        customerPhone: phoneToSave,
        ledgerNumber: ledgerToSave,
        items: items,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        discountAmount: overallDiscount,
        createdAt: _invoiceDate ?? DateTime.now(),
        lastUpdatedAt: DateTime.now(),
        dueDate: _isQuotation ? null : _dueDate,
        clearDueDate: _isQuotation || _dueDate == null,
      );

      if (convertToInvoice && _isQuotation) {
        final connectivityState = context.read<ConnectivityCubit>().state;
        if (connectivityState is ConnectivityDisconnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.noInternetConnection.tr()),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        final result = await ConvertQuotationDialog.show(context, updated);
        if (result != null && result.confirmed && context.mounted) {
          context.read<InvoiceCubit>().convertQuotationToInvoice(
            quotation: updated,
            dueDate: result.dueDate,
          );
        }
        return;
      }

      context.read<InvoiceCubit>().updateInvoice(
        updated,
        previous: widget.invoiceToEdit,
      );
    } else {
      // Create mode
      final profileTaxRate =
          BusinessProfileService.instance.cachedProfile?.taxRate;
      final invoice = InvoiceEntity(
        id: '',
        uid: uid,
        customerName: customerName,
        customerPhone: phoneToSave,
        ledgerNumber: ledgerToSave,
        items: items,
        status: _isQuotation ? InvoiceStatus.quotation : InvoiceStatus.pending,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        discountAmount: overallDiscount,
        createdAt: _invoiceDate ?? DateTime.now(),
        lastUpdatedAt: DateTime.now(),
        dueDate: _isQuotation ? null : _dueDate,
        taxRate: profileTaxRate,
        creatorEmployeeUid:
            AppStrings.isEmployee && AppStrings.employeeAuthUid.isNotEmpty
            ? AppStrings.employeeAuthUid
            : null,
        creatorEmployeeName:
            AppStrings.isEmployee && AppStrings.loggedInEmployeeName.isNotEmpty
            ? AppStrings.loggedInEmployeeName
            : null,
      );

      _pendingInvoice = invoice;
      context.read<InvoiceCubit>().createInvoice(invoice);
    }
  }

  Future<void> _pickInvoiceDate() async {
    final DateTime minDate = DateTime(2000);
    final DateTime initialDate = _invoiceDate ?? DateTime.now();
    final DateTime finalInitialDate = initialDate.isBefore(minDate)
        ? minDate
        : initialDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: finalInitialDate,
      firstDate: minDate,
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: AppColors.isDark
                ? ColorScheme.dark(primary: AppColors.primaryColor)
                : ColorScheme.light(
                    primary: AppColors.primaryColor,
                    onPrimary: AppColors.white,
                    onSurface: AppColors.black,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        final originalTime = _invoiceDate ?? DateTime.now();
        _invoiceDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          originalTime.hour,
          originalTime.minute,
          originalTime.second,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final canViewCustomerPhone = CustomerDataMasker.canViewCustomerPhone;
    final isRestricted = _isCustomerRestricted;
    final effectiveTaxRate = _isEditMode
        ? (widget.invoiceToEdit?.taxRate ??
              BusinessProfileService.instance.cachedProfile?.taxRate ??
              0.0)
        : (BusinessProfileService.instance.cachedProfile?.taxRate ?? 0.0);

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
              phoneNumber: _pendingInvoice?.customerPhone,
              ledgerNumber: _pendingInvoice?.ledgerNumber,
            );
          }
          // ──────────────────────────────────────────────────────────────────

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isQuotation
                    ? AppStrings.quotationCreatedSuccess.tr()
                    : AppStrings.invoiceCreateSuccess.tr(),
              ),
              backgroundColor: AppColors.success,
            ),
          );
          if (_pendingInvoice != null) {
            Navigator.of(context).pop({
              'invoice': _pendingInvoice!.copyWith(
                id: state.invoiceId,
                status: _isQuotation
                    ? InvoiceStatus.quotation
                    : InvoiceStatus.pending,
              ),
              'showPaymentImmediately': !_isQuotation,
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
        } else if (state is InvoiceConvertSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.quotationConvertedSuccess.tr()),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
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
                ? (_isQuotation
                      ? AppStrings.editQuotation.tr()
                      : AppStrings.invoiceEditTitle.tr())
                : (_isQuotation
                      ? AppStrings.createQuotation.tr()
                      : AppStrings.createInvoice.tr()),
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
                maxWidth: isDesktop ? 1000 : double.infinity,
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
                            CreateInvoiceSectionHeader(
                              title: AppStrings.invoiceCustomerSection.tr(),
                            ),
                            const SizedBox(height: 12),
                            CreateInvoiceCustomerField(
                              controller: _customerController,
                              focusNode: _customerFocus,
                              autofocus: !_isEditMode,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) {
                                if (canViewCustomerPhone && !isRestricted) {
                                  _phoneFocus.requestFocus();
                                } else if (_itemControllers.isNotEmpty) {
                                  _itemControllers.first.descFocus
                                      .requestFocus();
                                }
                              },
                              hint: AppStrings.customerNameHint.tr(),
                              label: AppStrings.customerName.tr(),
                              onContactTap: _pickContact,
                              canPickContact: !isRestricted,
                              onSelected: (customer) {
                                setState(() {
                                  _selectedCustomer = customer;
                                  if (canViewCustomerPhone) {
                                    _phoneController.text =
                                        customer.phoneNumber ?? '';
                                    _ledgerController.text =
                                        customer.ledgerNumber ?? '';
                                  } else {
                                    _phoneController.text =
                                        (customer.phoneNumber != null &&
                                                customer.phoneNumber!.isNotEmpty)
                                            ? '••••••••••'
                                            : '';
                                    _ledgerController.text =
                                        (customer.ledgerNumber != null &&
                                                customer.ledgerNumber!.isNotEmpty)
                                            ? '••••••'
                                            : '';
                                  }
                                });
                                // Smart auto focus jump:
                                final hasPhone =
                                    _phoneController.text.trim().isNotEmpty;
                                final hasLedger =
                                    _ledgerController.text.trim().isNotEmpty;
                                if (!isRestricted &&
                                    canViewCustomerPhone &&
                                    !hasPhone) {
                                  _phoneFocus.requestFocus();
                                } else if (!isRestricted && !hasLedger) {
                                  _ledgerFocus.requestFocus();
                                } else if (_itemControllers.isNotEmpty) {
                                  _itemControllers.first.descFocus
                                      .requestFocus();
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            CreateInvoiceSimpleField(
                              controller: _phoneController,
                              focusNode: _phoneFocus,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) {
                                _ledgerFocus.requestFocus();
                              },
                              hint: isRestricted
                                  ? AppStrings.permRestrictedData.tr()
                                  : AppStrings.invoicePhoneHint.tr(),
                              label: AppStrings.customerPhone.tr(),
                              isNumber: true,
                              readOnly: isRestricted,
                              obscureText:
                                  isRestricted &&
                                  _phoneController.text.isNotEmpty,
                              enableInteractiveSelection: !isRestricted,
                              suffixIcon: isRestricted
                                  ? Tooltip(
                                      message: AppStrings.permRestrictedData
                                          .tr(),
                                      child: Icon(
                                        Icons.visibility_off_outlined,
                                        size: 20,
                                        color: AppColors.blackLight.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            CreateInvoiceSimpleField(
                              controller: _ledgerController,
                              focusNode: _ledgerFocus,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) {
                                if (_itemControllers.isNotEmpty) {
                                  _itemControllers.first.descFocus
                                      .requestFocus();
                                }
                              },
                              hint: isRestricted
                                  ? AppStrings.permRestrictedData.tr()
                                  : AppStrings.invoiceLedgerHint.tr(),
                              label: AppStrings.ledgerNumber.tr(),
                              readOnly: isRestricted,
                              obscureText:
                                  isRestricted &&
                                  _ledgerController.text.isNotEmpty,
                              enableInteractiveSelection: !isRestricted,
                              suffixIcon: isRestricted
                                  ? Tooltip(
                                      message: AppStrings.permRestrictedData
                                          .tr(),
                                      child: Icon(
                                        Icons.visibility_off_outlined,
                                        size: 20,
                                        color: AppColors.blackLight.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 24),

                            // ── Section: Line Items ──────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CreateInvoiceSectionHeader(
                                  title: AppStrings.invoiceItemsSection.tr(),
                                ),
                                if (AppStrings.isVip)
                                  InkWell(
                                    onTap: _openMultiInventoryPicker,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.primaryColor
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.inventory_2_rounded,
                                            size: 16,
                                            color: AppColors.primaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            AppStrings.selectFromInventory.tr(),
                                            style: TextStyles.customStyle(
                                              color: AppColors.primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Line item rows
                            for (int i = 0; i < _itemControllers.length; i++)
                              InvoiceItemRow(
                                key: ObjectKey(_itemControllers[i]),
                                index: i,
                                descController: _itemControllers[i].desc,
                                priceController: _itemControllers[i].price,
                                qtyController: _itemControllers[i].qty,
                                unitController: _itemControllers[i].unit,
                                discountController:
                                    _itemControllers[i].discount,
                                descFocusNode: _itemControllers[i].descFocus,
                                priceFocusNode: _itemControllers[i].priceFocus,
                                qtyFocusNode: _itemControllers[i].qtyFocus,
                                discountFocusNode:
                                    _itemControllers[i].discountFocus,
                                unitFocusNode: _itemControllers[i].unitFocus,
                                availableProducts: _availableProducts,
                                selectedProductQuantities:
                                    _selectedProductQuantitiesMap,
                                productId: _itemControllers[i].productId,
                                maxQuantity: _itemControllers[i].maxQuantity,
                                onProductSelected: (product, {isExternalScanner = false}) =>
                                    _handleProductSelected(
                                      _itemControllers[i],
                                      product,
                                      isExternalScanner: isExternalScanner,
                                    ),
                                onNextItem: () {
                                  if (i + 1 < _itemControllers.length) {
                                    _itemControllers[i + 1].descFocus
                                        .requestFocus();
                                  } else {
                                    final currentDesc =
                                        _itemControllers[i].desc.text.trim();
                                    final currentPrice =
                                        _itemControllers[i].price.text.trim();
                                    if (currentDesc.isNotEmpty ||
                                        currentPrice.isNotEmpty) {
                                      _addItem(autoFocus: true);
                                    } else {
                                      FocusScope.of(context).unfocus();
                                    }
                                  }
                                },
                                purchasePrice:
                                    _itemControllers[i].purchasePrice,
                                taxRate: effectiveTaxRate,
                                isQuotation: _isQuotation,
                                onRemove: () => _removeItem(i),
                                onChanged: () => setState(() {}),
                              ),

                            const SizedBox(height: 16),
                            Center(
                              child: TextButton.icon(
                                onPressed: () => _addItem(autoFocus: true),
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
                            CreateInvoiceSimpleField(
                              controller: _overallDiscountController,
                              hint: '0',
                              label: AppStrings.overallDiscountLabel.tr(),
                              isNumber: true,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),

                            // ── Grand Total ──────────────────────────────────
                            CreateInvoiceTotalCard(
                              rawSubtotal: _rawSubtotal,
                              totalDiscount: _totalDiscount,
                              grandTotal: _grandTotal,
                              taxRate: effectiveTaxRate,
                              isQuotation: _isQuotation,
                            ),
                            const SizedBox(height: 20),

                            // ── Payment Due Date (Hidden for Quotation) ───────
                            if (!_isQuotation &&
                                !(_isEditMode &&
                                    widget.invoiceToEdit!.status ==
                                        InvoiceStatus.paid) &&
                                _grandTotal > 0) ...[
                              QuickDueDateSelector(
                                selectedDate: _dueDate,
                                onDateChanged: (date) {
                                  setState(() {
                                    _dueDate = date;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),
                            ],

                            // ── Notes ────────────────────────────────────────
                            CreateInvoiceSectionHeader(
                              title: AppStrings.invoiceNotesSection.tr(),
                            ),
                            const SizedBox(height: 12),
                            CreateInvoiceNotesField(
                              controller: _notesController,
                            ),
                            const SizedBox(height: 24),

                            // ── Invoice Date ─────────────────────────────────
                            CreateInvoiceSectionHeader(
                              title: AppStrings.invoiceDate.tr(),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _pickInvoiceDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.disabledColor.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          color: _invoiceDate != null
                                              ? AppColors.primaryColor
                                              : AppColors.disabledColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _invoiceDate != null
                                              ? DateFormatter.formatNumericDate(
                                                  _invoiceDate!,
                                                )
                                              : AppStrings.notSet.tr(),
                                          style: TextStyles.customStyle(
                                            color: _invoiceDate != null
                                                ? AppColors.textColor
                                                : AppColors.disabledColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_invoiceDate != null)
                                      IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: AppColors.error,
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          setState(() {
                                            _invoiceDate = null;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // ── Submit Button ────────────────────────────────
                            QuickActionButton(
                              label: _isEditMode
                                  ? AppStrings.invoiceSaveEdit.tr()
                                  : (_isQuotation
                                        ? AppStrings.saveQuotation.tr()
                                        : AppStrings.invoiceSubmit.tr()),
                              icon: _isEditMode
                                  ? Icons.save_rounded
                                  : (_isQuotation
                                        ? Icons.request_quote_rounded
                                        : Icons.receipt_long_rounded),
                              onPressed: isLoading
                                  ? null
                                  : () => _submit(context),
                            ),
                            if (_isEditMode &&
                                _isQuotation &&
                                PermissionService.instance.hasPermission(
                                  AppPermissions.invoicesCreate,
                                )) ...[
                              const SizedBox(height: 12),
                              QuickActionButton(
                                label: AppStrings.saveAndConvertToInvoice.tr(),
                                icon: Icons.published_with_changes_rounded,
                                onPressed: isLoading
                                    ? null
                                    : () => _submit(
                                        context,
                                        convertToInvoice: true,
                                      ),
                              ),
                            ],
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
