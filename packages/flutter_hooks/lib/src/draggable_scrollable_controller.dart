part of 'hooks.dart';

/// Creates a [DraggableScrollableController] that will be disposed automatically.
///
/// See also:
/// - [DraggableScrollableController]
DraggableScrollableController useDraggableScrollableController({
  List<Object?>? keys,
}) {
  return use(_DraggableScrollableControllerHook(keys));
}

class _DraggableScrollableControllerHook
    extends ListHook<DraggableScrollableController> {
  const _DraggableScrollableControllerHook(super.keys);

  @override
  HookState<DraggableScrollableController, Hook<DraggableScrollableController>>
      createState(beforeState) => _DraggableScrollableControllerHookState();
}

class _DraggableScrollableControllerHookState extends HookState<
    DraggableScrollableController, _DraggableScrollableControllerHook> {
  final controller = DraggableScrollableController();

  @override
  String get debugLabel => 'useDraggableScrollableController';

  @override
  DraggableScrollableController build(BuildContext context) => controller;

  @override
  void dispose(last, newerState) => controller.dispose();
}
