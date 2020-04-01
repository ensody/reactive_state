import 'package:flutter/foundation.dart';

/// Observer callback used by [autoRun] and [AutoRunner].
typedef R AutoRunCallback<R>(
  T Function<T>(ValueListenable<T> valueListenable) get,
  S Function<S extends Listenable>(S listenable) track,
);

/// Watches [Listener]s for changes.
///
/// This is a convenience function that immediately starts the [AutoRunner.run]
/// cycle for you.
///
/// Returns the underlying [AutoRunner]. To stop watching, you should call
/// [AutoRunner.dispose].
///
/// See [AutoRunner] for more details.
AutoRunner<void> autoRun(AutoRunCallback observer, {VoidCallback onChange}) =>
    AutoRunner<void>(observer, onChange: onChange)..run();

/// Just the minimum interface needed for [Resolver]. No generic types.
abstract class _BaseAutoRunner {
  void _addListenable(Listenable listenable);
}

/// Watches [Listener]s for changes.
class AutoRunner<T> implements _BaseAutoRunner {
  /// Given an [observer], this class will automatically register itself as a
  /// listener and keep track of the [Listener]s which [observer] depends on.
  ///
  /// You have to call [run] once to start watching.
  ///
  /// To stop watching, you should call [dispose].
  ///
  /// You can provide a custom [onChange] callback to manually call [run] at
  /// some later point, which in turn triggers the [observer].
  AutoRunner(this.observer, {VoidCallback onChange}) {
    _listener = onChange ?? run;
    _resolver = Resolver._(this);
  }

  final AutoRunCallback<T> observer;

  VoidCallback _listener;
  Resolver _resolver;

  /// Stops watching [Listenable]s.
  void dispose() {
    _observe((_) {});
  }

  /// Calls [observer] and tracks its dependencies.
  T run() {
    return _observe(
        (Resolver resolver) => observer(resolver.get, resolver.track));
  }

  T _observe<T>(T func(Resolver resolve)) {
    final next = Resolver._(this);
    try {
      return func(next);
    } finally {
      for (var item in _resolver._listenables.difference(next._listenables)) {
        item.removeListener(_listener);
      }
      _resolver = next;
    }
  }

  void _addListenable(Listenable listenable) {
    if (!_resolver._listenables.contains(listenable)) {
      listenable.addListener(_listener);
    }
  }
}

/// Tracks [Listenable]s for [AutoRunner].
class Resolver {
  Resolver._(this._autoRunner);

  final _BaseAutoRunner _autoRunner;
  final _listenables = <Listenable>{};

  /// Shorthand for [get].
  T call<T>(ValueListenable<T> listenable) => get(listenable);

  /// Get the [ValueListenable.value] and [track] the listenable.
  T get<T>(ValueListenable<T> listenable) => track(listenable).value;

  /// Track change events for [listenable].
  T track<T extends Listenable>(T listenable) {
    if (_listenables.add(listenable)) {
      _autoRunner._addListenable(listenable);
    }
    return listenable;
  }
}
