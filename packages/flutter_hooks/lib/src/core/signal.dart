import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../../flutter_hooks.dart';
import '../helper/use_update.dart';

class _CurrentBatch {
  _CurrentBatch(this.signals, this.listeners, this.effects);
  Set<_Signal<dynamic>> signals;
  Set<Function> listeners;
  SplayTreeMap<double, List<Function>> effects;
}

Function? _currentFun;
_CurrentBatch? _currentBatch;
SplayTreeMap<double, List<Function>>? _currentEffects;
List<_CurrentBatch> _recycleBatches = [];
Map<Function, dynamic>? _currentRelay;

void memoKeep(Function fun) {
  final oldCurrent = _currentFun;
  final oldCurrentRelay = _currentRelay;
  _currentFun = null;
  _currentRelay = null;
  fun();
  _currentFun = oldCurrent;
  _currentRelay = oldCurrentRelay;
}

void addEffect(Function effect, {double level = 0}) {
  late Map<double, List<Function>> effects;
  if (_currentEffects != null) {
    effects = _currentEffects!;
  } else {
    _beginCurrentBatch();
    effects = _currentBatch!.effects;
  }

  var olds = effects[level];
  if (olds == null) {
    olds = [];
    effects[level] = olds;
  }
  olds.add(effect);
}

void _addRelay(Function get, dynamic value) {
  _currentRelay?[get] = value;
}

void _addListener(Function listener) {
  _currentBatch!.listeners.add(listener);
}

mixin Signal<T> {
  T get();
  void set(T v);

  late T value;
}

class _Signal<T> with Signal<T> {
  _Signal(this._value, this._shouldChange) {
    this._dirtyValue = _value;
  }
  bool _dirty = false;
  late T _dirtyValue;
  T _value;
  final Compare<dynamic> _shouldChange;
  final List<Set<Function>> _listeners = [{}, {}];

