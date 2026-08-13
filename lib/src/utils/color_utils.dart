import 'dart:core';

String toDartHex(String input) {
  var s = input.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.startsWith('0x')) s = s.substring(2);
  if (s.length == 6) return '0xFF${s.toUpperCase()}';
  if (s.length == 8) return '0x${s.toUpperCase()}';
  throw StateError('非法 hex：$input（支持 #RRGGBB 或 #AARRGGBB）');
}

String toAlignment(String name) {
  const map = {
    'topleft': 'Alignment.topLeft',
    'topcenter': 'Alignment.topCenter',
    'topright': 'Alignment.topRight',
    'centerleft': 'Alignment.centerLeft',
    'center': 'Alignment.center',
    'centerright': 'Alignment.centerRight',
    'bottomleft': 'Alignment.bottomLeft',
    'bottomcenter': 'Alignment.bottomCenter',
    'bottomright': 'Alignment.bottomRight',
  };
  final key = name.replaceAll('_', '').replaceAll(' ', '').toLowerCase();
  final v = map[key];
  if (v == null) throw StateError('不支持的 Alignment: $name');
  return v;
}

String emitLinearGradientExpr({
  required List<String> colors,
  String? begin,
  String? end,
  List<num>? stops,
}) {
  if (colors.isEmpty) {
    throw StateError('渐变需要至少一个颜色');
  }
  final colorsExpr = colors.map((c) => 'Color(${toDartHex(c)})').join(', ');
  final beginStr = begin != null ? toAlignment(begin) : 'Alignment.topCenter';
  final endStr = end != null ? toAlignment(end) : 'Alignment.bottomCenter';
  final stopsExpr = (stops == null || stops.isEmpty)
      ? ''
      : '\n        stops: [${stops.map((e) => e.toString()).join(', ')}],';

  return '''
LinearGradient(
        colors: [$colorsExpr],
        begin: $beginStr,
        end: $endStr,$stopsExpr
      )''';
}