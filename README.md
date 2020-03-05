# reactive_state

[![Pub](https://img.shields.io/pub/v/reactive_state.svg)](https://pub.dev/packages/reactive_state)
[![Build Status](https://travis-ci.com/ensody/reactive_state.svg?branch=master)](https://travis-ci.com/ensody/reactive_state)

An easy to understand reactive state management solution for Flutter.

## Principles

### Observable state

State is held in one or multiple instances of `Value` or similar classes implementing `ValueNotifier`.
These are standard Flutter interfaces that everybody knows from `TextEditingController`, `Animation`, etc.

Additionally, you can use `ListValue` and `MapValue` for creating observable `List` and `Map` values that can notify you about fine-grained change events (instead of the whole value changing).

### Reactive widgets

`AutoBuild` automatically rebuilds your widgets when a `ValueNotifier` (or any `Listenable`) triggers a notification. It's similar to Flutter's `ValueListenableBuilder`, but it can track multiple dependencies and also works with `Listenable`.

No need to call `addListener`/`removeListener`. Just `get()` the value directly while `AutoBuild` takes care of tracking your dependencies.

Unlike `InheritedWidget` and `Provider` you get fine-grained control over what gets rebuilt.

Standard Flutter classes like `TextEditingController` and `Animation` implement `ValueListenable` and thus work nicely with `AutoBuild`.

### Derived/computed state

`DerivedValue` is an observable value that is computed (derived) from other observable values.

Also, `ListValue` and `MapValue` provide `.map()` and other operations for creating derived containers that keep themselves updated on a per-element basis.

### Less boilerplate and indirection

The resulting code is much simpler than the same solution in [BLoC](https://www.didierboelens.com/2018/08/reactive-programming---streams---bloc/) or Redux.

* No streams, no `StreamBuilder`, no asynchronous loading of widgets (unless you really need it).
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

## autoRun and AutoRunner

Outside of widgets you might still want to react to state changes.
You can do that with `autoRun()` and `AutoRunner` (see [reference](https://pub.dev/documentation/reactive_state/latest/) for details).

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

## ListValue and MapValue

A simple example showing a few things that can be done:

```dart
final listValue = ListValue(<int>[]);
final mappedList = listValue.map((x) => x.toString());
final listToMap = mappedList.toMap((x) => MapEntry(2 * int.parse(x), x));
final invertedMap = listToMap.map((k, v) => MapEntry(v, k));

listValue.addAll([4, 1]);
// => invertedMap.value == {'4': 8, '1': 2}
```
