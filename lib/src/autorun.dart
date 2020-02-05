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

/// Observes [Listenable] instances, so [AutoBuild] can redraw itself when necessary.
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
