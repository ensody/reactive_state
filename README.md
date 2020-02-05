# reactive_state

[![Pub](https://img.shields.io/pub/v/reactive_state.svg)](https://pub.dev/packages/reactive_state)
[![Build Status](https://travis-ci.com/ensody/reactive_state.svg?branch=master)](https://travis-ci.com/ensody/reactive_state)

Easy to understand reactive state management for Flutter apps and for writing reusable Flutter components.

## Principles

### Observable state

State is held in one or multiple instances of `Value` or similar classes implementing `ValueNotifier`. These are standard Flutter interfaces that everybody knows from `TextEditingController`, `Animation`, etc.

### Reactive widgets

`AutoBuild` automatically rebuilds your widgets when a `ValueNotifier` (or any `Listenable`) triggers a notification. It's similar to Flutter's `ValueListenableBuilder`, but it can track multiple dependencies and also works with `Listenable`.

No need to call `addListener`/`removeListener`. Just `get()` the value directly while `AutoBuild` takes care of tracking your dependencies.

Unlike `InheritedWidget` and `Provider` you get fine-grained control over what gets rebuilt.

Standard Flutter classes like `TextEditingController` and `Animation` implement `ValueListenable` and thus work nicely with `AutoBuild`.

### Derived/computed state

`DerivedValue` is an observable value that is computed (derived) from other observable values.

TODO: Similar classes optimized for `List`, `Map`, `Set` are planned.

### Less boilerplate and indirection

Compared the same code to [BLoC](https://www.didierboelens.com/2018/08/reactive-programming---streams---bloc/) or Redux.

In contrast, reactive_state has:

* No streams, no `StreamBuilder`, no asynchronous loading of widgets.
* No special event objects, no event handlers with long `switch()` statements.

## Usage

Note: Also see [reference](https://pub.dev/documentation/reactive_state/latest/) for details.

A simple `AutoBuild` example:

```dart
import 'package:flutter/material.dart';
import 'package:reactive_state/reactive_state.dart';

class MyPage extends StatelessWidget {
  MyPage({Key key, @required this.counter}) : super(key: key);

  final ValueNotifier<int> counter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Counter')),
      body: Column(
        children: <Widget>[
          AutoBuild(builder: (context, get, track) {
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

Note that in real-world applications you shouldn't directly mutate the state, but instead put that into separate methods e.g. on an object made accessible through the [provider](https://pub.dev/packages/provider) package.

Also, take a look at the [example](https://github.com/ensody/reactive_state/blob/master/example/lib/main.dart) in the repo.

## autorun and AutoRunner

Outside of widgets you might still want to react to state changes.
You can do that with `autorun()` and `AutoRunner` (see [reference](https://pub.dev/documentation/reactive_state/latest/) for details).

## Value vs ValueNotifier

As an alternative to `ValueNotifier` you can also use `reactive_state`'s `Value` class which provides an `update()` method for modifying more complex objects:

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

## DerivedValue

`DerivedValue` is a dynamically calculated `ValueListenable` that updates its value whenever its dependencies change:

```dart
var user = Value(User());
var emailLink = DerivedValue((get, track) => 'mailto:${get(user).email}');
```

Here, `emailLink` can be observed on its own and is updated whenever `user` is modified.
