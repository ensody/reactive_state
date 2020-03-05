import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'autorun.dart';

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
class AutoBuild extends StatefulWidget {
  AutoBuild({Key key, @required this.builder}) : super(key: key);

  final AutoBuilder builder;

  @override
  _AutoBuildState createState() => _AutoBuildState();
}

class _AutoBuildState extends State<AutoBuild> {
  AutoRunner<Widget> _autoRunner;
  Widget _cache;

  @override
  void initState() {
    super.initState();
    _autoRunner = AutoRunner(
        (get, track) => widget.builder(context, get, track),
        onChange: () => setState(() => _cache = null));
  }

  @override
  void dispose() {
    _autoRunner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _cache ??= _autoRunner.run();
}
