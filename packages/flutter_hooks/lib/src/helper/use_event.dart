import '../../flutter_hooks.dart';

ObjectGetRef<T> useEvent<T>(T fun) {
  final ref = useRef(fun);
  useAlawaysEffect((e) {
    ref.value = fun;
  });
  return ref as ObjectGetRef<T>;
}

///
/// 尝试写成js中的形式,但是只有dynamic,没有类型签名
///
dynamic useDynamicEvent<T extends Function>(T fun) {
  final ref = useMemo((e) {
    return _EventProxy(fun);
  }, emptyList);
  useAlawaysEffect((e) {
    ref.target = fun;
  });

  return ref as dynamic;
}

class _EventProxy<T> {
  Function target;

  _EventProxy(this.target);
  @override
  dynamic noSuchMethod(Invocation invocation) {
    /**
     * 函数调用时,
     * invocation.memberName=Symbol("call")
     */
    return Function.apply(
        target, invocation.positionalArguments, invocation.namedArguments);
  }
}
