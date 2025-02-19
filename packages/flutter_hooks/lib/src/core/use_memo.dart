import 'package:flutter/widgets.dart';

import '../../flutter_hooks.dart';

/// Caches the instance of a complex object.
///
/// [useMemo] will immediately call [valueBuilder] on first call and store its result.
/// Later, when the [HookWidget] rebuilds, the call to [useMemo] will return the previously created instance without calling [valueBuilder].
///
/// A subsequent call of [useMemo] with different [keys] will re-invoke the function to create a new instance.
T useMemo<T, V>(
  T Function(MemoEvent<T, V> e) valueBuilder,
  V dep,
) {
  return use(
    _MemoizedHook<T, V>(valueBuilder, dep, listOrOneEqual),
  );
}

/// memo event
mixin MemoEvent<T, Trigger> {
  /// 本次的触发者
  Trigger? trigger;

  ///上一次的值
  late T? beforeValue;

  ///上一次的触发
  Trigger? beforeTrigger;

  ///是否是第一次执行
  late bool isInit;
}

class _MemoizedHook<T, V> extends Hook<T> {
  const _MemoizedHook(this.valueBuilder, this.dep, this.compareEqual);

  final V dep;

  final MCompare<V> compareEqual;

  @override
  bool shouldPreserveState(Hook<Object?> newHooks) {
    if (newHooks is! _MemoizedHook) {
      return false;
    }
    return compareEqual(this.dep, newHooks.dep);
  }

  final T Function(MemoEvent<T, V> e) valueBuilder;

  @override
  _MemoHookState<T, V> createState(
    beforeState,
  ) {
    final bs = beforeState as _MemoHookState<T, V>?;
    return _MemoHookState<T, V>(
      dep,
      bs == null,
      bs?.trigger,
      bs?.value,
    );
  }
}

class _MemoHookState<T, V> extends HookState<T, _MemoizedHook<T, V>>
    with MemoEvent<T, V> {
  _MemoHookState(
    this.trigger,
    this.isInit,
    this.beforeTrigger,
    this.beforeValue,
  );
  late final T value = hook.valueBuilder(this);

  ///触发者
  @override
  final V? trigger;
  @override
  final bool isInit;
  @override
  final V? beforeTrigger;
  @override
  final T? beforeValue;

  @override
  T build(BuildContext context) {
    return value;
  }

  @override
  String get debugLabel => 'useMemoized<$T>';
}
