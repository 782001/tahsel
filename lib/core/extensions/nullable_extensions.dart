extension NullableObjectExtensions<T extends Object> on T? {
  /// Returns [true] if the object is null.
  bool get isNull => this == null;
  
  /// Returns [true] if the object is not null.
  bool get isNotNull => this != null;

  /// Executes the given function [action] if the object is not null, 
  /// and returns the result. Extremely useful for concise null checks.
  /// Example: user?.let((u) => print(u.name))
  R? let<R>(R Function(T it) action) {
    if (this != null) {
      return action(this as T);
    }
    return null;
  }
}
