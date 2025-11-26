extension IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    /// Trả về phần tử đầu tiên thỏa điều kiện, hoặc `null` nếu không có.
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}