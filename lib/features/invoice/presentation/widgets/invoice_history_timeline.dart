import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_history_entity.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_history_cubit.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_history_state.dart';

/// Displays the invoice edit-history as an immutable activity timeline.
///
/// Consumes [InvoiceHistoryCubit] which must be provided above this widget.
/// This widget only triggers a rebuild of itself — it never causes the main
/// InvoiceDetailScreen to re-render.
class InvoiceHistoryTimeline extends StatelessWidget {
  const InvoiceHistoryTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceHistoryCubit, InvoiceHistoryState>(
      builder: (context, state) {
        if (state is InvoiceHistoryLoading) {
          return _buildShimmerSkeleton();
        }

        if (state is InvoiceHistoryEmpty || state is InvoiceHistoryInitial) {
          return _buildEmptyCard(context);
        }

        if (state is InvoiceHistoryFailure) {
          return const SizedBox.shrink();
        }

        if (state is InvoiceHistoryLoaded) {
          return _buildTimeline(context, state.entries);
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────────

  Widget _buildEmptyCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            color: AppColors.disabledColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            AppStrings.invoiceHistoryEmpty.tr(),
            style: TextStyles.customStyle(
              fontSize: 13,
              color: AppColors.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shimmer Skeleton ────────────────────────────────────────────────────────

  Widget _buildShimmerSkeleton() {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.veryLightGrey,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  // ── Timeline ────────────────────────────────────────────────────────────────

  Widget _buildTimeline(
    BuildContext context,
    List<InvoiceHistoryEntity> entries,
  ) {
    // Group by calendar day label (Today / Yesterday / date)
    final groups = _groupByDay(entries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) ...[
          // Day header
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Text(
              group.dayLabel,
              style: TextStyles.customStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.disabledColor,
              ),
            ),
          ),
          // Cards for this day
          for (int i = 0; i < group.entries.length; i++) ...[
            _HistoryCard(entry: group.entries[i]),
            if (i < group.entries.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Container(
                  width: 2,
                  height: 14,
                  color: AppColors.dividerColor,
                ),
              ),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  List<_DayGroup> _groupByDay(List<InvoiceHistoryEntity> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<InvoiceHistoryEntity>>{};
    for (final entry in entries) {
      final d = entry.timestamp;
      final day = DateTime(d.year, d.month, d.day);
      final String label;
      if (day == today) {
        label = AppStrings.historyToday.tr();
      } else if (day == yesterday) {
        label = AppStrings.historyYesterday.tr();
      } else {
        label =
            '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      }
      groups.putIfAbsent(label, () => []).add(entry);
    }

    return groups.entries
        .map((e) => _DayGroup(dayLabel: e.key, entries: e.value))
        .toList();
  }
}

// ── Day Group ─────────────────────────────────────────────────────────────────

class _DayGroup {
  final String dayLabel;
  final List<InvoiceHistoryEntity> entries;
  const _DayGroup({required this.dayLabel, required this.entries});
}

// ── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final InvoiceHistoryEntity entry;
  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(entry.changeType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: const [AppColors.shadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(config.icon, color: config.color, size: 18),
          ),
          const SizedBox(width: 12),

          // Body
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        config.title,
                        style: TextStyles.customStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(entry.timestamp),
                      style: TextStyles.customStyle(
                        fontSize: 11,
                        color: AppColors.disabledColor,
                      ),
                    ),
                  ],
                ),

                // Field label (e.g. product name)
                if (entry.fieldLabel?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.fieldLabel!,
                    style: TextStyles.customStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],

                // Old → New values
                if (entry.oldValue != null || entry.newValue != null) ...[
                  const SizedBox(height: 6),
                  _ValueChangeRow(
                    changeType: entry.changeType,
                    oldValue: entry.oldValue,
                    newValue: entry.newValue,
                  ),
                ],

                // Metadata rows (quantity, price, subtotal for added/removed items)
                if (entry.metadata.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _MetadataRow(metadata: entry.metadata),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _CardConfig _getConfig(InvoiceHistoryChangeType type) {
    switch (type) {
      case InvoiceHistoryChangeType.itemAdded:
        return _CardConfig(
          icon: Icons.add_circle_outline_rounded,
          color: AppColors.success,
          title: AppStrings.historyItemAdded.tr(),
        );
      case InvoiceHistoryChangeType.itemRemoved:
        return _CardConfig(
          icon: Icons.remove_circle_outline_rounded,
          color: AppColors.error,
          title: AppStrings.historyItemRemoved.tr(),
        );
      case InvoiceHistoryChangeType.quantityUpdated:
        return _CardConfig(
          icon: Icons.format_list_numbered_rounded,
          color: AppColors.warning,
          title: AppStrings.historyQtyUpdated.tr(),
        );
      case InvoiceHistoryChangeType.priceUpdated:
        return _CardConfig(
          icon: Icons.price_change_outlined,
          color: AppColors.info,
          title: AppStrings.historyPriceUpdated.tr(),
        );
      case InvoiceHistoryChangeType.customerUpdated:
        return _CardConfig(
          icon: Icons.person_outline_rounded,
          color: AppColors.primaryColor,
          title: AppStrings.historyCustomerUpdated.tr(),
        );
      case InvoiceHistoryChangeType.notesUpdated:
        return _CardConfig(
          icon: Icons.notes_rounded,
          color: AppColors.blackLight,
          title: AppStrings.historyNotesUpdated.tr(),
        );
      case InvoiceHistoryChangeType.discountUpdated:
        return _CardConfig(
          icon: Icons.discount_outlined,
          color: AppColors.warning,
          title: AppStrings.historyDiscountUpdated.tr(),
        );
    }
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Value Change Row ──────────────────────────────────────────────────────────

class _ValueChangeRow extends StatelessWidget {
  final InvoiceHistoryChangeType changeType;
  final String? oldValue;
  final String? newValue;

  const _ValueChangeRow({
    required this.changeType,
    this.oldValue,
    this.newValue,
  });

  @override
  Widget build(BuildContext context) {
    // For notes — just show a simple label
    if (changeType == InvoiceHistoryChangeType.notesUpdated) {
      return Text(
        AppStrings.historyNotesChanged.tr(),
        style: TextStyles.customStyle(
          fontSize: 11,
          color: AppColors.disabledColor,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Row(
      children: [
        if (oldValue != null) ...[
          _ValuePill(label: oldValue!, isOld: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: AppColors.disabledColor,
            ),
          ),
        ],
        if (newValue != null) _ValuePill(label: newValue!, isOld: false),
      ],
    );
  }
}

class _ValuePill extends StatelessWidget {
  final String label;
  final bool isOld;
  const _ValuePill({required this.label, required this.isOld});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOld
            ? AppColors.error.withValues(alpha: 0.10)
            : AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyles.customStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isOld ? AppColors.error : AppColors.success,
        ),
      ),
    );
  }
}

// ── Metadata Row ──────────────────────────────────────────────────────────────

class _MetadataRow extends StatelessWidget {
  final Map<String, dynamic> metadata;
  const _MetadataRow({required this.metadata});

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
          _MetaChip(
            label:
                '${AppStrings.invoiceItemQty.tr()}: ${_fmt(qty)}',
          ),
        if (price != null)
          _MetaChip(
            label:
                '${AppStrings.invoiceItemPrice.tr()}: ${_fmt(price)}',
          ),
        if (subtotal != null)
          _MetaChip(
            label:
                '${AppStrings.invoiceLineTotal.tr()}: ${_fmt(subtotal)}',
          ),
      ],
    );
  }

  String _fmt(dynamic val) {
    if (val is double) {
      return val % 1 == 0
          ? val.toInt().toString()
          : val.toStringAsFixed(2);
    }
    return val.toString();
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.veryLightGrey,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Text(
        label,
        style: TextStyles.customStyle(
          fontSize: 11,
          color: AppColors.blackLight,
        ),
      ),
    );
  }
}

// ── Config Helper ─────────────────────────────────────────────────────────────

class _CardConfig {
  final IconData icon;
  final Color color;
  final String title;
  const _CardConfig({
    required this.icon,
    required this.color,
    required this.title,
  });
}
