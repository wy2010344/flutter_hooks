import 'package:flutter/foundation.dart';

import '../../flutter_hooks.dart';

typedef FutureGet<T> = Future<T> Function();
typedef RequestPromiseFinally<T> = void Function(
    FutureResult<T, FutureGet<T>> v);
void useRenderFuture<T>(
  RequestPromiseFinally<T> initFinally,
  FutureGet<T>? request,
) {
  final onFinally = useEvent((FutureResult<T, FutureGet<T>> data) {
    if (request == data.other) {
      initFinally(data);
    }
  });

  useEffect((e) {
    if (request != null) {
      final future = request();
      future.then((value) {
        onFinally.value(FutureSuccess(value, future, request));
      }).catchError((error) {
        onFinally.value(FutureError(error, future, request));
      });
    }
  }, [request]);
}

MemoFutureState<T> useMemoPromise<T>(
  FutureGet<T>? request, {
  (void Function(T v),)? onSuccess,
  (void Function(dynamic error),)? onError,
}) {
  final value = useState<FutureResult<T, FutureGet<T>>?>(null);
  useRenderFuture((data) {
    value.value = data;
    switch (data) {
      case FutureSuccess<T, FutureGet<T>>():
        onSuccess ?? (data.data);
      case FutureError<T, FutureGet<T>>():
        onError ?? (data.data);
    }
  }, request);
  return MemoFutureState(value, request);
}

class MemoFutureState<T> {
  final ValueNotifier<FutureResult<T, FutureGet<T>>?> value;
  final FutureGet<T>? request;
  MemoFutureState(this.value, this.request);

  FutureResult<T, FutureGet<T>>? get data {
    return request == null ? null : value.value;
  }

  bool get loading {
    return value.value?.other != request;
  }

  bool setValue(T v) {
    final d = data;
    if (d != null) {
      switch (d) {
        case FutureSuccess<T, FutureGet<T>>():
          value.value = FutureSuccess(v, d.future, d.other);
          return true;
        default:
      }
    }
    return false;
  }
}
