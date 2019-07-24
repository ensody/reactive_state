# flutter_simple_state

[![Pub](https://img.shields.io/pub/v/flutter_simple_state.svg)](https://pub.dev/packages/flutter_simple_state)
[![Build Status](https://travis-ci.com/wkornewald/flutter_simple_state.svg?branch=master)](https://travis-ci.com/wkornewald/flutter_simple_state)

Easy to understand state management for Flutter apps and for writing reusable Flutter components:

* Events are handled using callbacks/functions.
  * Nothing to learn: Simple concept that everybody knows.
  * Easy to debug/understand: Use "jump to definition" to see what the code does.
  * Good for reusable components: Callbacks work well with any app architecture (BLoC, Stream, etc.).
* State is held in one or multiple instances of `ValueNotifier`/`ValueListenable`.
  * Nothing to learn: Standard Flutter classes that are widely in use and that everybody knows.
  * You always have access to the current value (better than working with streams).
* `AutoRebuild` automatically rebuilds your widgets when a `ValueNotifier` (or actually, any `Listenable`) triggers a notification.
  * Tracks all `ValueListenable`/`Listenable` objects for you, so you don't have to call `addListener`/`removeListener`.
  * Provides fine-grained control for minimizing amount of redraws (more fine-grained than `InheritedWidget`).
  * Standard Flutter classes like `TextEditingController` and `Animation` implement `ValueListenable` and thus work nicely with `AutoRebuild`.
* No indirection and no boilerplate (e.g. compared to [BLoC](https://www.didierboelens.com/2018/08/reactive-programming---streams---bloc/) or Redux).
  * No custom event objects.
  * No event handlers with long `switch()` statements.
  * No streams, no ugly `StreamBuilder`.
  * Only small, trivial code that everyone can understand and debug with ease.

## Usage

A simple `AutoRebuild` example:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_simple_state/flutter_simple_state.dart';

class MyPage extends StatelessWidget {
  MyPage({Key key, @required this.counter}) : super(key: key);

  final ValueNotifier<int> counter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Counter')),
      body: Column(
        children: <Widget>[
          AutoRebuild(builder: (context, get, track) {
            return Text('Counter: ${get(counter)}');
          }),
          MaterialButton(
            onPressed: () => counter.value++,
            child: Text('Increment'),
          ),
        ],
      ),
    );
  }
}
```

Also, take a look at the [example](https://github.com/wkornewald/flutter_simple_state/blob/master/example/lib/main.dart) in the repo.
It shows everything you need to know.

As a rule of thumb, try to avoid global state because that can make your code too tightly coupled and at some point turn into a monolithic mess.
Imagine your app as a tree of pages (and each page as a tree of widgets) and think about which page depends on which state/action:
Put the state/action as deeply nested (close to the leafs) in the tree as possible.
Use arguments instead of `Provider` if that's convenient enough.
Only use global state if every part of your app depends on it (e.g. the currently logged-in user).

## Value vs ValueNotifier

As an alternative to `ValueNotifier` you can also use `flutter_simple_state`'s `Value` class which provides an `update()` method for modifying more complex objects:

```dart
class User {
  String name = '';
  String email = '';
  // ...
}

var userValue = Value(User());
userValue.update((user) {
  user.name = 'Adam';
  user.email = 'adam@adam.com';
});
```

This is similar to calling `setState()` with `StatefulWidget`.
With `update()` you can change multiple attributes and `Value` will trigger a single notification once finished - even if nothing was changed (so you don't need to implement comparison operators for complex objects).
