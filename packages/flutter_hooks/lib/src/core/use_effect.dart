import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../flutter_hooks.dart';

mixin EffectDisposeEvent<V> {
  ///是否是最张销毁
  late bool isDestroy;

  /// 销毁的时候,是effect自身的trigger,不是触发销毁的trigger
  late V trigger;

  ///是触发销毁最新的事件,如果isDestroy=true,则是null
  late EffectEvent<V>? destroyEvent;
}

/// A function called when the state of a widget is destroyed.
typedef Dispose<V> = void Function(EffectDisposeEvent<V> e);

/// Useful for side-effects and optionally canceling them.
///
/// [useEffect] is called synchronously on every `build`, unless
/// [keys] is specified. In which case [useEffect] is called again only if
/// any value inside [keys] has changed.
///
/// It takes an [effect] callback and calls it synchronously.
/// That [effect] may optionally return a function, which will be called when the [effect] is called again or if the widget is disposed.
///
/// By default [effect] is called on every `build` call, unless [keys] is specified.
/// In which case, [effect] is called once on the first [useEffect] call and whenever something within [keys] change/
///
/// The following example call [useEffect] to subscribes to a [Stream] and cancels the subscription when the widget is disposed.
/// Also if the [Stream] changes, it will cancel the listening on the previous [Stream] and listen to the new one.
///
/// ```dart
/// Stream stream;
/// useEffect(() {
///     final subscription = stream.listen(print);
///     // This will cancel the subscription when the widget is disposed
///     // or if the callback is called again.
///     return subscription.cancel;
///   },
///   // when the stream changes, useEffect will call the callback again.
///   [stream],
/// );
/// ```
void useEffect<V>(Dispose<V>? Function(EffectEvent<V> e) effect, V dep) {
  use(_EffectHook(effect, dep, listOrOneEqual));
}

bool _alawaysFalse(dynamic a, dynamic b) {
  return false;
}

void useAlawaysEffect(Dispose<void>? Function(EffectEvent<void> e) effect) {
  use(_EffectHook(effect, null, _alawaysFalse));
}

// memo event
mixin EffectEvent<V> {
  late V trigger;
  //是否是第一次执行
  late bool isInit;
  //上一次的触发
  late V? beforeTrigger;
}

class _EffectHook<V> extends Hook<void> {
  const _EffectHook(this.effect, this.dep, this.compareEqual);

  final V dep;

  final MCompare<V> compareEqual;

  final Dispose<V>? Function(EffectEvent<V> e) effect;

  @override
  _EffectHookState<V> createState(
    beforeState,
  ) {
    final bs = beforeState as _EffectHookState<V>?;
    return _EffectHookState(dep, bs == null, bs?.trigger);
  }

  @override
  bool shouldPreserveState(Hook<Object?> newHooks) {
    if (newHooks is! _EffectHook) {
      return false;
    }
    return compareEqual(dep, newHooks.dep);
  }
}

class _EffectHookState<V> extends HookState<void, _EffectHook<V>>
    with EffectEvent<V>, EffectDisposeEvent<V> {
  _EffectHookState(this.trigger, this.isInit, this.beforeTrigger);
  final V trigger;
  final bool isInit;
  final V? beforeTrigger;
  bool isDestroy = false;

  Dispose<V>? disposer;

  @override
  void initHook() {
    super.initHook();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduleEffect();
    });
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose(last, newer) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isDestroy = last;
      destroyEvent = newer as _EffectHookState<V>?;
      disposer?.call(this);
    });
  }

  void scheduleEffect() {
    disposer = hook.effect(this);
  }

  @override
  String get debugLabel => 'useEffect';

  @override
  bool get debugSkipValue => true;
}
