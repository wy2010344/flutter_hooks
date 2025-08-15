import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../../flutter_hooks.dart';
import '../helper/use_update.dart';

final class _CurrentBatch {
  final List<_TrackSignal> deps = [];
  final Set<_TrackSignalBase> listeners = {};
  final SplayTreeMap<double, List<Function>> effects = SplayTreeMap();
}

final class UID {}

var _beginBatch = false;
var _onEffectRun = false;
var _callGet = false;
_TrackSignalBase? _currentFun;
var _currentBatch = _CurrentBatch();
var _nextBatch = _CurrentBatch();
UID _state = UID();
_CurrentBatch? _onWorkBatch;
Map<GetSignal<dynamic>, dynamic>? _currentRelay;

void addEffect(Function effect, {double level = 0}) {
  late Map<double, List<Function>> effects;
  if (_onWorkBatch != null) {
    effects = _onWorkBatch!.effects;
  } else {
    _beginCurrentBatch();
    effects = _currentBatch.effects;
  }
  var olds = effects[level];
  if (olds == null) {
    olds = [];
    effects[level] = olds;
  }
  olds.add(effect);
}

void _addRelay(GetSignal<dynamic> get, dynamic value) {
  _currentRelay?[get] = value;
}

mixin GetSignal<T> {
  T get value;
}
mixin Signal<T> implements GetSignal<T> {
  T get();
  void set(T v);

  late T value;
}

class _Signal<T> with Signal<T> {
  _Signal(this._value, this._shouldChange) {}
  T _value;
  final Compare<dynamic> _shouldChange;

  @override
  T get value {
    return this.get();
  }

  @override
  set value(T v) {
    this.set(v);
  }

  @override
  void set(T v) {
    if (_onWorkBatch != null) {
      throw Exception('计算期间不允许修改值');
    }
    if (_shouldChange(v, _value)) {
      if (_callGet) {
        _callGet = false;
        _state = UID();
      }
      _value = v;
      if (_currentBatch.listeners.isNotEmpty) {
        _beginCurrentBatch();
      }
    }
  }

  @override
  T get() {
    final value = this._value;
    _addRelay(this, value);
    if (_currentFun != null) {
      _currentBatch.listeners.add(_currentFun!);
    }
    return value;
  }
}

// ignore: public_member_api_docs
Signal<T> createSignal<T>(T value,
    {Compare<dynamic> shouldChange = simpleNotEqual}) {
  return _Signal(value, shouldChange);
}

bool signalOnUpdate() {
  return _onWorkBatch != null;
}

void _beginCurrentBatch() {
  if (_beginBatch) {
    return;
  }
  _beginBatch = true;
  Future.microtask(batchSignalEnd);
}

// ignore: public_member_api_docs
void batchSignalEnd() {
  if (_onEffectRun) {
    print("执行effect中不能batchSignalEnd");
    return;
  }
  if (_onWorkBatch != null) {
    print("执行listener中中不能batchSignalEnd");
    return;
  }
  while (_beginBatch) {
    _beginBatch = false;
    final currentBatch = _currentBatch;
    _currentBatch = _nextBatch;
    _nextBatch = currentBatch;

    final deps = currentBatch.deps;
    final effects = currentBatch.effects;
    _onWorkBatch = currentBatch;

    currentBatch.listeners.forEach(_listenerRun);
    currentBatch.listeners.clear();

    while (deps.isNotEmpty) {
      deps.removeAt(0).addFun();
    }
    _onWorkBatch = null;

    _onEffectRun = true;
    effects.forEach(_runEffect);
    effects.clear();
    _onEffectRun = false;
  }
}

void _listenerRun(_TrackSignalBase track) {
  track.addFun();
}

void _runEffect(double level, List<Function> effects) {
  effects.forEach(run);
}

mixin _TrackSignalBase {
  void addFun();
}

mixin TrackSignalArg<T> {
  T get(GetSignal<T>? e);
  void set(T v, GetSignal<T>? e);
}

class _TrackSignal<T> implements GetSignal<T>, _TrackSignalBase {
  final TrackSignalArg<T> arg;
  _TrackSignal(this.arg) {}
  var _disabled = false;
  var _inited = false;
  late T _lastValue;

  @override
  T get value => _lastValue;

  addFun() {
    if (_disabled) {
      return;
    }
    _currentFun = this;
    final value = this.arg.get(_inited ? this : null);
    _currentFun = null;
    if (_inited) {
      if (value != _lastValue) {
        _lastValue = value;
        this.arg.set(value, this);
      }
    } else {
      _inited = true;
      _lastValue = value;
      this.arg.set(value, null);
    }
  }

