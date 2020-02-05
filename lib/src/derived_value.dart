import 'package:flutter/foundation.dart';

import 'autorun.dart';

/// Similar to [ValueNotifier], but calculates its value based on the given callback.
///
/// The resulting value is cached and only updated lazily.
class DerivedValue<T> extends ChangeNotifier implements ValueListenable<T> {
  DerivedValue(AutoRunCallback<T> callback) {
    _autoRunner = AutoRunner(callback, onChange: _onChange);
  }

  @protected
  AutoRunner<T> _autoRunner;
  @protected
  T _value;
  @protected
  bool _upToDate = false;

  @override
  T get value {
    if (!_upToDate) {
      _value = _autoRunner.run();
    }
    return _value;
  }

  @override
  void dispose() {
    _autoRunner.dispose();
    super.dispose();
  }

  void _onChange() {
    _upToDate = false;
    _value = null;
    notifyListeners();
  }
}
