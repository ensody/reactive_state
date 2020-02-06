import 'derived_value.dart';
import 'map_value.dart';
import 'observable_container.dart';
import 'value.dart';

/// A change event sent by observable list classes like [ListValue].
class ListChanged<T> {
  ListChanged(this.start, Iterable<T> removed, Iterable<T> added)
      : removed = List.unmodifiable(removed),
        added = List.unmodifiable(added);

  final int start;
  final List<T> removed;
  final List<T> added;
}

abstract class BaseListValue<T>
    extends ObservableContainer<List<T>, ListChanged<T>> {
  /// Creates an observable List.map() based on this list's values.
  BaseListValue<TOut> map<TOut>(TOut f(T x)) =>
      MappedListValue<TOut, T>(this, f);

  /// Creates an observable Map based on this list's values.
  BaseMapValue<K, V> toMap<K, V>(MapEntry<K, V> f(T x)) =>
      ListToMapValue<K, V, T>(this, f);
}

/// An observable List sending [ListChanged] events.
///
/// You can use this for more efficient List observers than would be possible
/// with e.g. [DerivedValue].
///
/// If you use-case requires always changing the whole instance instead of its
/// entries you might want to use [Value] instead because that's more efficient.
class ListValue<T> extends BaseListValue<T> {
  ListValue(Iterable<T> value) : _value = value.toList();

  List<T> _value;

  @override
  List<T> get value => List<T>.unmodifiable(_value);

  /// Updates the whole value.
  ///
  /// The resulting [ListChanged] will mark the whole old value as removed.
  /// Consider using [update] and returning a more fine-grained [ListChanged].
  set value(List<T> other) {
    final change = ListChanged(0, _value, other);
    _value = List.of(other);
    notify(change);
  }

  /// Updates the existing value using [func].
  ///
  /// The provided [func] function has to return a [ListChanged] instance
  /// describing all changes. Complex changes may require multiple update()
  /// calls and it might be easier to use the pre-defined list manipulation
  /// functions like [addAll], [insertAll], [setRange], [removeRange], etc.
  void update(ListChanged<T> func(List<T> val)) {
    notify(func(_value));
  }

  void operator []=(int index, T item) {
    final removed = _value[index];
    _value[index] = item;
    notify(ListChanged<T>(index, [removed], [item]));
  }

  set first(T item) {
    final removed = [if (_value.length > 0) _value.first];
    _value.first = item;
    notify(ListChanged<T>(0, removed, [item]));
  }

  set last(T item) {
    final removed = [if (_value.length > 0) _value.last];
    _value.last = item;
    notify(ListChanged<T>(0, removed, [item]));
  }

  void add(T item) {
    _value.add(item);
    notify(ListChanged<T>(_value.length - 1, [], [item]));
  }

  void addAll(Iterable<T> items) {
    final len = _value.length;
    _value.addAll(items);
    notify(ListChanged<T>(len, [], items));
  }

  void clear() {
    final removed = List<T>.unmodifiable(_value);
    _value.clear();
    notify(ListChanged<T>(0, removed, []));
  }

  void insert(int index, T item) {
    _value.insert(index, item);
    notify(ListChanged<T>(index, [], [item]));
  }

  void insertAll(int index, Iterable<T> items) {
    _value.insertAll(index, items);
    notify(ListChanged<T>(index, [], items));
  }

  void setAll(int index, Iterable<T> items) {
    final removed = _value.sublist(index, index + items.length);
    _value.setAll(index, items);
    notify(ListChanged<T>(index, removed, items));
  }

  bool remove(T item) {
    final index = _value.indexOf(item);
    if (index < 0) {
      return false;
    }
    removeAt(index);
    return true;
  }

  T removeAt(int index) {
    final result = _value.removeAt(index);
    notify(ListChanged<T>(index, [result], []));
    return result;
  }

  T removeLast() {
    final result = _value.removeLast();
    notify(ListChanged<T>(_value.length - 1, [result], []));
    return result;
  }

  void setRange(int start, int end, Iterable<T> items, [int skipCount = 0]) {
    if (end <= start) {
      return;
    }
    final removed = _value.sublist(start, end);
    _value.removeRange(start, end);
    notify(ListChanged<T>(start, removed, items));
  }

  void removeRange(int start, int end) {
    if (end <= start) {
      return;
    }
    final removed = _value.sublist(start, end);
    _value.removeRange(start, end);
    notify(ListChanged<T>(start, removed, []));
  }
}

/// Like an observable [List.map]().
class MappedListValue<T, TIn> extends BaseListValue<T> {
  MappedListValue(this.parent, this.func)
      : _value = parent.value.map(func).toList() {
    parent.addContainerListener(_onChange);
  }

  final ObservableContainer<List<TIn>, ListChanged<TIn>> parent;
  final T Function(TIn value) func;
  final List<T> _value;

  @override
  List<T> get value => List.unmodifiable(_value);

  @override
  void dispose() {
    parent.removeContainerListener(_onChange);
    super.dispose();
  }

  void _onChange(ListChanged<TIn> change) {
    final removed =
        _value.sublist(change.start, change.start + change.removed.length);
    final added = change.added.map<T>(func);
    if (change.removed.isNotEmpty) {
      _value.removeRange(change.start, change.start + change.removed.length);
    }
    if (change.added.isNotEmpty) {
      _value.insertAll(change.start, added);
    }
    notify(ListChanged<T>(change.start, removed, added));
  }
}
