import 'package:equatable/equatable.dart';

abstract class BasePaginated<T> extends Equatable {
  const BasePaginated({
    required this.data,
    this.page = 1,
    this.perPage = 15,
    this.hasMore = false,
  });
  final int page;
  final int perPage;
  final bool hasMore;
  final List<T> data;

  @override
  List<Object?> get props => [
        page,
        perPage,
        hasMore,
        data,
      ];
}
class MessagePaginatedNew<T> extends BasePaginated<T> {
  const MessagePaginatedNew({
    required List<T> data,
    int page = 1,
    int perPage = 15,
    bool hasMore = false,
  }) : super(
          data: data,
          page: page,
          perPage: perPage,
          hasMore: hasMore,
        );
}
