extension ListExtensions<T> on List<T> {
  /// Separates the elements of the list with a [separator].
  /// Useful for adding spacing between widgets.
  /// Example: [Text('1'), Text('2')].separatedBy(SizedBox(height: 10))
  List<E> separatedBy<E extends Object>(E separator) {
    if (isEmpty) return <E>[];
    
    final List<E> separatedList = [];
    for (int i = 0; i < length; i++) {
      separatedList.add(this[i] as E);
      if (i < length - 1) {
        separatedList.add(separator);
      }
    }
    return separatedList;
  }
}

extension NullableListExtensions<T> on List<T>? {
  /// Returns true if the list is null or empty.
  /// Example: null.isNullOrEmpty // true
  /// Example: [].isNullOrEmpty // true
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns true if the list is neither null nor empty.
  bool get isNotNullNorEmpty => this != null && this!.isNotEmpty;
  
  /// Returns the first element if the list is not empty, otherwise null.
  /// Example: [1, 2, 3].firstOrNull // 1
  /// Example: [].firstOrNull // null
  T? get firstOrNull => isNullOrEmpty ? null : this!.first;
  
  /// Returns the last element if the list is not empty, otherwise null.
  T? get lastOrNull => isNullOrEmpty ? null : this!.last;
}
