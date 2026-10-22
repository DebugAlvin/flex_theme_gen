import 'dart:io';

import 'package:path/path.dart' as p;

/// 读取模板文件
String loadTemplate(String absoluteTemplatesDir, String name) {
  final full = p.normalize(p.join(absoluteTemplatesDir, name));
  final f = File(full);
  if (!f.existsSync()) {
    throw StateError('模板不存在：$full');
  }
  return f.readAsStringSync();
}

/// 渲染模板（支持 {{var}}、{{#each key}}、{{#if key}}）
String renderTemplate(String tpl, Map<String, dynamic> ctx) {
  String out = tpl;

  // ---------- 1️⃣ 处理 each 块 ----------
  final eachReg = RegExp(r'{{#each (\w+)}}([\s\S]*?){{\/each}}');
  out = out.replaceAllMapped(eachReg, (m) {
    final key = m.group(1)!;
    final body = m.group(2)!;
    final list = ctx[key];
    if (list is List) {
      return list.map((item) {
        var seg = body;
        if (item is Map) {
          item.forEach((k, v) {
            seg = seg.replaceAll('{{${k}}}', v.toString());
          });
        }
        ctx.forEach((k, v) {
          seg = seg.replaceAll('{{${k}}}', v.toString());
        });
        return seg;
      }).join('');
    }
    return '';
  });

  // ---------- 2️⃣ 处理 if / else 块 ----------
  final ifReg = RegExp(r'{{#if (\w+)}}([\s\S]*?)({{else}}([\s\S]*?))?{{\/if}}');
  out = out.replaceAllMapped(ifReg, (m) {
    final key = m.group(1)!;
    final trueBlock = m.group(2)!;
    final falseBlock = m.group(4) ?? '';
    final val = ctx[key];
    final cond = val == true || val == 'true';
    return cond ? trueBlock : falseBlock;
  });

  // ---------- 3️⃣ 简单变量替换 ----------
  ctx.forEach((k, v) {
    if (k == 'source' && v is String) {
      // Support both built-in and existing custom templates. Keep headers
      // relative to the generation working directory, even for absolute input.
      final source = p.relative(v).replaceAll(p.separator, '/');
      out = out.replaceAll(RegExp(r'{{\s*source\s*}}'), source);
    } else {
      out = out.replaceAll('{{$k}}', v.toString());
    }
  });

  return out;
}

/// 缩进多行文本
String indent(String text, int spaces) {
  final pad = ' ' * spaces;
  return text.split('\n').map((l) => l.isEmpty ? l : '$pad$l').join('\n');
}
