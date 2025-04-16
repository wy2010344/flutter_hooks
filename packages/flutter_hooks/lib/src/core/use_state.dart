import 'package:flutter/widgets.dart';
import '../../flutter_hooks.dart';

/// Creates a variable and subscribes to it.
///
/// Whenever [ValueNotifier.value] updates, it will mark the caller [HookWidget]
/// as needing a build.
/// On the first call, it initializes [ValueNotifier] to [initialData]. [initialData] is ignored
/// on subsequent calls.
///
/// The following example showcases a basic counter application:
///
/// ```dart
/// class Counter extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final counter = useState(0);
///
///     return GestureDetector(
///       // automatically triggers a rebuild of the Counter widget
///       onTap: () => counter.value++,
///       child: Text(counter.value.toString()),
///     );
///   }
/// }
/// ```
///
/// See also:
///
///  * [ValueNotifier]
///  * [useStreamController], an alternative to [ValueNotifier] for state.
ValueNotifier<T> useState<T>(T initialData) {
  return use(_StateHook(quote, initialData));
}

ValueNotifier<T> useStateCreateOne<T, V>(OneCreater<V, T> creater, V init) {
  return use(_StateHook(creater, init));
}

abstract class AbsStateHook<T> extends Hook<ValueNotifier<T>> {
  /**重载这个初始化的类 */
  T create();

  @override
  _StateHookState<T> createState(
    beforeState,
  ) =>
      _StateHookState(ValueNotifier(create()));
}

class _StateHook<T, V> extends AbsStateHook<T> {
  final V init;
  final OneCreater<V, T> creater;
  _StateHook(this.creater, this.init);
  @override
  T create() {
    return creater(init);
  }
}

class _StateHookState<T> extends HookState<ValueNotifier<T>, AbsStateHook<T>> {
  final ValueNotifier<T> _state;
  _StateHookState(this._state) {
    _state.addListener(_listener);
  }

  @override
  void dispose(last, newerState) {
    _state.dispose();
  }

  @override
  ValueNotifier<T> build(BuildContext context) => _state;

  void _listener() {
    setState(emptyFun);
  }

  @override
  Object? get debugValue => _state.value;

  @override
  String get debugLabel => 'useState<$T>';
}
