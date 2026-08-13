class JsonUtil {
  /// 读取必填字段并校验类型
  static T requireField<T>(
      Map<String, dynamic> map,
      String key, {
        required String path,
      }) {
    if (!map.containsKey(key) || map[key] == null) {
      throw StateError('[$path.$key] 必填字段缺失或为 null');
    }
    final value = map[key];
    if (value is! T) {
      throw StateError('[$path.$key] 期望类型 $T，实际：${value.runtimeType} ($value)');
    }
    return value;
  }

  /// 读取数值字段（支持 num / string），支持 fallback
  static double readNum(
      Map<String, dynamic> map,
      String key, {
        required String path,
        double? fallback,
      }) {
    final value = map[key];
    if (value == null) {
      if (fallback != null) return fallback;
      throw StateError('[$path.$key] 期望数值，实际：null');
    }
    if (value is num) return value.toDouble();
    if (value is String) {
      final t = value.trim();
      if (t.isEmpty && fallback != null) return fallback;
      final parsed = double.tryParse(t);
      if (parsed != null) return parsed;
    }
    throw StateError('[$path.$key] 期望数值，实际：${value.runtimeType} ($value)');
  }

  /// 读取字符串字段，支持 fallback
  static String readString(
      Map<String, dynamic> map,
      String key, {
        required String path,
        String? fallback,
      }) {
    final value = map[key];
    if (value == null) {
      if (fallback != null) return fallback;
      throw StateError('[$path.$key] 期望字符串，实际：null');
    }
    if (value is String) return value;
    throw StateError('[$path.$key] 期望字符串，实际：${value.runtimeType} ($value)');
  }

  /// defaults → node 合并（node 覆盖 defaults）
  static Map<String, dynamic> mergedNode(
      Map<String, dynamic> defaults,
      Map<String, dynamic> node,
      ) {
    return <String, dynamic>{...defaults, ...node};
  }

  /// 判断 key 是否存在且非 null
  static bool has(Map<String, dynamic> map, String key) {
    return map.containsKey(key) && map[key] != null;
  }

  /// 尝试读取任意字段，不抛异常
  static T? tryRead<T>(
      Map<String, dynamic> map,
      String key, {
        required String path,
      }) {
    try {
      final value = map[key];
      if (value is T) return value;
      return null;
    } catch (_) {
      return null;
    }
  }
}