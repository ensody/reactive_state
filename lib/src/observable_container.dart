import 'package:flutter/foundation.dart';

typedef ContainerChangeListener<C> = void Function(C);

/// Base class for all observable container types (for List, Map, etc.).
abstract class ObservableContainer<C, N> extends ChangeNotifier
    implements ValueListenable<C> {
  var _containerListeners = ObserverList<ContainerChangeListener<N>>();

  @override
  @protected
  bool get hasListeners {
    return _containerListeners.isNotEmpty || super.hasListeners;
  }

  void addContainerListener(ContainerChangeListener<N> listener) {
    _containerListeners.add(listener);
  }

  void removeContainerListener(ContainerChangeListener<N> listener) {
    _containerListeners.remove(listener);
  }

  @override
  void dispose() {
    super.dispose();
    _containerListeners = null;
  }

  @protected
  void notify(N change) {
    notifyListeners();
    final localListeners =
        List<ContainerChangeListener<N>>.from(_containerListeners);
    for (final listener in localListeners) {
      if (_containerListeners.contains(listener)) {
        listener(change);
      }
    }
  }
}
