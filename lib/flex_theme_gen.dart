/// Gen Flex Theme
///
/// 命令行工具：根据 design_tokens.yaml 自动生成 Flutter 主题 Tokens 与链式别名。
///
/// - 支持 CLI 调用: `dart run flex_theme_gen:gen_flex_theme build`
/// - 支持代码调用（通过导入）
///
/// 示例：
/// ```bash
/// dart run flex_theme_gen:gen_flex_theme build
/// dart run flex_theme_gen:gen_flex_theme watch
/// ```
///
/// 或在 Dart 程序中使用：
/// ```dart
/// import 'package:flex_theme_gen/flex_theme_gen.dart';
///
/// Future<void> main() async {
///   final paths = Paths(
///     inputPath: 'assets/design_tokens.yaml',
///     outDir: 'lib/theme/',
///     templatesDir: 'lib/src/templates',
///   );
///   await runGenerateThemeTokens(paths: paths);
/// }
/// ```

library flex_theme_gen;

export 'src/generate_theme_tokens.dart' show runGenerateThemeTokens;
export 'src/core/base.dart' show Paths;
export 'src/core/base.dart' show ThemeGenerator;

/// 当前包版本号。
const String genFlexThemeVersion = '1.1.0';

/// 打印工具信息 Banner。
void printGenFlexThemeBanner() {
  print('''
✨ gen_flex_theme v$genFlexThemeVersion
--------------------------------------
根据 design_tokens.yaml 自动生成 Flutter 主题代码。
命令用法：
  dart run flex_theme_gen:gen_flex_theme build
  dart run flex_theme_gen:gen_flex_theme watch
项目主页：https://pub.dev/packages/flex_theme_gen
''');
}
