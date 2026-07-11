import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tahsel/core/extensions/string_extensions.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/core/utils/app_strings.dart';
import 'package:tahsel/core/utils/styles.dart';
import 'package:tahsel/features/invoice/domain/entities/invoice_history_entity.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_history_cubit.dart';
import 'package:tahsel/features/invoice/presentation/cubit/invoice_history_state.dart';
import 'package:tahsel/features/invoice/presentation/widgets/history_card.dart';

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
            HistoryCard(entry: group.entries[i]),
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

// ── Config Helper ─────────────────────────────────────────────────────────────

class CardConfig {
  final IconData icon;
  final Color color;
  final String title;
  const CardConfig({
    required this.icon,
    required this.color,
    required this.title,
  });
}
