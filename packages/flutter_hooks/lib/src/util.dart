import 'package:flutter/material.dart';

import '../flutter_hooks.dart';

const emptyList = [];

void emptyFun() {}

typedef OneCreater<V, T> = T Function(V);

T quote<T>(T v) {
  return v;
}

typedef GetValue<T> = T Function();
typedef SetValue<T> = void Function(T);
typedef Compare<T> = bool Function(T, T);
typedef MCompare<V> = bool Function(V, dynamic);

typedef Builder = Widget Function(BuildContext context);
HookBuilder createC(Builder builder) {
  return HookBuilder(key: ValueKey(builder), builder: builder);
}

List<Widget> _children = List.empty();
List<Widget> listBuilder(VoidCallback render) {
  final before = _children;
  List<Widget> children = [];
  _children = children;
  render();
  _children = before;
  return children;
}

Widget hookChild(Widget widget) {
  _children.add(widget);
  return widget;
}

VoidCallback subscribeValueNotifier<T>(
    ValueNotifier<T> notifier, void Function(T e) callback) {
  void listener() {
    callback(notifier.value);
  }

  notifier.addListener(listener);
  return () {
    notifier.removeListener(listener);
  };
}

bool simpleEqual(dynamic a, dynamic b) {
  return a == b;
}

bool simpleNotEqual(dynamic a, dynamic b) {
  return a != b;
}

void emptySet(dynamic a) {}

/// 要么 a与b简单相等
/// 要么 a的列表与b列表相等
bool listOrOneEqual(dynamic a, dynamic b) {
  if (a == b) {
    return true;
  }
  if (a is List && b is List) {
    return listDeppEqual(a, b);
  }
  return false;
}

void run(Function fun) {
  fun();
}

extension ObjectExtension on Object {
  List<T> asList<T>() {
    return [this as T];
  }
}

bool listDeppEqual(List<Object?> p1, List<Object?> p2) {
  if (p1.length != p2.length) {
    return false;
  }
  final i1 = p1.iterator;
  final i2 = p2.iterator;
  // ignore: literal_only_boolean_expressions, returns will abort the loop
  while (true) {
    if (!i1.moveNext() || !i2.moveNext()) {
      return true;
    }

    final curr1 = i1.current;
    final curr2 = i2.current;

    if (curr1 is num && curr2 is num) {
      // Checks if both are NaN
      if (curr1.isNaN && curr2.isNaN) {
        continue;
      }

      // Checks if one is 0.0 and the other is -0.0
      if (curr1 == 0 && curr2 == 0) {
        if (curr1.isNegative != curr2.isNegative) {
          return false;
        }
        continue;
      }
    }

    if (curr1 != curr2) {
      return false;
    }
  }
}
