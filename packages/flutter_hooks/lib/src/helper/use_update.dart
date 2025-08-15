import 'package:flutter/foundation.dart';
import 'package:flutter/src/widgets/framework.dart';

import '../../flutter_hooks.dart';

typedef BD<T> = T Function(VoidCallback fun);
T useUpdateT<T>(BD<T> toT) {
  return use(_UpdateHook<T>(toT));
}

VoidCallback useUpdateFun() {
  return useUpdateT(quote);
}

class _UpdateHook<T> extends Hook<T> {
  BD<T> _build;
  _UpdateHook(this._build) {}
  @override
  HookState<T, Hook<T>> createState(HookState<T, Hook<T>>? beforeState) {
    return _UpdateHookState<T>(_build);
  }
}

class _UpdateHookState<T> extends HookState<T, _UpdateHook<T>> {
  BD<T> _build;
  _UpdateHookState(this._build) {}
  bool _disposed = false;
  void _callback() {
    if (_disposed) {
      return;
    }
    setState(emptyFun);
  }

  @override
  T build(BuildContext context) {
    return _build(_callback);
  }

  @override
  void dispose(bool last, covariant HookState<T, _UpdateHook<T>>? beforeState) {
    _disposed = true;
  }
}
