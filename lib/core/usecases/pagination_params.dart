import 'package:cloud_firestore/cloud_firestore.dart';

class PaginationParams {
  final int limit;
  final DocumentSnapshot? lastDocument;

  const PaginationParams({this.limit = 15, this.lastDocument});
}

class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });
}
