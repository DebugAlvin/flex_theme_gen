import 'package:path/path.dart' as p;

import '../utils/template_utils.dart';
import '../utils/yaml_util.dart';

typedef Logger = void Function(String message);

class Paths {
  final String inputPath;
  final String outDir;
  final String templatesDir;
  const Paths({
    required this.inputPath,
    required this.outDir,
    required this.templatesDir,
  });

  String joinOut(String file) => p.normalize(p.join(outDir, file));

  // 便捷方法：直接读模板
  String loadTpl(String name) => loadTemplate(templatesDir, name);
}

abstract class ThemeGenerator {
  /// 模块 ID：'colors' | 'tokens' | 'typography'
  String get id;
  void run(Map<String, dynamic> root, Paths paths, Logger log);
}

/// 统一入口：加载 design_tokens 配置文件
///
/// - 自动识别 .yaml / .yml / .json
/// - 内部使用 [YamlUtil.load]
/// - 返回标准化 Map<String, dynamic>
Map<String, dynamic> loadDesignTokens(String path) {
  try {
    final root = YamlUtil.load(path);
    return root;
  } catch (e) {
    throw StateError('❌ 读取 design_tokens 失败 ($path): $e');
  }
}