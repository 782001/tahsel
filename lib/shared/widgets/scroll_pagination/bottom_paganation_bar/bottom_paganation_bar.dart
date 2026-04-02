import 'package:flutter/material.dart';
import 'package:tahsel/core/utils/app_colors.dart';
import 'package:tahsel/shared/widgets/fields/text_widget.dart';
//Usage///
// PaginationBar(
//                       currentPage: pagination.currentPage,
//                       totalPages: pagination.totalPages,
//                       onPageChanged: (page) {
//                         packagesCubit.getAvailablePackages(
//                           page: page,
//                           pageSize: 5,
//                           city: selectedCity?.id.toString(),
//                           category: getSelectedCategoryId(),
//                         );
//                       },
//                     ),

class BottomPaginationBar extends StatelessWidget {
  const BottomPaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    super.key,
    this.height = 36,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  });
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final double height;
  final EdgeInsetsGeometry padding;

  List<Object> _items() {
    if (totalPages <= 5) {
      return List<int>.generate(totalPages, (i) => i + 1);
    }
    if (currentPage <= 3) {
      return [1, 2, 3, 4, '...', totalPages];
    }
    if (currentPage >= totalPages - 2) {
      return [
        1,
        '...',
        totalPages - 3,
        totalPages - 2,
        totalPages - 1,
        totalPages,
      ];
    }
    return [
      1,
      '...',
      currentPage - 1,
      currentPage,
      currentPage + 1,
      '...',
      totalPages,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryColor;
    final disabled = AppColors.disabledColor.withOpacity(0.5);
    final items = _items();

    Widget pageChip(int page) {
      final selected = page == currentPage;
      return InkWell(
        onTap: selected ? null : () => onPageChanged(page),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: height,
          constraints: const BoxConstraints(minWidth: 36),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? primary : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextWidget(
            '$page',
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    Widget ellipsis() => Container(
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const TextWidget('...'),
    );

    final canGoPrev = currentPage > 1;
    final canGoNext = currentPage < totalPages;

    return Container(
      padding: padding,
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: canGoPrev ? () => onPageChanged(1) : null,
            icon: Icon(
              Icons.keyboard_double_arrow_left_rounded,
              color: canGoPrev ? null : disabled,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                children: items.map((e) {
                  if (e is String) return ellipsis();
                  return pageChip(e as int);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: canGoNext ? () => onPageChanged(totalPages) : null,
            icon: Icon(
              Icons.keyboard_double_arrow_right_rounded,
              color: canGoNext ? null : disabled,
            ),
          ),
        ],
      ),
    );
  }
}
