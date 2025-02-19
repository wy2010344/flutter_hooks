part of 'hooks.dart';

/// Creates a [WidgetStatesController] that will be disposed automatically.
///
/// See also:
/// - [WidgetStatesController]
WidgetStatesController useWidgetStatesController({
  Set<WidgetState>? values,
  List<Object?>? keys,
}) {
  return use(
    _WidgetStatesControllerHook(
      keys,
      values: values,
    ),
  );
}

class _WidgetStatesControllerHook extends ListHook<WidgetStatesController> {
  const _WidgetStatesControllerHook(super.keys, {required this.values});

  final Set<WidgetState>? values;

  @override
  HookState<WidgetStatesController, Hook<WidgetStatesController>> createState(
          beforeState) =>
      _WidgetStateControllerHookState();
}

class _WidgetStateControllerHookState
    extends HookState<WidgetStatesController, _WidgetStatesControllerHook> {
  late final controller = WidgetStatesController(hook.values);

  @override
  WidgetStatesController build(BuildContext context) => controller;

  @override
  void dispose(last, newerState) => controller.dispose();

  @override
  String get debugLabel => 'useWidgetStatesController';
}
