// lib/src/generate_theme_tokens.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'core/colors_generator.dart';
import 'core/fonts_generator.dart';
import 'core/tokens_generator.dart';
import 'core/typography_generator.dart';
import 'utils/yaml_util.dart';
import 'core/base.dart';
import 'fonts/font_declarations.dart';

typedef Logger = void Function(String message);

/// 运行主题生成流程。
/// - [paths] 指定输入/输出/模板目录
/// - [watch] 是否进入监听模式（文件修改后自动重新生成）
/// - [logger] 可选日志输出（默认 stdout）
Future<void> runGenerateThemeTokens({
  required Paths paths,
  bool watch = false,
  Logger? logger,
}) async {
  final log = logger ?? (m) => stdout.writeln(m);

  Future<Map<String, dynamic>> _loadDesignTokens(String inputPath) async {
    final file = File(inputPath);
    if (!file.existsSync()) {
      throw StateError('未找到 design tokens 文件：$inputPath');
    }

    final ext = p.extension(inputPath).toLowerCase();
    try {
      if (ext == '.yaml' || ext == '.yml') {
        // 优先 YAML
        return YamlUtil.load(inputPath);
      } else if (ext == '.json') {
        final txt = await file.readAsString();
        final obj = jsonDecode(txt);
        if (obj is Map<String, dynamic>) return obj;
        throw StateError('JSON 顶层必须为对象。');
      } else {
        // 自动尝试：先 YAML 再 JSON
        try {
          return YamlUtil.load(inputPath);
        } catch (_) {
          final txt = await file.readAsString();
          final obj = jsonDecode(txt);
          if (obj is Map<String, dynamic>) return obj;
          throw StateError('无法解析文件（既不是合法 YAML 也不是合法 JSON）：$inputPath');
        }
      }
    } catch (e) {
      throw StateError('解析 design tokens 失败：$e');
    }
  }

  Future<void> _runOnce() async {
    try {
      final root = await _loadDesignTokens(paths.inputPath);

      final fonts = FontDeclarations.load(root, paths, log);

      // 这里按依赖拓扑排序：Colors -> Tokens -> Fonts -> Typography
      final generators = <ThemeGenerator>[
        ColorsGenerator(),
        TokensGenerator(),
        FontsGenerator(declarations: fonts),
        TypographyGenerator(declarations: fonts),
      ];

      log('▶️ Generating theme tokens...');
      for (final g in generators) {
        final now = DateTime.now().toIso8601String();
        log('• [${g.id}] start @ $now');
        g.run(root, paths, log);
      }
      log('✅ Theme files generated successfully.');
    } catch (e, st) {
      stderr.writeln('❌ Generation failed: $e');
      // 可选：输出堆栈，方便排查
      stderr.writeln(st);
      // 单次模式下直接抛出；watch 模式下仅输出错误继续监听
      if (!watch) rethrow;
    }
  }

  // --- 一次执行 ---
  await _runOnce();

  // --- 监听模式 ---
  if (watch) {
    final file = File(paths.inputPath);
    if (!file.existsSync()) {
      stderr.writeln('❌ ${paths.inputPath} not found.');
      return;
    }

    log('👀 Watching ${paths.inputPath} for changes...');
    DateTime lastTick = DateTime.fromMillisecondsSinceEpoch(0);
    const debounce = Duration(milliseconds: 500);

    final sub =
        file.watch(events: FileSystemEvent.modify).listen((event) async {
      final now = DateTime.now();
      if (now.difference(lastTick) < debounce) return; // 防抖
      lastTick = now;

      log('\n🔄 Detected change: ${event.path}');
      await _runOnce();
    });

    // 在 watch 模式下保持常驻，直到进程被外部终止（Ctrl+C）
    // 这里 await 永不返回；如需内置退出逻辑可添加取消条件
    await sub.asFuture<void>();
    await sub.cancel();
  }
}
