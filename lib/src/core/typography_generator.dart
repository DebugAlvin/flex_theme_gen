import 'dart:io';
import 'base.dart';
import '../utils/template_utils.dart';
import '../utils/color_utils.dart';

class TypographyGenerator implements ThemeGenerator {
  @override
  String get id => 'typography';

  @override
  void run(Map<String, dynamic> root, Paths paths, Logger log) {
    final typo =
        ((root['typography'] as Map?) ?? const {}).cast<String, dynamic>();
    if (typo.isEmpty) {
      log('ℹ️ typography 为空，跳过。');
      return;
    }

    // 根级 fonts token 映射 & 外部包名（可为空）
    final fonts = ((root['fonts'] as Map?) ?? const {}).cast<String, String>();
    final rootFontsPackage = (root['fontsPackage'] as String?)?.trim();
    final hasRootExternal =
        rootFontsPackage != null && rootFontsPackage.isNotEmpty;

    final styleStatics = StringBuffer();
    final resolvedMethods = StringBuffer();

    for (final groupKey in typo.keys.toList()..sort()) {
      final groupNode = (typo[groupKey] as Map).cast<String, dynamic>();
      final sizes = (groupNode['sizes'] as Map?);

      if (sizes != null) {
        // ---------------- 分组模式 ----------------
        final groupFontToken = groupNode['fontFamilyToken'] as String?;
        final groupFontFamily = groupNode['fontFamily'] as String?;
        final groupFontsPkg = (groupNode['fontsPackage'] as String?)?.trim();
        final usedFontsPackage = (groupFontsPkg?.isNotEmpty == true)
            ? groupFontsPkg
            : (hasRootExternal ? rootFontsPackage : null);

        final defaults = ((groupNode['defaults'] as Map?) ?? const {})
            .cast<String, dynamic>();
        final sizeKeys = sizes.keys.map((e) => e.toString()).toList()..sort();

        for (final sizeKey in sizeKeys) {
          final rawNode = (sizes[sizeKey] as Map).cast<String, dynamic>();
          final m = <String, dynamic>{...defaults, ...rawNode};
          final outKey = _safe('${groupKey}_$sizeKey');

          // 1️⃣ 数值读取
          final fontSizeNum = _parseNum(
            m['fontSize'],
            'typography.$groupKey.$sizeKey.fontSize',
          );
          final fontSize = _fmt(fontSizeNum);

          final heightRatio = _heightRatio(
            size: fontSizeNum,
            lineHeight: m['lineHeight'],
            height: m['height'],
            pathBase: 'typography.$groupKey.$sizeKey',
          );

          final letter = _asDouble(
            m['letterSpacing'],
            path: 'typography.$groupKey.$sizeKey.letterSpacing',
            fallback: 0.0,
          );
          final weight = _weightExpr(
            m['fontWeight'],
            path: 'typography.$groupKey.$sizeKey.fontWeight',
            fallback: 'w400',
          );

          // 2️⃣ family 解析
          bool fromToken = false;
          final resolvedFamily = _resolveFontFamily(
            fonts,
            m['fontFamilyToken'] as String? ?? groupFontToken,
            m['fontFamily'] as String? ?? groupFontFamily,
            () => fromToken = true,
          );
          final famLiteral =
              resolvedFamily != null ? "'${_esc(resolvedFamily)}'" : null;

          // 3️⃣ color / colorToken
          final hexColor = (m['color'] as String?);
          final colorToken = (m['colorToken'] as String?);

          // 4️⃣ TextStyle 拼装
          final fields = <String>[
            'fontSize: $fontSize',
            'fontWeight: $weight',
            'height: ${_fmt(heightRatio)}',
            'letterSpacing: $letter',
          ];
          if (famLiteral != null) fields.add('fontFamily: $famLiteral');

          if (fromToken &&
              usedFontsPackage != null &&
              usedFontsPackage.isNotEmpty &&
              !_isSystemFont(resolvedFamily ?? '')) {
            fields.add("package: '$usedFontsPackage'");
          }

          if (hexColor != null && hexColor.trim().isNotEmpty) {
            fields.add('color: Color(${toDartHex(hexColor)})');
          }

          styleStatics.writeln(
            '  static const TextStyle $outKey = TextStyle(${fields.join(', ')});',
          );

          if (colorToken != null && colorToken.trim().isNotEmpty) {
            final tokenField = _safe(colorToken);
            resolvedMethods.writeln(
              '  static TextStyle $outKey(AppColors c) => TextStyles.$outKey.copyWith(color: c.$tokenField);',
            );
          } else {
            resolvedMethods.writeln(
              '  static TextStyle $outKey(AppColors c) => TextStyles.$outKey;',
            );
          }
        }
      } else {
        // ---------------- 扁平模式（向后兼容） ----------------
        final safe = _safe(groupKey);

        final sizeNum = _parseNum(
          groupNode['size'],
          'typography.$groupKey.size',
        );
        final size = _fmt(sizeNum);

        final weight = _weightExpr(
          groupNode['weight'],
          path: 'typography.$groupKey.weight',
          fallback: 'w400',
        );

        final height = _asDouble(
          groupNode['height'],
          path: 'typography.$groupKey.height',
          fallback: 1.0,
        );

        final letter = _asDouble(
          groupNode['letterSpacing'],
          path: 'typography.$groupKey.letterSpacing',
          fallback: 0.0,
        );

        bool fromToken = false;
        final resolvedFamily = _resolveFontFamily(
          fonts,
          groupNode['fontFamilyToken'] as String?,
          groupNode['fontFamily'] as String?,
          () => fromToken = true,
        );
        final famLiteral =
            resolvedFamily != null ? "'${_esc(resolvedFamily)}'" : null;

        final hexColor = (groupNode['color'] as String?);
        final colorToken = (groupNode['colorToken'] as String?);

        final fields = <String>[
          'fontSize: $size',
          'fontWeight: $weight',
          'height: $height',
          'letterSpacing: $letter',
        ];
        if (famLiteral != null) fields.add('fontFamily: $famLiteral');

        if (fromToken &&
            (rootFontsPackage?.isNotEmpty == true) &&
            !_isSystemFont(resolvedFamily ?? '')) {
          fields.add("package: '$rootFontsPackage'");
        }

        if (hexColor != null && hexColor.trim().isNotEmpty) {
          fields.add('color: Color(${toDartHex(hexColor)})');
        }

        styleStatics.writeln(
          '  static const TextStyle $safe = TextStyle(${fields.join(', ')});',
        );

        if (colorToken != null && colorToken.trim().isNotEmpty) {
          final tokenField = _safe(colorToken);
          resolvedMethods.writeln(
            '  static TextStyle $safe(AppColors c) => TextStyles.$safe.copyWith(color: c.$tokenField);',
          );
        } else {
          resolvedMethods.writeln(
            '  static TextStyle $safe(AppColors c) => TextStyles.$safe;',
          );
        }
      }
    }

    // 输出 typography.g.dart
    final tpl = paths.loadTpl('typography.dart.tmpl');
    final rendered = renderTemplate(tpl, {
      'source': paths.inputPath,
      'generatedAt': DateTime.now().toIso8601String(),
      'styleStatics': styleStatics.toString().trimRight(),
    });
    File(paths.joinOut('typography.g.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync(rendered);
    log('✅ 写入：${paths.joinOut('typography.g.dart')}');

    // 输出 typography_resolved.g.dart
    final tplR = paths.loadTpl('typography_resolved.dart.tmpl');
    final renderedR = renderTemplate(tplR, {
      'source': paths.inputPath,
      'generatedAt': DateTime.now().toIso8601String(),
      'resolvedMethods': resolvedMethods.toString().trimRight(),
    });
    File(paths.joinOut('typography_resolved.g.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync(renderedR);
    log('✅ 写入：${paths.joinOut('typography_resolved.g.dart')}');
  }

  // ---------------- 工具函数 ----------------

  String? _resolveFontFamily(
    Map<String, String> fonts,
    String? token,
    String? family,
    void Function() markToken,
  ) {
    if (token != null &&
        token.trim().isNotEmpty &&
        fonts.containsKey(token.trim())) {
      markToken();
      return fonts[token.trim()];
    }
    if (family != null && family.trim().isNotEmpty) {
      return family.trim();
    }
    return null;
  }

  String _safe(String s) => s
      .replaceAll('-', '_')
      .replaceAll(' ', '_')
      .replaceAll('/', '_')
      .replaceAll('.', '_');

  String _esc(String s) => s.replaceAll("'", r"\'");

  String _fmt(num v) {
    final s = v.toString();
    if (!s.contains('.')) return s;
    return v
        .toStringAsFixed(6)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _asDouble(dynamic v, {required String path, double? fallback}) {
    if (v == null) {
      if (fallback != null) return _fmt(fallback);
      throw StateError('[$path] 期望数值，实际：null');
    }
    if (v is num) return _fmt(v.toDouble());
    if (v is String) {
      final t = v.trim();
      if (t.isEmpty && fallback != null) return _fmt(fallback);
      final parsed = double.tryParse(t);
      if (parsed != null) return _fmt(parsed);
    }
    if (fallback != null) return _fmt(fallback);
    throw StateError('[$path] 期望数值，实际：$v');
  }

  double _parseNum(dynamic v, String path) {
    if (v == null) throw StateError('[$path] 期望数值，实际：null');
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v.trim());
      if (parsed != null) return parsed;
    }
    throw StateError('[$path] 期望数值，实际：${v.runtimeType} ($v)');
  }

  double _heightRatio({
    required double size,
    required dynamic lineHeight,
    required dynamic height,
    required String pathBase,
  }) {
    if (height != null) {
      final h = _parseNum(height, '$pathBase.height');
      if (h > 0) return h;
    }
    if (lineHeight != null) {
      final lh = _parseNum(lineHeight, '$pathBase.lineHeight');
      return lh <= 0 ? 1.0 : (lh / size);
    }
    return 1.0;
  }

  String _weightExpr(
    dynamic v, {
    required String path,
    String fallback = 'w400',
  }) {
    if (v == null) return 'FontWeight.$fallback';
    if (v is String) {
      final t = v.trim().toLowerCase();
      final s = t.startsWith('w') ? t : 'w$t';
      if (_allowed.contains(s)) return 'FontWeight.$s';
    }
    if (v is num) {
      final s = 'w${v.toInt()}';
      if (_allowed.contains(s)) return 'FontWeight.$s';
    }
    throw StateError('[$path] 不支持的字重：$v（期望 w100~w900 或 100/400/700）');
  }

  static const _allowed = {
    'w100',
    'w200',
    'w300',
    'w400',
    'w500',
    'w600',
    'w700',
    'w800',
    'w900',
  };

  // ✅ 系统字体判断（这些字体不需要 package）
  bool _isSystemFont(String family) {
    const systemFonts = {
      'Roboto',
      'SF Pro Text',
      'SF Pro Display',
      'Noto Sans',
      'Noto Sans SC',
      'Segoe UI',
      'Helvetica',
      'Arial',
    };
    return systemFonts.contains(family);
  }
}
