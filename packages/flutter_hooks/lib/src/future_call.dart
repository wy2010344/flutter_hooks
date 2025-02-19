import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../flutter_hooks.dart';

sealed class FutureResult<T, V> {
  final Future<T> future;
  final V other;
  FutureResult(this.future, this.other);
}

class FutureSuccess<T, V> extends FutureResult<T, V> {
  final T data;
  FutureSuccess(this.data, super.future, super.other);
}

class FutureError<T, V> extends FutureResult<T, V> {
  final dynamic data;
  FutureError(this.data, super.future, super.other);
}

/// 正好,处理异常事件也使用监听
abstract class AbsFutureChangeNotifier<T, V> extends ChangeNotifier {
  AbsFutureChangeNotifier({this.block = false, this.callback = emptyFun});
  final bool block;
  //可以减少不必要的监听
  final VoidCallback callback;
  Future<T>? _future;
  FutureResult<T, V>? _result;
  Future<T>? get request {
    return _future;
  }

  FutureResult<T, V>? get result {
    return _result;
  }

  V createOther();
  bool setData(Future<T> future) {
    if (future == _future) {
      return false;
    }
    if (block && onLoading) {
//如果是阻塞模式,则正在加载中不允许进入
      return false;
    }
    _future = future;
    notifyListeners();
    final other = createOther();
    future.then((v) {
      if (future == _future) {
        _result = FutureSuccess(v, future, other);
        callback();
        notifyListeners();
      }
    });
    future.catchError((e) {
      if (future == _future) {
        _result = FutureError(e, future, other);
        callback();
        notifyListeners();
      }
    });
    return true;
  }

  /// 有请求提交,正在加载中,等待请求返回
  bool get onLoading {
    return _future != null && _future != _result?.future;
  }

  /// 未初始化未正在加载中
  bool get notLoadOrloading {
    if (_result != null) {
      return _result!.future != _future;
    }
    return true;
  }
}

class FutureChangeNotifier<T> extends AbsFutureChangeNotifier<T, Null> {
  @override
  Null createOther() {
    return null;
  }
}
