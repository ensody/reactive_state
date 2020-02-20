import 'derived_value.dart';
import 'list_value.dart';
import 'observable_container.dart';

/// A change event sent by observable map classes like [MapValue].
///
/// Entries that got updated/replaced appear in [removed] wit their old value
/// and in [added] with their new value.
class MapChanged<K, V> {
  MapChanged(Map<K, V> removed, Map<K, V> added)
      : removed = Map.unmodifiable(removed),
        added = Map.unmodifiable(added);

  /// Entries that got removed.
  final Map<K, V> removed;

  /// Entries that got added.
  final Map<K, V> added;
}

abstract class BaseMapValue<K, V>
    extends ObservableContainer<Map<K, V>, MapChanged<K, V>> {
  BaseMapValue<KOut, VOut> map<KOut, VOut>(
          MapEntry<KOut, VOut> func(K key, V value)) =>
      MappedMapValue(this, func);
}

/// An observable Map sending [MapChanged] events.
///
/// You can use this for more efficient Map observers than would be possible
/// with e.g. [DerivedValue].
///
/// If you use-case requires always changing the whole instance instead of its
/// entries you might want to use [Value] instead because that's more efficient.
class MapValue<K, V> extends BaseMapValue<K, V> {
  MapValue(Map<K, V> value) : _value = Map.of(value);

  Map<K, V> _value;

  @override
  Map<K, V> get value => Map<K, V>.unmodifiable(_value);

  /// Updates the whole value.
  ///
  /// The resulting [MapChanged] will mark the whole old value as removed.
  /// Consider using [update] and returning a more fine-grained [MapChanged].
  set value(Map<K, V> other) {
    final change = MapChanged(_value, other);
    _value = Map.of(other);
    notify(change);
  }

  /// Updates the existing value using [func].
  ///
  /// The provided [func] function has to return a [MapChanged] instance
  /// describing all changes.
  void update(MapChanged<K, V> func(Map<K, V> val)) {
    notify(func(_value));
  }

  void operator []=(K key, V value) {
    final removed = {if (_value.containsKey(key)) key: _value[key]};
    _value[key] = value;
    notify(MapChanged<K, V>(removed, {key: value}));
  }

  void addAll(Map<K, V> items) {
    final removed = <K, V>{
      for (var key in items.keys) if (_value.containsKey(key)) key: _value[key]
    };
    _value.addAll(items);
    notify(MapChanged<K, V>(removed, items));
  }

  void clear() {
    final removed = Map<K, V>.unmodifiable(_value);
    _value.clear();
    notify(MapChanged<K, V>(removed, {}));
  }
}

/// Like an observable [Map.map]().
class MappedMapValue<K, V, KIn, VIn> extends BaseMapValue<K, V> {
  MappedMapValue(this.parent, this.func) : _value = parent.value.map(func) {
    parent.addContainerListener(_onChange);
  }

  final BaseMapValue<KIn, VIn> parent;
  final MapEntry<K, V> Function(KIn key, VIn value) func;
  final Map<K, V> _value;

  @override
  Map<K, V> get value => Map.unmodifiable(_value);

  @override
  void dispose() {
    parent.removeContainerListener(_onChange);
    super.dispose();
  }

  void _onChange(MapChanged<KIn, VIn> change) {
    final removed = change.removed.map(func);
    final added = change.added.map(func);
    for (var key in removed.keys) {
      _value.remove(key);
    }
    _value.addAll(added);
    notify(MapChanged<K, V>(removed, added));
  }
}

/// An observable Map, sourced from an observable List.
class ListToMapValue<K, V, T> extends BaseMapValue<K, V> {
  ListToMapValue(this.parent, this.func) {
    _value.addEntries(_mapping..addAll(parent.value.map(func)));
    parent.addContainerListener(_onChange);
  }

  final ObservableContainer<List<T>, ListChanged<T>> parent;
  final MapEntry<K, V> Function(T item) func;
  final _value = <K, V>{};
  final _mapping = <MapEntry<K, V>>[];

  @override
  Map<K, V> get value => Map.unmodifiable(_value);

  @override
  void dispose() {
    parent.removeContainerListener(_onChange);
    super.dispose();
  }

  void _onChange(ListChanged<T> change) {
    final removed = Map.fromEntries(
        _mapping.sublist(change.start, change.start + change.removed.length));
    final addedMapped = change.added.map(func);
    _mapping.replaceRange(
        change.start, change.start + change.removed.length, addedMapped);
    final added = Map.fromEntries(addedMapped);
    for (var key in removed.keys) {
      _value.remove(key);
    }
    _value.addAll(added);
    notify(MapChanged<K, V>(removed, added));
  }
}
