import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_state/reactive_state.dart';

void main() {
  test('container chaining', () {
    final listValue = ListValue(<int>[]);
    final mappedList = listValue.map((x) => x);
    final mappedStringList = mappedList.map((x) => x.toString());
    final listToMap = mappedStringList.toMap((x) => MapEntry(int.parse(x), x));
    final invertedMap = listToMap.map((k, v) => MapEntry(v, k));
    expect(mappedList.value, equals(listValue.value));
    listValue.add(2);
    expect(listValue.value, equals([2]));
    expect(mappedList.value, equals(listValue.value));
    listValue.addAll([4, 1]);
    listValue.add(3);
    listValue.add(5);
    expect(listValue.value, equals([2, 4, 1, 3, 5]));
    expect(mappedList.value, equals(listValue.value));
    listValue.removeAt(1);
    listValue.add(8);
    listValue.removeAt(3);
    expect(listValue.value, equals([2, 1, 3, 8]));
    expect(mappedList.value, equals(listValue.value));
    expect(listToMap.value, equals({2: '2', 1: '1', 3: '3', 8: '8'}));
    expect(invertedMap.value, equals({'2': 2, '1': 1, '3': 3, '8': 8}));
  });
}
