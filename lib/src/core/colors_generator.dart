import 'dart:io';
import '../utils/template_utils.dart';
import '../utils/color_utils.dart';
import 'base.dart';

typedef Logger = void Function(String message);

class ColorsGenerator implements ThemeGenerator {
  @override
  String get id => 'colors';

  @override
  void run(Map<String, dynamic> root, Paths paths, Logger log) {
    final colors = root['colors'];
    if (colors == null) {
      throw StateError('design_tokens 缺少 "colors" 节点');
    }

    final colorsMap = _normalizeMap(colors);
    final light = _readPalette(colorsMap, 'light');
    final dark = _readPalette(colorsMap, 'dark');

    final keys = <String>{}..addAll(light.keys)..addAll(dark.keys);
    final sorted = keys.toList()..sort();

    final fields = StringBuffer();
    final ctor = StringBuffer();
    final initL = StringBuffer();
    final initD = StringBuffer();

    for (final k in sorted) {
      final t = _inferType(light[k] ?? dark[k]);
      final safe = _safeName(k);
      fields.writeln('  final ${t.dartType} $safe;');
      ctor.writeln('    required this.$safe,');
      initL.writeln('      $safe: ${_emitValueExpr(t, light[k], k)},');
      initD.writeln('      $safe: ${_emitValueExpr(t, dark[k], k)},');
    }

    final tpl = paths.loadTpl('app_colors.dart.tmpl');;
    final rendered = renderTemplate(tpl, {
      'source': paths.inputPath,
      'generatedAt': DateTime.now().toIso8601String(),
      'fields': fields.toString().trimRight(),
      'ctorParams': ctor.toString().trimRight(),
      'lightInits': initL.toString().trimRight(),
      'darkInits': initD.toString().trimRight(),
    });

    File(paths.joinOut('app_colors.g.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync(rendered);
    log('✅ 写入：${paths.joinOut('app_colors.g.dart')}');
  }
}

enum _FieldType { color, linearGradient }

extension on _FieldType {
  String get dartType => this == _FieldType.color ? 'Color' : 'LinearGradient';
}

// ----------------------------------------------------------------------
// 🧠 YAML / JSON Normalize Helpers
// ----------------------------------------------------------------------

Map<String, dynamic> _normalizeMap(dynamic v) {
  if (v == null) return {};
  if (v is Map<String, dynamic>) return v;
  if (v is Map) {
    return v.map((k, v) => MapEntry(k.toString(), _normalizeValue(v)));
  }
  throw StateError('期望 Map，但得到: $v');
}

dynamic _normalizeValue(dynamic v) {
  if (v is Map) return _normalizeMap(v);
  if (v is Iterable) return v.map(_normalizeValue).toList();
  return v;
}

// ----------------------------------------------------------------------
// 🌈 Palette & Type Detection
// ----------------------------------------------------------------------

Map<String, dynamic> _readPalette(Map root, String key) {
  final v = root[key];
  if (v == null) throw StateError('"colors.$key" 缺失');
  return _normalizeMap(v);
}

_FieldType _inferType(dynamic v) {
  // 允许数字型颜色（YAML 会自动转成 int）
  if (v is String || v is num) return _FieldType.color;

  if (v is Map) {
    final map = _normalizeMap(v);
    final type = (map['type'] ?? '').toString().toLowerCase();
    if (type == 'linear') return _FieldType.linearGradient;
  }

  throw StateError('无法推断字段类型: $v');
}

// ----------------------------------------------------------------------
// 🎨 Emit Value Expression
// ----------------------------------------------------------------------


String _emitValueExpr(_FieldType t, dynamic v, String key) {
  switch (t) {
    case _FieldType.color:
      final colorValue = v.toString(); // ✅ 统一转字符串
      if (colorValue.trim().isEmpty) throw StateError('$key 颜色值为空');
      return 'Color(${toDartHex(colorValue)})';

    case _FieldType.linearGradient:
      final map = _normalizeMap(v);
      final colors = (map['colors'] as List?)?.cast<String>() ?? const <String>[];
      final begin = map['begin'] as String?;
      final end = map['end'] as String?;
      final stops = (map['stops'] as List?)?.cast<num>();
      return emitLinearGradientExpr(
        colors: colors,
        begin: begin,
        end: end,
        stops: stops,
      );
  }
}

// ----------------------------------------------------------------------
// 🧩 Safe Variable Name
// ----------------------------------------------------------------------

String _safeName(String raw) {
  final r = raw.trim();
  if (r.isEmpty) return '_';
  final buf = StringBuffer();
  final first = r[0];
  if (_isLetter(first) || first == '_') buf.write(first);
  else buf.write('_');
  for (int i = 1; i < r.length; i++) {
    final ch = r[i];
    if (_isLetter(ch) || _isDigit(ch) || ch == '_') buf.write(ch);
    else buf.write('_');
  }
  return buf.toString();
}

bool _isLetter(String ch) {
  final c = ch.codeUnitAt(0);
  return (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
}

bool _isDigit(String ch) {
  final c = ch.codeUnitAt(0);
  return c >= 48 && c <= 57;
}