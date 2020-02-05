import 'package:flutter/foundation.dart';

/// Extends [ValueNotifier] with an [update] helper method.
class Value<T> extends ValueNotifier<T> {
  Value(T value) : super(value);

  /// Mutate value and notify listeners.
  ///
  /// The notification is sent even if the value is unchanged.
  /// In other words, unlike `.value = ` this doesn't check for equality of the
  /// modified value.
  void update(void fn(T value)) {
    fn(value);
    notifyListeners();
  }
}
