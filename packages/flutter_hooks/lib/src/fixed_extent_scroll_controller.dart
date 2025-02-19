part of 'hooks.dart';

/// Creates [FixedExtentScrollController] that will be disposed automatically.
///
/// See also:
/// - [FixedExtentScrollController]
FixedExtentScrollController useFixedExtentScrollController({
  int initialItem = 0,
  ScrollControllerCallback? onAttach,
  ScrollControllerCallback? onDetach,
  List<Object?>? keys,
}) {
  return use(
    _FixedExtentScrollControllerHook(
      keys,
      initialItem: initialItem,
      onAttach: onAttach,
      onDetach: onDetach,
    ),
  );
}

class _FixedExtentScrollControllerHook
    extends ListHook<FixedExtentScrollController> {
  const _FixedExtentScrollControllerHook(super.keys,
      {required this.initialItem, this.onAttach, this.onDetach});

  final int initialItem;
  final ScrollControllerCallback? onAttach;
  final ScrollControllerCallback? onDetach;

  @override
  HookState<FixedExtentScrollController, Hook<FixedExtentScrollController>>
      createState(beforeState) => _FixedExtentScrollControllerHookState();
}

class _FixedExtentScrollControllerHookState extends HookState<
    FixedExtentScrollController, _FixedExtentScrollControllerHook> {
  late final controller = FixedExtentScrollController(
    initialItem: hook.initialItem,
    onAttach: hook.onAttach,
    onDetach: hook.onDetach,
  );

  @override
  FixedExtentScrollController build(BuildContext context) => controller;

  @override
  void dispose(last, newerState) => controller.dispose();

  @override
  String get debugLabel => 'useFixedExtentScrollController';
}
