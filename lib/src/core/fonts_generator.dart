import 'dart:io';

import 'base.dart';
import '../fonts/font_declarations.dart';
import '../fonts/sfnt_metrics.dart';
import '../fonts/metrics_template.dart';
import '../utils/template_utils.dart';

/// FontsGenerator
/// 动态生成：
///   1) fonts.g.dart   —— 字体家族 & 包名常量（来自 design_tokens.json）
///   2) tw_font.g.dart —— Text 的字体链式扩展（fXxx / fBold / withStyle）
class FontsGenerator implements ThemeGenerator {
  final FontDeclarations? declarations;
  FontsGenerator({this.declarations});

  @override
  String get id => 'fonts';

  @override
  void run(Map<String, dynamic> root, Paths paths, Logger log) {
    final catalog = declarations ?? FontDeclarations.load(root, paths, log);
    final fonts = catalog.families;
    final fontsPackage = (root['fontsPackage'] as String?)?.trim();

    if (fonts.isEmpty) {
      log('ℹ️ fonts 为空，跳过 fonts 生成。');
      return;
    }

    String packageLiteralFor(String token, String family) {
      if (fontsPackage == null ||
          fontsPackage.isEmpty ||
          !catalog.isBundled(family, token: token)) {
        return 'null';
      }
      return "'${_escape(fontsPackage)}'";
    }

    // —— 组装 FontFamilies / FontPackages 的字段
    final bufFamilies = StringBuffer();
    final bufPackages = StringBuffer();
    final sortedKeys = fonts.keys.toList()..sort();

    for (final key in sortedKeys) {
      final family = fonts[key]!.trim();
      final safeFamily = family.replaceAll("'", r"\'");
      bufFamilies.writeln("  static const $key = '$safeFamily';");
      bufPackages
          .writeln("  static const $key = ${packageLiteralFor(key, family)};");
    }

    // === 1) 生成 fonts.g.dart ===
    final tplFonts = paths.loadTpl('fonts.dart.tmpl');
    var renderedFonts = renderTemplate(tplFonts, {
      'source': paths.inputPath,
      'families': bufFamilies.toString().trimRight(),
      'packages': bufPackages.toString().trimRight(),
    });

    // Only append the metrics API when a bundled asset is declared.
    if (fonts.keys.any((key) => catalog.assetFor(key) != null)) {
      renderedFonts += _renderMetrics(catalog, log);
    }

    final outFonts = File(paths.joinOut('fonts.g.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync(renderedFonts);
    log('✅ 写入：${outFonts.path}');

    // === 2) 生成 tw_font.g.dart（根据 fonts 的 key 动态生成 f<Key> getters） ===
    _emitTwFontExtensions(fonts, paths, log);
  }

  String _escape(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$');

  String _renderMetrics(FontDeclarations catalog, Logger log) {
    final metrics = StringBuffer();
    final lookups = StringBuffer();
    final parsed = <String, SfntMetrics?>{};
    for (final key in catalog.tokens.keys.toList()..sort()) {
      final asset = catalog.assetFor(key);
      if (asset == null) continue;
      final assetPath = catalog.resolveAsset(asset);
      if (!parsed.containsKey(assetPath)) {
        try {
          final extension = assetPath.toLowerCase().split('.').last;
          if (extension != 'ttf' && extension != 'otf') {
            throw FormatException('Unsupported font format .$extension '
                '(expected .ttf/.otf; .ttc/.woff/.woff2 are unsupported)');
          }
          parsed[assetPath] =
              parseFontMetrics(File(assetPath).readAsBytesSync());
        } catch (error) {
          parsed[assetPath] = null;
          log('⚠️ 跳过字体 $key ($assetPath): $error');
        }
      }
      final value = parsed[assetPath];
      if (value == null) continue;
      metrics.writeln('''  static const $key = FontVerticalMetrics(
    unitsPerEm: ${value.unitsPerEm},
    ascent: ${value.ascent},
    descent: ${value.descent},
    lineGap: ${value.lineGap},
    typoAscender: ${value.typoAscender},
    typoDescender: ${value.typoDescender},
    useTypoMetrics: ${value.useTypoMetrics},
  );''');
      lookups.writeln('''    if (family == FontFamilies.$key &&
        (package == null || package == FontPackages.$key)) {
      return $key;
    }''');
    }
    return renderTemplate(fontMetricsTemplate, {
      'metrics': metrics.toString().trimRight(),
      'lookups': lookups.toString().trimRight(),
    });
  }

  /// 根据 JSON fonts 的键生成 fXxx 链式
  void _emitTwFontExtensions(
    Map<String, String> fonts,
    Paths paths,
    Logger log,
  ) {
    if (fonts.isEmpty) {
      log('ℹ️ fonts 为空，跳过 tw_font。');
      return;
    }

    String _safeCap(String key) {
      final cleaned = key.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      if (cleaned.isEmpty) return 'Font';
      return '${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
    }

    final buf = StringBuffer();
    final keys = fonts.keys.toList()..sort();
    for (final k in keys) {
      final cap = _safeCap(k);
      buf.writeln('  /// 字体（来自 JSON: fonts.$k）');
      buf.writeln(
          '  Text get f$cap => _twCopyWith(fontFamily: FontFamilies.$k, package: FontPackages.$k);');
      buf.writeln();
    }
    final tpl = paths.loadTpl('tw_font.dart.tmpl');
    final rendered = renderTemplate(tpl, {
      'source': paths.inputPath,
      'fontGetters': buf.toString().trimRight(),
    });

    final outTw = File(paths.joinOut('tw_font.g.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync(rendered);
    log('✅ 写入：${outTw.path}');
  }
}
