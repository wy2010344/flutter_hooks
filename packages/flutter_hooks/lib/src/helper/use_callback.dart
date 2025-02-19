import '../core/use_memo.dart';

/// Cache a function across rebuilds based on a list of keys.
///
/// This is syntax sugar for [useMemo], so that instead of:
///
/// ```dart
/// final cachedFunction = useMemoized(() => () {
///   print('doSomething');
/// }, [key]);
/// ```
///
/// we can directly do:
///
/// ```dart
/// final cachedFunction = useCallback(() {
///   print('doSomething');
/// }, [key]);
/// ```
T useCallback<T extends Function>(
  T callback, [
  List<Object?> keys = const <Object>[],
]) {
  return useMemo((e) => callback, keys);
}
