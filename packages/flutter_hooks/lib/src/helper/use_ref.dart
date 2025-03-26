import 'package:flutter/foundation.dart';
import '../core/use_memo.dart';
import '../util.dart';

class ObjectGetRef<T> {
  @protected
  T _value;
  ObjectGetRef(this._value);
  T get value {
    return _value;
  }
}

/// A class that stores a single value.
///
/// It is typically created by [useRef].
class ObjectRef<T> extends ObjectGetRef<T> {
  /// A class that stores a single value.
  ///
  /// It is typically created by [useRef].
  ObjectRef(super._value);
  set value(T v) {
    _value = v;
  }
}

/// Creates an object that contains a single mutable property.
///
/// Mutating the object's property has no effect.
/// This is useful for sharing state across `build` calls, without causing
/// unnecessary rebuilds.
ObjectRef<T> useRef<T>(T initialValue) {
  return useMemo((e) => ObjectRef<T>(initialValue), emptyList);
}

ObjectRef<T> useRefCreateOne<T, V>(OneCreater<V, T> creater, V init) {
  return useMemo((e) => ObjectRef<T>(creater(init)), emptyList);
}

ObjectRef<T> useRefCreate<T>(T Function() creater) {
  return useMemo((e) => ObjectRef<T>(creater()), emptyList);
}
