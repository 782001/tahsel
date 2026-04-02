import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tahsel/core/utils/media_query_values.dart';
import 'package:tahsel/shared/widgets/empty_widget/empty_widget.dart';
import 'package:tahsel/shared/widgets/scroll_pagination/custom_footer.dart';
import 'package:tahsel/shared/widgets/scroll_pagination/models/pagination.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

//usage example:
/*
    return InfiniteScrollPagination<Review>(
                          onLoading: () async {
                            await ref
                                .read(reviewsControllerProvider.notifier)
                                .loadMore();
                          },
                          onRefresh: () async {
                            ref.invalidate(reviewsControllerProvider);
                          },
                          pagination: data,
                          itemBuilder: (context, model) =>
                              ReviewCard(review: model),
                        );
*/
class InfiniteScrollPagination<T> extends StatefulWidget {
  const InfiniteScrollPagination({
    required this.onLoading,
    required this.itemBuilder,
    required this.pagination,
    this.controller,
    this.onRefresh,
    this.padding,
    this.separatorWidget,
    this.emptyWidget,
    this.reverse = false,
    super.key,
  });

  final Widget Function(int index, T item) itemBuilder;
  final BasePaginated<T>? pagination;
  final Future<void> Function()? onRefresh;
  final Future<void> Function() onLoading;
  final EdgeInsetsGeometry? padding;
  final Widget? separatorWidget;
  final Widget? emptyWidget;
  final bool reverse;
  final ScrollController? controller;

  @override
  State<InfiniteScrollPagination<T>> createState() =>
      _InfiniteScrollPaginationState<T>();
}

class _InfiniteScrollPaginationState<T>
    extends State<InfiniteScrollPagination<T>> {
  late final RefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
  }

  @override
  void didUpdateWidget(covariant InfiniteScrollPagination<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.pagination?.hasMore == false) &&
        (widget.pagination?.hasMore ?? false)) {
      _refreshController.resetNoData();
    }
  }

  @override
  void dispose() {
    try {
      final ctrl = widget.controller ?? PrimaryScrollController.of(context);
      if (ctrl.hasClients ?? false) {
        final pos = ctrl.position;
        ctrl.jumpTo(pos.pixels);
      }
    } catch (_) {}
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onLoading() async {
    if (widget.pagination?.hasMore != true) {
      if (mounted) _refreshController.loadNoData();
      return;
    }
    await widget.onLoading();
    if (!mounted) return;
    if (widget.pagination?.hasMore ?? false) {
      _refreshController.loadComplete();
    } else {
      _refreshController.loadNoData();
    }
  }

  Future<void> _onRefresh() async {
    if (widget.onRefresh == null) return;
    await widget.onRefresh!();
    if (!mounted) return;
    _refreshController.resetNoData();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.pagination?.data.isNotEmpty ?? false;

    return SmartRefresher(
      controller: _refreshController,
      enablePullUp: true,
      reverse: widget.reverse,
      onRefresh: widget.onRefresh != null ? _onRefresh : null,
      onLoading: _onLoading,
      enablePullDown: widget.onRefresh != null,
      footer: const CustomFooterWidget(),
      child: hasData
          ? ListView.separated(
              padding: widget.padding ?? EdgeInsets.zero,
              controller: widget.controller,
              reverse: widget.reverse,
              primary: widget.controller == null ? null : false,
              separatorBuilder: (context, index) =>
                  widget.separatorWidget ?? SizedBox(height: 12.h),
              itemCount: widget.pagination?.data.length ?? 0,
              itemBuilder: (context, index) =>
                  widget.itemBuilder(index, widget.pagination!.data[index]),
            )
          : (widget.emptyWidget ??
                EmptyWidget(topHeight: context.height * 0.25)),
    );
  }
}
