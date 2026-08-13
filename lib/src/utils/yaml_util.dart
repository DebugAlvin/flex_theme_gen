import 'dart:io';
import 'dart:convert';
import 'package:yaml/yaml.dart';

/// 统一处理 YAML / JSON 文件解析的工具类
///
/// - 自动识别 `.yaml` / `.yml` / `.json`
/// - 自动将 YamlMap / YamlList 转换为 Dart Map / List
/// - 提供安全异常提示
class YamlUtil {
  /// 读取文件并解析为 `Map<String, dynamic>`
  static Map<String, dynamic> load(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw StateError('未找到配置文件: $path');
    }

    final content = file.readAsStringSync();
    final isYaml = path.endsWith('.yaml') || path.endsWith('.yml');

    try {
      final data = isYaml ? loadYaml(content) : jsonDecode(content);
      if (data is! Map) {
        throw StateError('配置文件顶层必须为 Map: $path');
      }
      return _normalize(data);
    } catch (e) {
      throw StateError('解析配置文件失败 ($path): $e');
    }
  }

  /// 将 [YamlMap] / [YamlList] 转换为普通 Dart 对象
  static dynamic _normalize(dynamic value) {
    if (value is YamlMap) {
      return value.map((k, v) => MapEntry(k.toString(), _normalize(v)));
    } else if (value is YamlList) {
      return value.map(_normalize).toList();
    } else {
      return value;
    }
  }
}