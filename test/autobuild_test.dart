import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reactive_state/reactive_state.dart';

void main() {
  testWidgets('observes value change', (WidgetTester tester) async {
    final tagsValue = Value<List<String>>(<String>['a', 'b']);
    final derivedTags = DerivedValue((get, track) =>
        List<String>.unmodifiable(<String>['X']..addAll(get(tagsValue))));
    final counter = ValueNotifier<int>(0);
    final widget = AutoBuild(builder: (context, get, track) {
      var count = get(counter);
      var tags = get(derivedTags);
      return MaterialApp(
        title: 'Test',
        home: Scaffold(
          appBar: AppBar(title: Text('Test')),
          body: Column(
            children: <Widget>[
              Text('Count: $count'),
              Text('Tags: ${tags.join(",")}'),
            ],
          ),
        ),
      );
    });
    await tester.pumpWidget(widget);
    expect(find.text('Count: 0'), findsOneWidget);
    expect(find.text('Tags: X,a,b'), findsOneWidget);

    tagsValue.update((t) => t.add('c'));
    await tester.pumpWidget(widget);
    expect(find.text('Tags: X,a,b,c'), findsOneWidget);

    counter.value++;
    await tester.pumpWidget(widget);
    expect(find.text('Count: 1'), findsOneWidget);
  });
}
