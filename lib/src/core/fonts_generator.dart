import 'dart:io';

import 'base.dart';
import '../utils/template_utils.dart';

/// FontsGenerator
/// 动态生成：
///   1) fonts.g.dart   —— 字体家族 & 包名常量（来自 design_tokens.json）
///   2) tw_font.g.dart —— Text 的字体链式扩展（fXxx / fBold / withStyle）
class FontsGenerator implements ThemeGenerator {
  @override
  String get id => 'fonts';

  @override
  void run(Map<String, dynamic> root, Paths paths, Logger log) {
    final fonts = ((root['fonts'] as Map?) ?? const {}).cast<String, String>();
    final fontsPackage = (root['fontsPackage'] as String?)?.trim();

    if (fonts.isEmpty) {
      log('ℹ️ fonts 为空，跳过 fonts 生成。');
      return;
    }

    // —— 判断是否系统/内置字体（无需 package）
    bool isSystem(String family) {
      const systemFonts = {
        'Roboto',
        'Noto Sans',
        'Noto Sans SC',
        'SF Pro Text',
        'SF Pro Display',
        'Helvetica',
        'Arial',
        'Segoe UI',
      };
      return systemFonts.contains(family);
    }

    String packageLiteralFor(String family) {
      if (fontsPackage == null || fontsPackage.isEmpty) return 'null';
      if (isSystem(family)) return 'null';
      return "'$fontsPackage'";
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
          .writeln("  static const $key = ${packageLiteralFor(family)};");
    }

    // === 1) 生成 fonts.g.dart ===
    final tplFonts = paths.loadTpl('fonts.dart.tmpl');
    final renderedFonts = renderTemplate(tplFonts, {
      'source': paths.inputPath,
      'families': bufFamilies.toString().trimRight(),
      'packages': bufPackages.toString().trimRight(),
    });

    final outFonts = File(paths.joinOut('fonts.g.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync(renderedFonts);
    log('✅ 写入：${outFonts.path}');

    // === 2) 生成 tw_font.g.dart（根据 fonts 的 key 动态生成 f<Key> getters） ===
    _emitTwFontExtensions(fonts, paths, log);
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
