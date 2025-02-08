import 'package:flutter/material.dart';

import '../flutter_hooks.dart';

const emptyList = [];

void emptyFun() {}

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
