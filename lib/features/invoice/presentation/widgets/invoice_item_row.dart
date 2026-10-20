import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:tahsel/core/extensions/number_extensions.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/inventory/data/datasources/inventory_local_data_source.dart';
import 'package:tahsel/features/inventory/domain/entities/inventory_product_entity.dart';
import 'package:tahsel/features/inventory/presentation/widgets/barcode_scanner_dialog.dart';

typedef OnInvoiceItemProductSelected = void Function(
  InventoryProductEntity product, {
  bool isExternalScanner,
});

/// A single editable line-item row used inside the invoice form.
class InvoiceItemRow extends StatefulWidget {
  final int index;
  final TextEditingController descController;
  final TextEditingController priceController;
  final TextEditingController qtyController;
  final TextEditingController unitController;
  final TextEditingController discountController;
  final FocusNode? descFocusNode;
  final FocusNode? priceFocusNode;
  final FocusNode? qtyFocusNode;
  final FocusNode? discountFocusNode;
  final FocusNode? unitFocusNode;
  final List<InventoryProductEntity>? availableProducts;
  final OnInvoiceItemProductSelected? onProductSelected;
  final Map<String, double>? selectedProductQuantities;
  final VoidCallback? onNextItem;
  final String? productId;
  final double? maxQuantity;
  final double? purchasePrice;
  final double taxRate;
  final bool isQuotation;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const InvoiceItemRow({
    super.key,
    required this.index,
    required this.descController,
    required this.priceController,
    required this.qtyController,
    required this.unitController,
    required this.discountController,
    this.descFocusNode,
    this.priceFocusNode,
    this.qtyFocusNode,
    this.discountFocusNode,
    this.unitFocusNode,
    this.availableProducts,
    this.onProductSelected,
    this.selectedProductQuantities,
    this.onNextItem,
    this.productId,
    this.maxQuantity,
    this.purchasePrice,
    this.taxRate = 0.0,
    this.isQuotation = false,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<InvoiceItemRow> createState() => _InvoiceItemRowState();
}

class _InvoiceItemRowState extends State<InvoiceItemRow> {
  bool _isTotalExpanded = false;

  final LayerLink _layerLink = LayerLink();
  final GlobalKey _descFieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  List<InventoryProductEntity> _suggestions = [];
  List<InventoryProductEntity> _fallbackProducts = [];

  FocusNode? _ownedDescFocus;
  FocusNode? _ownedPriceFocus;
  FocusNode? _ownedQtyFocus;
  FocusNode? _ownedDiscountFocus;
  FocusNode? _ownedUnitFocus;

  FocusNode get _descFocus =>
      widget.descFocusNode ?? (_ownedDescFocus ??= FocusNode());
  FocusNode get _priceFocus =>
      widget.priceFocusNode ?? (_ownedPriceFocus ??= FocusNode());
  FocusNode get _qtyFocus =>
      widget.qtyFocusNode ?? (_ownedQtyFocus ??= FocusNode());
  FocusNode get _discountFocus =>
      widget.discountFocusNode ?? (_ownedDiscountFocus ??= FocusNode());
  FocusNode get _unitFocus =>
      widget.unitFocusNode ?? (_ownedUnitFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _descFocus.addListener(_onDescFocusChange);
    widget.descController.addListener(_onDescTextChanged);
    if (widget.availableProducts == null || widget.availableProducts!.isEmpty) {
      _loadFallbackProducts();
    }
  }

  @override
  void didUpdateWidget(covariant InvoiceItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.descController != widget.descController) {
      oldWidget.descController.removeListener(_onDescTextChanged);
      widget.descController.addListener(_onDescTextChanged);
    }
    if (oldWidget.descFocusNode != widget.descFocusNode) {
      (oldWidget.descFocusNode ?? _ownedDescFocus)?.removeListener(
        _onDescFocusChange,
      );
      _descFocus.addListener(_onDescFocusChange);
    }
  }

  @override
  void dispose() {
    try {
      _descFocus.removeListener(_onDescFocusChange);
    } catch (_) {}
    try {
      widget.descController.removeListener(_onDescTextChanged);
    } catch (_) {}
    _hideOverlay();
    _ownedDescFocus?.dispose();
    _ownedPriceFocus?.dispose();
    _ownedQtyFocus?.dispose();
    _ownedDiscountFocus?.dispose();
    _ownedUnitFocus?.dispose();
    super.dispose();
  }

  Future<void> _loadFallbackProducts() async {
    try {
      final local = GetIt.I<InventoryLocalDataSource>();
      final prods = await local.getProducts();
      if (mounted && prods.isNotEmpty) {
        setState(() {
          _fallbackProducts = prods;
        });
      }
    } catch (_) {}
  }

  void _onDescFocusChange() {
    if (!_descFocus.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_descFocus.hasFocus) {
          _hideOverlay();
        }
      });
    } else if (widget.descController.text.trim().isNotEmpty) {
      _updateSuggestions(widget.descController.text);
    }
  }

  bool get _isCameraScanSupported => kIsWeb || !Platform.isWindows;

  bool _isLikelyBarcode(String query) {
    final trimmed = query.trim();
    return RegExp(r'^[A-Za-z0-9_\-\.]{3,50}$').hasMatch(trimmed);
  }

  void _onDescTextChanged() {
    final rawText = widget.descController.text;
    if (rawText.contains('\n') || rawText.contains('\r')) {
      final cleaned = rawText.replaceAll('\r', '').replaceAll('\n', '').trim();
      widget.descController.text = cleaned;
      widget.descController.selection = TextSelection.fromPosition(
        TextPosition(offset: cleaned.length),
      );
      if (cleaned.isNotEmpty) {
        _handleScannedCode(cleaned, isExternalScanner: true).then((matched) {
          if (!matched && mounted) {
            if (_isLikelyBarcode(cleaned)) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppStrings.barcodeNotFoundInInventory.tr(
                      namedArgs: {'barcode': cleaned},
                    ),
                  ),
                  backgroundColor: AppColors.warning,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            _updateSuggestions(cleaned);
          }
        });
        return;
      }
    }
    if (_descFocus.hasFocus) {
      _updateSuggestions(widget.descController.text);
    }
  }

  String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll(RegExp(r'[إأآا]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .trim()
        .toLowerCase();
  }

  void _updateSuggestions(String text) {
    if (!mounted) return;
    final rawQuery = text.trim();
    final normalizedQuery = _normalizeArabic(rawQuery);
    final allProducts =
        (widget.availableProducts != null &&
            widget.availableProducts!.isNotEmpty)
        ? widget.availableProducts!
        : _fallbackProducts;

    if (rawQuery.isEmpty || allProducts.isEmpty) {
      _suggestions = [];
      _hideOverlay();
      return;
    }

    _suggestions = allProducts
        .where((p) {
          // Show ONLY available products with stock in inventory > 0
          if (!p.isAvailable || p.currentQuantity <= 0) return false;

          final normName = _normalizeArabic(p.name);
          final normCategory = _normalizeArabic(p.categoryName);
          final sku = p.sku.toLowerCase();
          final barcode = p.barcode?.toLowerCase() ?? '';
          final lowerRaw = rawQuery.toLowerCase();

          return normName.contains(normalizedQuery) ||
              normCategory.contains(normalizedQuery) ||
              sku.contains(lowerRaw) ||
              barcode.contains(lowerRaw);
        })
        .take(6)
        .toList();

    if (_suggestions.isNotEmpty && _descFocus.hasFocus) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  bool _isSelectingProduct = false;

  void _showOverlay() {
    _isSelectingProduct = false;
    if (!mounted) return;
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    final renderBox =
        _descFieldKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(300, 50);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, size.height + 4.0),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(14),
              color: AppColors.surface,
              shadowColor: AppColors.blackLight.withValues(alpha: 0.18),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.25),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.dividerColor.withValues(alpha: 0.6),
                    ),
                    itemBuilder: (context, index) {
                      final item = _suggestions[index];
                      return _buildSuggestionItem(item);
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  void _selectProduct(
    InventoryProductEntity product, {
    bool isExternalScanner = false,
  }) {
    if (_isSelectingProduct) return;
    _isSelectingProduct = true;
    _hideOverlay();
    if (widget.onProductSelected != null) {
      widget.onProductSelected!(product, isExternalScanner: isExternalScanner);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _isSelectingProduct = false;
      });
      return;
    }

    widget.descController.text = product.name;
    widget.descController.selection = TextSelection.fromPosition(
      TextPosition(offset: product.name.length),
    );
    widget.priceController.text = product.sellingPrice.toSmartAmount();
    if (product.unit.trim().isNotEmpty) {
      widget.unitController.text = product.unit.trim();
    }
    final currentQty = double.tryParse(widget.qtyController.text) ?? 0.0;
    final maxQty = product.currentQuantity;
    if (currentQty <= 0) {
      widget.qtyController.text = '1';
    } else if (maxQty > 0 && currentQty > maxQty) {
      widget.qtyController.text = maxQty.toSmartAmount();
    }
    if (!mounted) return;
    setState(() {});
    widget.onChanged();

    if (isExternalScanner && widget.onNextItem != null) {
      widget.onNextItem!();
    } else {
      // Focus price and select all text so user can either confirm or overwrite
      _priceFocus.requestFocus();
      if (widget.priceController.text.isNotEmpty) {
        widget.priceController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.priceController.text.length,
        );
      }
    }
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _isSelectingProduct = false;
    });
  }

  Future<bool> _handleScannedCode(
    String rawCode, {
    bool isExternalScanner = false,
  }) async {
    final target = rawCode.trim().toLowerCase();
    if (target.isEmpty) return false;

    var allProducts =
        (widget.availableProducts != null &&
            widget.availableProducts!.isNotEmpty)
        ? widget.availableProducts!
        : _fallbackProducts;

    if (allProducts.isEmpty) {
      await _loadFallbackProducts();
      allProducts = _fallbackProducts;
    }

    InventoryProductEntity? matchedProduct;
    for (final p in allProducts) {
      final barcode = p.barcode?.trim().toLowerCase();
      final sku = p.sku.trim().toLowerCase();
      final id = p.id.trim().toLowerCase();
      if ((barcode != null && barcode == target) ||
          sku == target ||
          id == target) {
        matchedProduct = p;
        break;
      }
    }

    if (matchedProduct != null) {
      _hideOverlay();
      _selectProduct(matchedProduct, isExternalScanner: isExternalScanner);
      return true;
    }
    return false;
  }

  Future<void> _scanBarcodeForItem() async {
    if (!_isCameraScanSupported) return;
    _hideOverlay();
    final scannedCode = await BarcodeScannerDialog.scan(context);
    if (scannedCode == null || scannedCode.trim().isEmpty) return;

    final matched = await _handleScannedCode(
      scannedCode,
      isExternalScanner: false,
    );
    if (!matched) {
      widget.descController.text = scannedCode.trim();
      widget.descController.selection = TextSelection.fromPosition(
        TextPosition(offset: scannedCode.trim().length),
      );
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.barcodeNotFoundInInventory.tr(
                namedArgs: {'barcode': scannedCode.trim()},
              ),
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  Widget _buildSuggestionItem(InventoryProductEntity item) {
    final currency = AppStrings.currencyEgp.tr();
    final isLowStock = item.currentQuantity <= item.minQuantity;
    final isAlreadyInInvoice = widget.selectedProductQuantities != null &&
        widget.selectedProductQuantities!.containsKey(item.id);
    final alreadyQty = isAlreadyInInvoice
        ? widget.selectedProductQuantities![item.id]!
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectProduct(item),
        hoverColor: AppColors.primaryColor.withValues(alpha: 0.05),
        splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyles.customStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        if (isAlreadyInInvoice) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primaryColor.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              AppStrings.invoiceItemBadgeAdded.tr(
                                namedArgs: {
                                  'qty': alreadyQty.toSmartAmount(),
                                },
                              ),
                              style: TextStyles.customStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (item.categoryName.trim().isNotEmpty) ...[
                          Flexible(
                            child: Text(
                              item.categoryName.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.customStyle(
                                fontSize: 11,
                                color: AppColors.subTitleColor,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Text(
                              '•',
                              style: TextStyles.customStyle(
                                fontSize: 10,
                                color: AppColors.disabledColor,
                              ),
                            ),
                          ),
                        ],
                        Flexible(
                          child: Text(
                            '${AppStrings.available.tr()}: ${item.currentQuantity.toSmartAmount()} ${item.unit}',
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyles.customStyle(
                              fontSize: 11,
                              fontWeight: isLowStock
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isLowStock
                                  ? AppColors.warning
                                  : AppColors.subTitleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.sellingPrice.toSmartAmount()} $currency',
                  style: TextStyles.customStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InventoryProductEntity? get _matchedProduct {
    final allProducts =
        (widget.availableProducts != null &&
            widget.availableProducts!.isNotEmpty)
        ? widget.availableProducts!
        : _fallbackProducts;
    if (allProducts.isEmpty) return null;

    final currentDesc = widget.descController.text.trim();
    if (currentDesc.isEmpty) return null;

    // 1. If productId is provided, verify description still matches that product
    if (widget.productId != null && widget.productId!.isNotEmpty) {
      for (final p in allProducts) {
        if (p.id == widget.productId) {
          if (p.name.trim().toLowerCase() == currentDesc.toLowerCase() ||
              _normalizeArabic(p.name) == _normalizeArabic(currentDesc)) {
            return p;
          }
        }
      }
    }

    // 2. Otherwise match by product name in inventory
    final normDesc = _normalizeArabic(currentDesc);
    for (final p in allProducts) {
      if (p.name.trim().toLowerCase() == currentDesc.toLowerCase() ||
          _normalizeArabic(p.name) == normDesc) {
        return p;
      }
    }

    return null;
  }

  double? get _effectiveMaxQty {
    if (widget.maxQuantity != null) {
      return widget.maxQuantity;
    }
    final product = _matchedProduct;
    if (product == null){
      return null; // Custom product not in inventory -> no stock limit
    }
    return product.currentQuantity;
  }

  void _showStockLimitFeedback(double maxQty) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${AppStrings.availableInStock.tr()}: ${maxQty.toSmartAmount()}',
                style: TextStyles.customStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _changeQty(double delta) {
    final currentQty = double.tryParse(widget.qtyController.text) ?? 1.0;
    final maxQty = _effectiveMaxQty;

    if (delta > 0 && maxQty != null && currentQty >= maxQty) {
      _showStockLimitFeedback(maxQty);
      return;
    }

    final upperLimit = maxQty ?? 999999.0;
    final newQty = (currentQty + delta).clamp(1.0, upperLimit);
    widget.qtyController.text = newQty.toSmartAmount();
    setState(() {});
    widget.onChanged();
  }

  void _applyDiscountPercent(double percent) {
    final qty = double.tryParse(widget.qtyController.text) ?? 1.0;
    final price = double.tryParse(widget.priceController.text) ?? 0.0;
    final subtotal = qty * price;
    if (subtotal <= 0) return;
    final discount = subtotal * (percent / 100.0);
    widget.discountController.text = discount.toSmartAmount();
    setState(() {});
    widget.onChanged();
  }

  void _clearDiscount() {
    widget.discountController.text = '0';
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final qty = double.tryParse(widget.qtyController.text) ?? 1.0;
    final price = double.tryParse(widget.priceController.text) ?? 0.0;
    final discountAmount =
        double.tryParse(widget.discountController.text) ?? 0.0;
    final subtotal = qty * price;
    final lineTotal = (subtotal - discountAmount).clamp(0.0, double.infinity);
    final hasTax = widget.taxRate > 0;
    final itemTax = hasTax ? lineTotal * (widget.taxRate / 100.0) : 0.0;
    final itemBeforeTax = hasTax ? (lineTotal - itemTax) : lineTotal;

    final effectiveUnitPrice = qty > 0
        ? ((qty * price) - discountAmount) / qty
        : (price - discountAmount);
    final hasPurchasePrice =
        widget.purchasePrice != null && widget.purchasePrice! > 0;
    final isBelowCost =
        hasPurchasePrice &&
        (effectiveUnitPrice < widget.purchasePrice! ||
            lineTotal < (qty * widget.purchasePrice!));
    final currency = AppStrings.currencyEgp.tr();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [AppColors.shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: item badge + delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      size: 13,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${AppStrings.invoiceItem.tr()} #${widget.index + 1}',
                      style: TextStyles.customStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onRemove,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.delete.tr(),
                          style: TextStyles.customStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description field with Autocomplete overlay
          CompositedTransformTarget(
            link: _layerLink,
            child: KeyedSubtree(
              key: _descFieldKey,
              child: InvoiceItemRowItemField(
                controller: widget.descController,
                focusNode: _descFocus,
                textInputAction: TextInputAction.next,
                suffixWidget: _isCameraScanSupported
                    ? IconButton(
                        icon: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                        tooltip: AppStrings.barcodeScanTitle.tr(),
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: _scanBarcodeForItem,
                      )
                    : null,
                onSubmitted: (value) async {
                  _hideOverlay();
                  final trimmed = value.trim();
                  if (trimmed.isNotEmpty) {
                    final matched = await _handleScannedCode(
                      trimmed,
                      isExternalScanner: true,
                    );
                    if (matched) {
                      return;
                    } else if (_isLikelyBarcode(trimmed)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.barcodeNotFoundInInventory.tr(
                                namedArgs: {'barcode': trimmed},
                              ),
                            ),
                            backgroundColor: AppColors.warning,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  }
                  _priceFocus.requestFocus();
                  if (widget.priceController.text.isNotEmpty) {
                    widget.priceController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: widget.priceController.text.length,
                    );
                  }
                },
                hint: AppStrings.invoiceItemDescHint.tr(),
                label: AppStrings.invoiceItemDesc.tr(),
                onChanged: (_) => widget.onChanged(),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // Price field
              Expanded(
                flex: 3,
                child: InvoiceItemRowItemField(
                  controller: widget.priceController,
                  focusNode: _priceFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    _qtyFocus.requestFocus();
                    if (widget.qtyController.text.isNotEmpty) {
                      widget.qtyController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: widget.qtyController.text.length,
                      );
                    }
                  },
                  hint: '0.00',
                  label: AppStrings.invoiceItemPrice.tr(),
                  isNumber: true,
                  suffix: currency,
                  onChanged: (_) {
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Quantity field with stepper controls
              Expanded(
                flex: 2,
                child: Builder(
                  builder: (context) {
                    final maxQty = _effectiveMaxQty;
                    final isAtMax = maxQty != null && qty >= maxQty;

                    return InvoiceItemRowItemField(
                      controller: widget.qtyController,
                      focusNode: _qtyFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) {
                        final currentMax = _effectiveMaxQty;
                        if (currentMax != null) {
                          final currentTyped =
                              double.tryParse(widget.qtyController.text) ?? 1.0;
                          if (currentTyped > currentMax) {
                            widget.qtyController.text = currentMax
                                .toSmartAmount();
                            _showStockLimitFeedback(currentMax);
                          }
                        }
                        _discountFocus.requestFocus();
                        if (widget.discountController.text.isNotEmpty) {
                          widget.discountController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: widget.discountController.text.length,
                          );
                        }
                      },
                      hint: '1',
                      label: maxQty != null
                          ? '${AppStrings.invoiceItemQty.tr()} (${AppStrings.available.tr()}: ${maxQty.toSmartAmount()})'
                          : AppStrings.invoiceItemQty.tr(),
                      isNumber: true,
                      suffixWidget: SizedBox(
                        width: 52,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            InkWell(
                              onTap: () => _changeQty(-1),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 4,
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 15,
                                  color: AppColors.blackLight,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: isAtMax
                                  ? () => _showStockLimitFeedback(maxQty)
                                  : () => _changeQty(1),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 4,
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 15,
                                  color: isAtMax
                                      ? AppColors.disabledColor
                                      : AppColors.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                      onChanged: (val) {
                        final currentMax = _effectiveMaxQty;
                        if (currentMax != null && val.trim().isNotEmpty) {
                          final parsed = double.tryParse(val.trim());
                          if (parsed != null && parsed > currentMax) {
                            widget.qtyController.text = currentMax
                                .toSmartAmount();
                            widget.qtyController.selection =
                                TextSelection.fromPosition(
                                  TextPosition(
                                    offset: widget.qtyController.text.length,
                                  ),
                                );
                            _showStockLimitFeedback(currentMax);
                          }
                        }
                        setState(() {});
                        widget.onChanged();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Discount amount field (in Currency)
              Expanded(
                flex: 2,
                child: InvoiceItemRowItemField(
                  controller: widget.discountController,
                  focusNode: _discountFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    _unitFocus.requestFocus();
                    if (widget.unitController.text.isNotEmpty) {
                      widget.unitController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: widget.unitController.text.length,
                      );
                    }
                  },
                  hint: '0',
                  label: AppStrings.invoiceItemDiscount.tr(),
                  isNumber: true,
                  suffix: currency,
                  onChanged: (_) {
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Unit field (e.g. قطعة، كرتونة)
              Expanded(
                flex: 1,
                child: InvoiceItemRowItemField(
                  controller: widget.unitController,
                  focusNode: _unitFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    if (widget.onNextItem != null) {
                      widget.onNextItem!();
                    } else {
                      _unitFocus.unfocus();
                    }
                  },
                  hint: AppStrings.unitPieceHint.tr(),
                  label: AppStrings.unit.tr(),
                  onChanged: (_) {
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),

          // Quick discount percentages helper
          if (subtotal > 0) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${AppStrings.quickDiscount.tr()}:',
                  style: TextStyles.customStyle(
                    fontSize: 11,
                    color: AppColors.subTitleColor,
                  ),
                ),
                ...[5, 10, 15, 20].map((pct) {
                  final isSelected =
                      discountAmount > 0 &&
                      ((discountAmount / subtotal) * 100 - pct).abs() < 0.2;
                  return InkWell(
                    onTap: () => _applyDiscountPercent(pct.toDouble()),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '$pct%',
                        style: TextStyles.customStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.primaryColor,
                        ),
                      ),
                    ),
                  );
                }),
                if (discountAmount > 0)
                  InkWell(
                    onTap: _clearDiscount,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, size: 12, color: AppColors.error),
                          const SizedBox(width: 2),
                          Text(
                            AppStrings.clear.tr(),
                            style: TextStyles.customStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // Smart Line Total & Financial Insights
          _buildSmartLineTotalCard(
            subtotal: subtotal,
            discountAmount: discountAmount,
            lineTotal: lineTotal,
            effectiveUnitPrice: effectiveUnitPrice,
            qty: qty,
            price: price,
            unit: widget.unitController.text.trim(),
            hasTax: hasTax,
            itemTax: itemTax,
            itemBeforeTax: itemBeforeTax,
            hasPurchasePrice: hasPurchasePrice,
            isBelowCost: isBelowCost,
            currency: currency,
          ),
        ],
      ),
    );
  }

  /// Builds a smart, contextual summary card for the line item total
  Widget _buildSmartLineTotalCard({
    required double subtotal,
    required double discountAmount,
    required double lineTotal,
    required double effectiveUnitPrice,
    required double qty,
    required double price,
    required String unit,
    required bool hasTax,
    required double itemTax,
    required double itemBeforeTax,
    required bool hasPurchasePrice,
    required bool isBelowCost,
    required String currency,
  }) {
    final discountPercent = subtotal > 0
        ? ((discountAmount / subtotal) * 100).clamp(0.0, 100.0)
        : 0.0;
    final totalCost = hasPurchasePrice ? (widget.purchasePrice! * qty) : 0.0;
    final totalProfit = hasPurchasePrice ? (lineTotal - totalCost) : 0.0;
    final profitMarginPercent = (hasPurchasePrice && lineTotal > 0)
        ? ((totalProfit / lineTotal) * 100).clamp(-999.0, 999.0)
        : 0.0;

    // Determine background, border & status icon based on business condition
    Color cardBg;
    Color cardBorder;
    Color statusIconBg;
    Color statusIconColor;
    IconData statusIcon;

    if (isBelowCost) {
      cardBg = AppColors.warning.withValues(
        alpha: AppColors.isDark ? 0.16 : 0.08,
      );
      cardBorder = AppColors.warning.withValues(alpha: 0.45);
      statusIconBg = AppColors.warning.withValues(alpha: 0.2);
      statusIconColor = AppColors.warning;
      statusIcon = Icons.warning_amber_rounded;
    } else if (hasPurchasePrice && totalProfit > 0) {
      cardBg = AppColors.isDark
          ? const Color(0xFF1B2A20)
          : const Color(0xFFF1F8F4);
      cardBorder = AppColors.success.withValues(alpha: 0.3);
      statusIconBg = AppColors.success.withValues(alpha: 0.15);
      statusIconColor = AppColors.success;
      statusIcon = Icons.trending_up_rounded;
    } else if (discountAmount > 0) {
      cardBg = AppColors.isDark
          ? const Color(0xFF28251C)
          : const Color(0xFFFFFDF5);
      cardBorder = AppColors.orange100.withValues(alpha: 0.3);
      statusIconBg = AppColors.orange100.withValues(alpha: 0.15);
      statusIconColor = AppColors.orange100;
      statusIcon = Icons.local_offer_outlined;
    } else {
      cardBg = AppColors.veryLightGrey;
      cardBorder = AppColors.dividerColor;
      statusIconBg = AppColors.primaryColor.withValues(alpha: 0.1);
      statusIconColor = AppColors.primaryColor;
      statusIcon = Icons.receipt_long_rounded;
    }

    final hasInsights = subtotal > 0 || isBelowCost || hasTax;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: isBelowCost ? 1.3 : 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: hasInsights
              ? () {
                  setState(() {
                    _isTotalExpanded = !_isTotalExpanded;
                  });
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Summary Row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status icon badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: statusIconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(statusIcon, color: statusIconColor, size: 20),
                    ),
                    const SizedBox(width: 10),

                    // Title and dynamic subtitle / formula
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  hasTax
                                      ? AppStrings.totalAfterTax.tr()
                                      : AppStrings.invoiceLineTotal.tr(),
                                  style: TextStyles.customStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasInsights) ...[
                                const SizedBox(width: 4),
                                AnimatedRotation(
                                  turns: _isTotalExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: AppColors.subTitleColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (discountAmount > 0)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          '${subtotal.toSmartAmount()} $currency',
                                      style:
                                          TextStyles.customStyle(
                                            fontSize: 11,
                                            color: AppColors.disabledColor,
                                          ).copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                    ),
                                    const TextSpan(text: ' '),
                                    TextSpan(
                                      text:
                                          '(${AppStrings.savedAmount.tr()} ${discountAmount.toSmartAmount()})',
                                      style: TextStyles.customStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.orange100,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (price > 0 && qty > 0)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                '${qty.toSmartAmount()} ${unit.isNotEmpty ? "$unit " : ""}× ${price.toSmartAmount()} $currency',
                                style: TextStyles.customStyle(
                                  fontSize: 11,
                                  color: AppColors.blackLight,
                                ),
                              ),
                            )
                          else
                            Text(
                              '0.00 $currency',
                              style: TextStyles.customStyle(
                                fontSize: 11,
                                color: AppColors.disabledColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Net Line Total
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerEnd,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  lineTotal.toSmartAmount(),
                                  style: TextStyles.customStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isBelowCost
                                        ? AppColors.warning
                                        : AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  currency,
                                  style: TextStyles.customStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isBelowCost
                                        ? AppColors.warning
                                        : AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasTax) ...[
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              child: Text(
                                '${AppStrings.totalBeforeTax.tr()}\n ${itemBeforeTax.toSmartAmount()}',
                                style: TextStyles.customStyle(
                                  fontSize: 10,
                                  color: AppColors.subTitleColor,
                                ),
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Animated Expandable Details / Smart Badges ──
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: _isTotalExpanded && hasInsights
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Divider(
                                  height: 1,
                                  thickness: 0.8,
                                  color: AppColors.dividerColor,
                                ),
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Formula breakdown pill
                                  if (price > 0 && qty > 0)
                                    _buildSmartBadge(
                                      context: context,
                                      icon: Icons.calculate_outlined,
                                      label:
                                          '${qty.toSmartAmount()} × ${price.toSmartAmount()}${discountAmount > 0 ? " - ${discountAmount.toSmartAmount()}" : ""}',
                                      color: AppColors.blackLight,
                                      bgColor: AppColors.surface,
                                      borderColor: AppColors.dividerColor,
                                    ),

                                  // Discount pill
                                  if (discountAmount > 0) ...[
                                    _buildSmartBadge(
                                      context: context,
                                      icon: Icons.local_offer_outlined,
                                      label:
                                          '${AppStrings.invoiceItemDiscount.tr()}: -${discountAmount.toSmartAmount()} $currency (${discountPercent.toSmartAmount(decimalDigits: 1)}%)',
                                      color: AppColors.orange100,
                                      bgColor: AppColors.orange100.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderColor: AppColors.orange100
                                          .withValues(alpha: 0.3),
                                    ),
                                    if (qty > 1)
                                      _buildSmartBadge(
                                        context: context,
                                        icon: Icons.sell_outlined,
                                        label:
                                            '${AppStrings.unitPriceAfterDiscount.tr()}: ${effectiveUnitPrice.toSmartAmount(decimalDigits: 2)} $currency',
                                        color: AppColors.blackLight,
                                        bgColor: AppColors.surface,
                                        borderColor: AppColors.dividerColor,
                                      ),
                                  ],

                                  // Cost & Profit pills
                                  if (hasPurchasePrice) ...[
                                    if (isBelowCost) ...[
                                      _buildSmartBadge(
                                        context: context,
                                        icon: Icons.warning_amber_rounded,
                                        label:
                                            '${AppStrings.lossAlert.tr()}: -${(totalCost - lineTotal).toSmartAmount()} $currency • ${AppStrings.sellingBelowCostWarning.tr().replaceAll('{cost}', widget.purchasePrice!.toSmartAmount()).replaceAll('{currency}', currency)}',
                                        color: AppColors.warning,
                                        bgColor: AppColors.warning.withValues(
                                          alpha: 0.16,
                                        ),
                                        borderColor: AppColors.warning
                                            .withValues(alpha: 0.5),
                                      ),
                                    ] else if (totalProfit > 0) ...[
                                      _buildSmartBadge(
                                        context: context,
                                        icon: Icons.trending_up_rounded,
                                        label:
                                            '${AppStrings.profitEstimate.tr()} +${totalProfit.toSmartAmount()} $currency (${profitMarginPercent.toSmartAmount(decimalDigits: 0)}% ${AppStrings.profitMargin.tr()})',
                                        color: AppColors.success,
                                        bgColor: AppColors.success.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderColor: AppColors.success
                                            .withValues(alpha: 0.3),
                                      ),
                                    ] else ...[
                                      _buildSmartBadge(
                                        context: context,
                                        icon: Icons.balance_rounded,
                                        label: AppStrings.atCostNoProfit.tr(),
                                        color: AppColors.blackLight,
                                        bgColor: AppColors.surface,
                                        borderColor: AppColors.dividerColor,
                                      ),
                                    ],
                                  ],

                                  // Tax breakdown pill
                                  if (hasTax)
                                    _buildSmartBadge(
                                      context: context,
                                      icon: Icons.account_balance_outlined,
                                      label:
                                          '${AppStrings.vatAmount.tr()} (${widget.taxRate.toSmartAmount()}%): +${itemTax.toSmartAmount()} $currency',
                                      color: AppColors.primaryColor,
                                      bgColor: AppColors.primaryColor
                                          .withValues(alpha: 0.08),
                                      borderColor: AppColors.primaryColor
                                          .withValues(alpha: 0.2),
                                    ),
                                ],
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartBadge({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    final maxBadgeWidth = (MediaQuery.of(context).size.width - 64).clamp(
      100.0,
      600.0,
    );
    return Container(
      constraints: BoxConstraints(maxWidth: maxBadgeWidth),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.customStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InvoiceItemRowItemField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final bool isNumber;
  final String? suffix;
  final Widget? suffixWidget;
  final Widget? prefixWidget;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  const InvoiceItemRowItemField({
    super.key,
    required this.controller,
    required this.hint,
    required this.label,
    this.isNumber = false,
    this.suffix,
    this.suffixWidget,
    this.prefixWidget,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyles.customStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.blackLight,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          cursorColor: AppColors.primaryColor,
          controller: controller,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onTap:
              onTap ??
              () {
                if (isNumber && controller.text.isNotEmpty) {
                  controller.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: controller.text.length,
                  );
                }
              },
          onChanged: onChanged,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: TextStyles.customStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyles.customStyle(
              fontSize: 14,
              color: AppColors.disabledColor,
            ),
            suffixText: suffix,
            suffixStyle: TextStyles.customStyle(
              fontSize: 13,
              color: AppColors.blackLight,
            ),
            suffixIcon: suffixWidget,
            prefixIcon: prefixWidget,
            suffixIconConstraints: suffixWidget != null
                ? const BoxConstraints(maxHeight: 36, minWidth: 44)
                : null,
            filled: true,
            fillColor: AppColors.veryLightGrey,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
