import 'package:flutter/foundation.dart';
import 'package:flutter/src/widgets/framework.dart';

import '../../flutter_hooks.dart';

VoidCallback useUpdate() {
  return use(_UpdateHook());
}

class _UpdateHook extends Hook<VoidCallback> {
  @override
  HookState<VoidCallback, Hook<VoidCallback>> createState(
      HookState<VoidCallback, Hook<VoidCallback>>? beforeState) {
    return _UpdateHookState();
  }
}

class _UpdateHookState extends HookState<VoidCallback, _UpdateHook> {
  bool _disposed = false;
  void _callback() {
    if (_disposed) {
      return;
    }
    setState(emptyFun);
  }

  @override
  VoidCallback build(BuildContext context) {
    return _callback;
  }

  @override
  void dispose(
      bool last, covariant HookState<VoidCallback, _UpdateHook>? beforeState) {
    _disposed = true;
  }
}
