part of 'hooks.dart';

/// Watches a value and triggers a callback whenever the value changed.
///
/// [useValueChanged] takes a [valueChange] callback and calls it whenever [value] changed.
/// [valueChange] will _not_ be called on the first [useValueChanged] call.
///
/// [useValueChanged] can also be used to interpolate
/// Whenever [useValueChanged] is called with a different [value], calls [valueChange].
/// The value returned by [useValueChanged] is the latest returned value of [valueChange] or `null`.
///
/// The following example calls [AnimationController.forward] whenever `color` changes
///
/// ```dart
/// AnimationController controller;
/// Color color;
///
/// useValueChanged(color, (_, __) {
///   controller.forward();
/// });
/// ```
R? useValueChanged<T, R>(
  T value,
  R? Function(T oldValue, R? oldResult) valueChange,
) {
  return use(_ValueChangedHook(value, valueChange));
}

class _ValueChangedHook<T, R> extends Hook<R?> {
  const _ValueChangedHook(this.value, this.valueChanged);

  final R? Function(T oldValue, R? oldResult) valueChanged;
  final T value;

  @override
  _ValueChangedHookState<T, R> createState(
    beforeState,
  ) =>
      _ValueChangedHookState<T, R>();
}

class _ValueChangedHookState<T, R>
    extends HookState<R?, _ValueChangedHook<T, R>> {
  R? _result;

  @override
  void didUpdateHook(_ValueChangedHook<T, R> oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.value != oldHook.value) {
      _result = hook.valueChanged(oldHook.value, _result);
    }
  }

  @override
  R? build(BuildContext context) {
    return _result;
  }

  @override
  String get debugLabel => 'useValueChanged';

  @override
  bool get debugHasShortDescription => false;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('value', hook.value));
    properties.add(DiagnosticsProperty('result', _result));
  }
}