  T collect<T>(T Function() fun) {
    _currentFun = this;
    final o = fun();
    _currentFun = null;
    return o;
  }

  void dispose() {
    _disabled = true;
  }
}

class _TrackSignalBaseFun with _TrackSignalBase {
  var fun;
  _TrackSignalBaseFun(this.fun) {}
  @override
  void addFun() {
    this.fun();
  }
}

// 在render期间,将更新注入信号
// 信号变更,只是将SignalHookBuilder变脏
class SignalHookBuilder extends HookBuilder {
  SignalHookBuilder({required super.builder, super.key});

  @override
  Widget build(BuildContext context) {
    final update = useUpdateT(_TrackSignalBaseFun.new);
    _currentFun = update;
    final widget = builder(context);
    _currentFun = null;
    return widget;
  }
}

// ignore: public_member_api_docs
void Function() trackSignal<T>(TrackSignalArg<T> arg) {
  final trackSignal = _TrackSignal(arg);
  final deps = _onWorkBatch?.deps;
  if (deps != null) {
    deps.add(trackSignal);
  } else {
    batchSignalEnd();
    _currentBatch.deps.add(trackSignal);
  }
  return trackSignal.dispose;
}

typedef SignalMemoReducer<T> = T Function(GetSignal<T>?);

// ignore: public_member_api_docs

void _mapInject(GetSignal<dynamic> get, dynamic v) {
  get.value;
}

class _Memo<T> with GetSignal<T> {
  _Memo(this._get, this._after);

  UID? _stateVersion;
  _TrackSignalBase? _listener;

  T _memoGet() {
    _relays.clear();
    _currentRelay = _relays;
    return _get((_inited ? this : null) as GetSignal<T>?);
  }

  bool _relayChange() {
    for (final get in _relays.keys) {
      final old = _relays[get];
      if (get.value != old) {
        return true;
      }
    }
    return false;
  }

  T _getValue() {
    _callGet = true;
    if (_stateVersion == _state) {
      if (_onWorkBatch != null && _listener != _currentFun) {
        _listener = _currentFun;
        _relays.forEach(_mapInject);
      }
      _addRelay(this, _value);
      return _value;
    }

    var shouldAfter = false;
    final lastRelay = _currentRelay;
    _currentRelay = null;
    if (_inited) {
      if (_relayChange()) {
        final value = _memoGet();
        if (value != _value) {
          _value = value;
          shouldAfter = true;
        }
      }
    } else {
      _value = _memoGet();
      _inited = true;
      shouldAfter = true;
    }
    _currentRelay = lastRelay;

    _addRelay(this, _value);
    if (shouldAfter && _after != null) {
      _after!(_value);
    }
    return _value;
  }

  late T _value;
  bool _inited = false;
  @override
  T get value {
    return _getValue();
  }

  final Map<GetSignal<dynamic>, dynamic> _relays = {};
  final SignalMemoReducer<T> _get;
  final SetValue<T>? _after;
}

// ignore: public_member_api_docs
GetSignal<T> memo<T>(SignalMemoReducer<T> get, [SetValue<T>? after = null]) {
  return _Memo(get, after);
}

GetValue<T> memoFun<T>(SignalMemoReducer<GetValue<T>> get,
    [SetValue<GetValue<T>> after = emptySet]) {
  final value = memo<GetValue<T>>(get, after);
  return () {
    return value.value();
  };
}

class _UpdateSignal with TrackSignalArg {
  VoidCallback callback;
  _UpdateSignal(this.callback) {}

  @override
  get(GetSignal? e) {}
  @override
  void set(v, GetSignal? e) {}
}

T useTrackSignal<T>(GetValue<T> callback) {
  final value = use(_TrackSignalHook());
  return value.collect<T>(callback);
}

class _TrackSignalHook extends Hook<_TrackSignal> {
  @override
  HookState<_TrackSignal, Hook<_TrackSignal>> createState(
      HookState<_TrackSignal, Hook<_TrackSignal>>? beforeState) {
    return _TrackSignalState();
  }
}

class _TrackSignalState extends HookState<_TrackSignal, _TrackSignalHook> {
  late _TrackSignal t;
  @override
  _TrackSignal build(BuildContext context) {
    t = _TrackSignal(_UpdateSignal(() {
      setState(emptyFun);
    }));
    return t;
  }

  @override
  void dispose(bool last,
      covariant HookState<_TrackSignal, _TrackSignalHook>? beforeState) {
    t.dispose();
  }
}