  T getValue() {
    if (_dirty) {
      return _dirtyValue;
    }
    return _value;
  }

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
    if (_currentFun != null) {
      throw Exception('计算期间不允许修改值');
    }
    if (_currentEffects != null) {
      throw Exception('计算期间不允许修改值1');
    }
    if (_dirty) {
      _dirtyValue = v;
    } else {
      if (_listeners[0].isEmpty) {
        this._value = v;
      } else {
        if (this._shouldChange(_value, v)) {
          _dirty = true;
          _dirtyValue = v;
          _beginCurrentBatch();
          _currentBatch!.signals.add(this);
        }
      }
    }
  }

  bool acceptChange(T v) {
    if (this._dirty) {
      return true;
    }
    return _shouldChange(_value, v);
  }

  void commit() {
    _dirty = false;
    if (_shouldChange(_dirtyValue, _value)) {
      _value = _dirtyValue;
      final oldListener = _listeners.removeAt(0);
      oldListener.forEach(_addListener);
      oldListener.clear();
      _listeners.add(oldListener);
    }
  }

  @override
  T get() {
    final value = this.getValue();
    _addRelay(get, value);
    if (_currentFun != null) {
      _listeners[0].add(_currentFun!);
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
  return _currentEffects != null;
}

void _beginCurrentBatch() {
  if (_currentBatch == null) {
    if (_recycleBatches.isEmpty) {
      _currentBatch = _CurrentBatch({}, {}, SplayTreeMap());
    } else {
      _currentBatch = _recycleBatches.removeAt(0);
    }
    Future.microtask(batchSignalEnd);
  }
}

void _commitSignal(_Signal<dynamic> signal) {
  signal.commit();
}

// ignore: public_member_api_docs
void batchSignalEnd() {
  if (_currentEffects != null) {
    print("执行effect中不能batchSignalEnd");
    return;
  }
  if (_currentEffects != null) {
    print("执行listener中中不能batchSignalEnd");
    return;
  }
  while (true) {
    if (_currentBatch != null) {
      final currentBatch = _currentBatch!;
      currentBatch.signals.forEach(_commitSignal);
      currentBatch.signals.clear();

      _currentBatch = null;
      _currentEffects = currentBatch.effects;

      final listeners = currentBatch.listeners;
      listeners.forEach(run);
      listeners.clear();
      _currentEffects = null;

      final effects = currentBatch.effects;
      effects.forEach(_runEffect);
      effects.clear();
      _recycleBatches.add(currentBatch);

      if (_recycleBatches.length > 2) {
        print('出现了${_recycleBatches.length}个recycleBatches');
      }
    } else {
      break;
    }
  }
}

void _runEffect(double level, List<Function> effects) {
  effects.forEach(run);
}

class _TrackSignal<T> implements SignalMemoEvent<T> {
  T Function(SignalMemoEvent<T> e) _get;
  void Function(T) _set;
  _TrackSignal(this._get, this._set) {}
  var _disabled = false;
  var _inited = false;
  late T _lastValue;
  @override
  bool get inited => _inited;

  @override
  T get lastValue => _lastValue;

  addFun() {
    if (_disabled) {
      return;
    }

    _currentFun = addFun;
    final value = this._get(this);
    _currentFun = null;
    if (inited) {
      if (value != lastValue) {
        _lastValue = value;
        this._set(value);
      }
    } else {
      _inited = true;
      _lastValue = value;
      this._set(value);
    }
  }

  void dispose() {
    _disabled = true;
  }
}

// 在render期间,将更新注入信号
// 信号变更,只是将SignalHookBuilder变脏
class SignalHookBuilder extends HookBuilder {
  SignalHookBuilder({required super.builder, super.key});

  @override
  Widget build(BuildContext context) {
    final update = useUpdate();
    _currentFun = update;
    final widget = builder(context);
    _currentFun = null;
    return widget;
  }
}

// ignore: public_member_api_docs
void Function() trackSignal<T>(
    T Function(SignalMemoEvent<T> e) get, void Function(T) set) {
  final trackSignal = _TrackSignal(get, set);
  trackSignal.addFun();
  return trackSignal.dispose;
}

bool _relayChange(Map<GetValue<dynamic>, dynamic> relays) {
  for (final get in relays.keys) {
    final old = relays[get];
    if (get() != old) {
      return true;
    }
  }
  return false;
}

typedef SignalMemoReducer<T> = T Function(SignalMemoEvent<T>);

T _memoGet<T>(Map<GetValue<dynamic>, dynamic> relays, SignalMemoReducer<T> get,
    SignalMemoEvent<T> e) {
  relays.clear();
  _currentRelay = relays;
  final v = get(e);
  return v;
}

// ignore: public_member_api_docs
mixin SignalMemoEvent<T> {
  bool get inited;
  T get lastValue;
}

abstract class Memo<T> {
  T get value;
}

class _Memo<T> extends Memo<T> with SignalMemoEvent<T> {
  _Memo(this._get, this._after);
  T _getValue() {
    var shouldAfter = false;

    final lastRelay = _currentRelay;
    _currentRelay = null;
    if (_inited) {
      if (_relayChange(_relays)) {
        final value = _memoGet(_relays, _get, this);
        if (value != _value) {
          _value = value;
          shouldAfter = true;
        }
      }
    } else {
      _value = _memoGet(_relays, _get, this);
      _inited = true;
      shouldAfter = true;
    }
    _currentRelay = lastRelay;

    _addRelay(_getValue, value);
    if (shouldAfter) {
      _after(value);
    }
    return value;
  }

  late T _value;
  bool _inited = false;
  @override
  T get value {
    return _getValue();
  }

  Map<GetValue<dynamic>, dynamic> _relays = {};
  SignalMemoReducer<T> _get;
  SetValue<T> _after;

  @override
  T get lastValue => _value;

  @override
  bool get inited => _inited;
}

// ignore: public_member_api_docs
Memo<T> memo<T>(SignalMemoReducer<T> get, [SetValue<T> after = emptySet]) {
  return _Memo(get, after);
}

GetValue<T> memoFun<T>(SignalMemoReducer<GetValue<T>> get,
    [SetValue<GetValue<T>> after = emptySet]) {
  final value = memo<GetValue<T>>(get, after);
  return () {
    return value.value();
  };
}
