library flutter_simple_state;

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

typedef R AutoRunCallback<R>(
  T Function<T>(ValueListenable<T> valueListenable) get,
  S Function<S extends Listenable>(S listenable) track,
);

/// Watches [Listener]s for changes.
///
/// Given a [builder], this class will automatically register itself as a
/// listener and keep track of the [Listener]s which the [builder] depends on.
///
/// You have to call [run] once to start listening.
///
/// To stop watching, you should call [dispose].
///
/// You can provide a custom [onChange] callback to manually call [run] at
/// some later point, which in turn triggers the [builder].
class AutoRunner<T> {
  AutoRunner(this.builder, {VoidCallback onChange}) {
    _resolverState = _ResolverState(onChange ?? run);
  }

  final AutoRunCallback<T> builder;
  _ResolverState _resolverState;

  void dispose() {
    _resolverState.dispose();
  }

  T run() {
    return _resolverState
        .observe((_Resolver resolve) => builder(resolve.get, resolve.track));
  }
}

/// Watches [Listener]s for changes.
///
/// This is a convenience function that immediately starts the [AutoRunner.run]
/// cycle for you.
///
/// Returns the underlying [AutoRunner]. To stop watching, you should call
/// [AutoRunner.dispose].
///
/// See [AutoRunner] for more details.
AutoRunner<void> autorun(AutoRunCallback builder, {VoidCallback onChange}) =>
    AutoRunner<void>(builder, onChange: onChange)..run();

typedef Widget AutoBuilder(
    BuildContext context,
    T Function<T>(ValueListenable<T> valueListenable) get,
    S Function<S extends Listenable>(S listenable) track);

/// Keeps the UI in sync with one or more [ValueListenable]s or [Listenable]s.
///
/// Given a [builder], this class will automatically register itself as a
/// listener and keep track of the [Listener]s which the [builder] depends on.
///
/// This is especially useful for managing state with [ValueNotifier],
/// [Value], or a custom [ValueListenable].
///
/// The [builder] is passed the `context`, a `get` and a `track` function.
/// Call `get(valueListenable)` to retrieve the value of a [ValueListenable]
/// instance and mark it as a dependency.
/// Call `track(listenable)` to mark a [Listenable] as a dependency.
class AutoRebuild extends StatefulWidget {
  AutoRebuild({Key key, @required this.builder}) : super(key: key);

  final AutoBuilder builder;

  @override
  _AutoRebuildState createState() => _AutoRebuildState();
}

class _AutoRebuildState extends State<AutoRebuild> {
  AutoRunner<Widget> _autoRunner;

  @override
  void initState() {
    super.initState();
    _autoRunner = AutoRunner(
        (get, track) => widget.builder(context, get, track),
        onChange: () => setState(() {}));
  }

  @override
  void dispose() {
    _autoRunner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _autoRunner.run();
  }
}

class _ResolverState {
  _ResolverState(this.listener) {
    _resolve = _Resolver(this);
  }

  final VoidCallback listener;
  _Resolver _resolve;

  void dispose() {
    observe((_) {});
  }

  bool isListening(Listenable listenable) => _resolve.isListening(listenable);

  T observe<T>(T func(_Resolver resolve)) {
    final resolve = _Resolver(this);
    try {
      return func(resolve);
    } finally {
      for (var item in _resolve._listenables.difference(resolve._listenables)) {
        item.removeListener(listener);
      }
      _resolve = resolve;
    }
  }
}

/// Observes [Listenable] instances, so [AutoRebuild] can redraw itself when necessary.
class _Resolver {
  _Resolver(this._state);

  final _ResolverState _state;
  final _listenables = <Listenable>{};

  bool isListening(Listenable listenable) => _listenables.contains(listenable);

  /// Shorthand to get the [ValueListenable.value] and [track] the listenable.
  T get<T>(ValueListenable<T> listenable) {
    track(listenable);
    return listenable.value;
  }

  /// Track change events for [listenable].
  T track<T extends Listenable>(T listenable) {
    if (_listenables.add(listenable) && !_state.isListening(listenable)) {
      listenable.addListener(_state.listener);
    }
    return listenable;
  }
}

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
