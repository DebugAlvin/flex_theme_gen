// bin/flex_theme_gen.dart
import 'dart:io';
import 'dart:isolate'; // 👈 新增
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'package:flex_theme_gen/src/generate_theme_tokens.dart' hide Logger;
import 'package:flex_theme_gen/src/core/base.dart'; // Paths / Logger

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.first == '-h' || args.first == '--help') {
    _printHelp();
    return;
  }

  final command = args.first; // build | watch
  final rest = args.length > 1 ? args.sublist(1) : const <String>[];

  // 1) 读取 pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  Map<String, dynamic> pubCfg = {};
  if (pubspecFile.existsSync()) {
    try {
      final doc = loadYaml(pubspecFile.readAsStringSync());
      final cfg = doc is YamlMap ? doc['flex_theme_gen'] : null;
      if (cfg is YamlMap) {
        pubCfg = Map<String, dynamic>.from(
          cfg.map((k, v) => MapEntry(k.toString(), v)),
        );
      } else if (cfg is Map) {
        pubCfg = Map<String, dynamic>.from(cfg);
      }
    } catch (e) {
      stderr.writeln('⚠️  解析 pubspec.yaml 失败：$e');
    }
  }

  // 2) 命令行参数
  String? inputPath;
  String? outDir;
  String? tplDirArg;
  for (int i = 0; i < rest.length; i++) {
    final v = rest[i];
    if (v == '--input' && i + 1 < rest.length) inputPath = rest[i + 1];
    if (v == '--out'   && i + 1 < rest.length) outDir   = rest[i + 1];
    if (v == '--tpl'   && i + 1 < rest.length) tplDirArg= rest[i + 1];
  }

  // 3) 回落到 pubspec.yaml
  inputPath ??= pubCfg['input']?.toString();
  outDir    ??= pubCfg['output']?.toString();

  // 4) 默认兜底
  inputPath ??= 'design_tokens.yaml';
  outDir    ??= 'output/';

  // 5) 解析模板目录（命令行 > 包内目录 > 本地相对目录）
  final templatesDir = await _resolveTemplatesDirAbs(tplDirArg);

  // 6) 校验输入
  if (!File(inputPath).existsSync()) {
    stderr.writeln('❌ 未找到配置文件：$inputPath');
    stderr.writeln('请在 pubspec.yaml 中添加：\n'
        'flex_theme_gen:\n'
        '  input: design_tokens.yaml\n'
        '  output: lib/generated/\n');
    exit(1);
  }

  // 规范化 & 确保输出目录
  final normInput = p.normalize(inputPath);
  final normOut   = p.normalize(outDir);
  Directory(normOut).createSync(recursive: true);

  final paths = Paths(
    inputPath: normInput,
    outDir: normOut,
    templatesDir: templatesDir, // 👈 现在一定是绝对路径
  );

  final watch = (command == 'watch');
  void logger(String m) => stdout.writeln(m);

  stdout.writeln('⚙️  flex_theme_gen 配置加载成功：');
  stdout.writeln('  输入: ${paths.inputPath}');
  stdout.writeln('  输出: ${paths.outDir}');
  stdout.writeln('  模板: ${paths.templatesDir}\n');

  await runGenerateThemeTokens(
    paths: paths,
    watch: watch,
    logger: logger,
  );
}

void _printHelp() {
  stdout.writeln('''
gen_flex_theme - 设计 Token → Flutter 主题代码生成器

用法：
  gen_flex_theme build  [--input <path>] [--out <dir>] [--tpl <dir>]
  gen_flex_theme watch  [--input <path>] [--out <dir>] [--tpl <dir>]
  gen_flex_theme --help

参数：
  --input   指定 design_tokens.yaml 路径（默认 design_tokens.yaml）
  --out     指定生成代码输出目录（默认 output/）
  --tpl     指定模板目录（默认使用包内置模板）

也可在 pubspec.yaml 中统一配置（命令行优先）：
  flex_theme_gen:
    input: design_tokens.yaml
    output: lib/generated/
''');
}

/// 解析模板目录（返回**绝对路径**）：
/// 1) 如果用户传了 --tpl，返回其绝对路径；
/// 2) 尝试用 package URI 定位：package:flex_theme_gen/src/templates/
/// 3) 再退回到相对目录 ./lib/src/templates （仅开发期）
/// 不成功则报错退出（避免再次出现“模板不存在”）。
Future<String> _resolveTemplatesDirAbs(String? arg) async {
  if (arg != null && arg.trim().isNotEmpty) {
    final abs = p.normalize(p.absolute(arg));
    if (Directory(abs).existsSync()) return abs;
    stderr.writeln('⚠️  --tpl 指定的目录不存在：$abs');
  }

  // A) 正规做法：通过 Package URI 定位到包内 lib/src/templates
  try {
    final uri = await Isolate.resolvePackageUri(
      Uri.parse('package:flex_theme_gen/src/templates/'),
    );
    if (uri != null) {
      final abs = File.fromUri(uri).path;
      if (Directory(abs).existsSync()) return abs;
    }
  } catch (_) {}

  // B) 开发期 fallback：项目相对目录
  final dev = p.normalize(p.absolute(p.join('lib', 'src', 'templates')));
  if (Directory(dev).existsSync()) return dev;

  stderr.writeln('❌ 未能定位模板目录。请通过 --tpl 指定：');
  stderr.writeln('   gen_flex_theme build --tpl lib/src/templates');
  exit(1);
}