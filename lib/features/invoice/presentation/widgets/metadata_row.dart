import 'package:flutter/material.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/features/invoice/presentation/widgets/meta_chip.dart';

class MetadataRow extends StatelessWidget {
  final Map<String, dynamic> metadata;
  const MetadataRow({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    final qty = metadata['quantity'];
    final price = metadata['unitPrice'];
    final subtotal = metadata['subtotal'];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (qty != null)
          MetaChip(label: '${AppStrings.invoiceItemQty.tr()}: ${_fmt(qty)}'),
        if (price != null)
          MetaChip(
            label: '${AppStrings.invoiceItemPrice.tr()}: ${_fmt(price)}',
          ),
        if (subtotal != null)
          MetaChip(
            label: '${AppStrings.invoiceLineTotal.tr()}: ${_fmt(subtotal)}',
          ),
      ],
    );
  }

  String _fmt(dynamic val) {
    if (val is double) {
      return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(2);
    }
    return val.toString();
  }
}
