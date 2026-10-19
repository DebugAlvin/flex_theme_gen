import 'dart:io';

import '../utils/template_utils.dart';
import 'base.dart';

/// 生成：
///  - tokens.g.dart   （Spacing / Radius / Shadow / Misc / Border 常量）
///  - {prefix}_alias.g.dart （Tailwind 链式：Padding / Radius / 背景 / 边框 + Token 变体）
///
/// 边框（legacy 写法示例）:
/// tokens:
///   prefix: tw                     # ✅ 可选,链式调用方法名前缀
///   border:
///     default:
///       color: "FF33A9FF"          # 可选：纯 hex
///       colorToken: "colorFF33A9FF" # ✅ 可选：支持 AppColors token（支持明暗）
///       width: 1.5                 # 可选：默认宽度
///     2: 2
///     4: 4
///     6: 6
///     8: 8

class TokensGenerator implements ThemeGenerator {
  @override
  String get id => 'tokens';

  @override
  void run(Map<String, dynamic> root, Paths paths, Logger log) {
    final tokens =
        ((root['tokens'] as Map?) ?? const {}).cast<String, dynamic>();
    if (tokens.isEmpty) {
      log('ℹ️ tokens 为空，跳过。');
      return;
    }

    // ============================================================
    // 读取 prefix（仅影响链式扩展）
    // ============================================================
    final prefix = (tokens['prefix'] as String?)?.trim() ?? 'tw';
    final aliasFileName = '${prefix}_alias.g.dart';

    // ============================================================
    // 1) 收集 tokens
    // ============================================================
    final spacing = _parseNumMap(tokens['spacing']);
    final radius = _parseNumMap(tokens['radius']);
    final shadow = _parseNumMap(tokens['shadow']);
    final misc = _parseNumMap(tokens['misc']);
    final border =
        (tokens['border'] as Map?)?.cast<String, dynamic>() ?? const {};

    // ============================================================
    // 2) Border 默认配置
    // ============================================================
    final def =
        (border['default'] as Map?)?.cast<String, dynamic>() ?? const {};
    final borderColorToken = (def['colorToken'] as String?)?.trim();
    final borderColorHex = (def['color'] as String?)?.trim();
    final borderDefaultWidth = _tryNum(def['width']) ?? 1.0;

    // 解析 border 数值节点
    final borderWidths = <String, double>{};
    for (final e in border.entries) {
      if (e.key == 'default') continue;
      final v = _tryNum(e.value);
      if (v != null) borderWidths[e.key] = v;
    }

    // ============================================================
    // 3) 渲染 tokens.g.dart
    // ============================================================
    final tplTokens = paths.loadTpl('tokens.dart.tmpl');
    final renderedTokens = renderTemplate(tplTokens, {
      'source': paths.inputPath,
      'prefix': prefix,
      'spacingTokens': _renderConst('spacing', spacing),
      'radiusTokens': _renderConst('radius', radius),
      'shadowTokens': _renderConst('shadow', shadow),
      'miscTokens': _renderConst('misc', misc),
      'borderTokens': _renderConst('border', borderWidths),
      'borderDefaultWidth': borderDefaultWidth.toString(),
      'borderDefaultColor': borderColorHex != null
          ? _toDartIntHexExpr(borderColorHex)
          : '0xFFCCCCCC',
      'borderDefaultColorToken': borderColorToken ?? '',
    });

    final outTokens = File(paths.joinOut('tokens.g.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync(renderedTokens);
    log('✅ 写入：${outTokens.path}');

    // ============================================================
    // 4) 渲染 {prefix}_alias.g.dart
    // ============================================================
    final hasToken = borderColorToken != null && borderColorToken.isNotEmpty;
    final resolvedBorderColorExpr = hasToken
        ? 'colors.${_safe(borderColorToken)}'
        : 'const Color(${_toDartIntHexExpr(borderColorHex) ?? '0xFFCCCCCC'})';

    final tplAlias = paths.loadTpl('tw_alias.dart.tmpl');
    final renderedAlias = renderTemplate(tplAlias, {
      'source': paths.inputPath,
      'prefix': prefix,
      'resolvedBorderColorExpr': resolvedBorderColorExpr,
      'spacing': spacing.keys.map((k) => {'keyCap': _cap(k)}).toList(),
      'radius': radius.keys.map((k) => {'keyCap': _cap(k)}).toList(),
      'border': borderWidths.keys.map((k) => {'keyCap': _cap(k)}).toList(),
    });

    final outAlias = File(paths.joinOut(aliasFileName))
      ..createSync(recursive: true)
      ..writeAsStringSync(renderedAlias);
    log('✅ 写入：${outAlias.path}');
  }

  // ============================================================
  // Helpers
  // ============================================================

  Map<String, double> _parseNumMap(dynamic src) {
    if (src is Map) {
      return src.map((k, v) {
        final numVal = _tryNum(v);
        if (numVal == null) throw StateError('期望数值，实际：$v');
        return MapEntry(k.toString(), numVal);
      });
    }
    return {};
  }

  double? _tryNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String _renderConst(String name, Map<String, double> data) {
    if (data.isEmpty) return '';
    final buf = StringBuffer();
    for (final e in data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      final key = _cap(e.key);
      buf.writeln('  static const $name$key = ${e.value};');
    }
    return buf.toString().trimRight();
  }

  String _cap(String s) =>
      s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1)}';

  String _safe(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

  String? _toDartIntHexExpr(String? color) {
    if (color == null || color.trim().isEmpty) return null;
    var s = color.trim().toUpperCase();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) throw StateError('颜色 hex 长度错误: $color');
    return '0x$s';
  }
}
