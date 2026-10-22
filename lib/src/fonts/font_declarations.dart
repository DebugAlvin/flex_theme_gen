import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/base.dart';
import '../utils/yaml_util.dart';

class FontToken {
  final String family;
  final String? asset;
  final bool system;

  const FontToken(this.family, {this.asset, this.system = false});
}

/// One declaration-based policy shared by font constants and typography.
class FontDeclarations {
  final Map<String, FontToken> tokens;
  final Map<String, String> assets;
  final String packageRoot;

  FontDeclarations._(this.tokens, this.assets, this.packageRoot);

  factory FontDeclarations.load(
      Map<String, dynamic> root, Paths paths, Logger log) {
    // The generated output belongs to the nearest enclosing Flutter package.
    var directory = Directory(p.absolute(paths.outDir));
    File? pubspec;
    while (true) {
      final candidate = File(p.join(directory.path, 'pubspec.yaml'));
      if (candidate.existsSync()) {
        pubspec = candidate;
        break;
      }
      final parent = directory.parent;
      if (parent.path == directory.path) break;
      directory = parent;
    }
    pubspec ??= File(p.join(Directory.current.path, 'pubspec.yaml'));
    final packageRoot = pubspec.parent.path;
    final assets = <String, String>{};
    if (pubspec.existsSync()) {
      try {
        final config = YamlUtil.load(pubspec.path);
        final flutter = config['flutter'];
        final families = flutter is Map ? flutter['fonts'] : null;
        if (families is List) {
          for (final entry in families) {
            if (entry is! Map || entry['family'] is! String) continue;
            final files = entry['fonts'];
            if (files is! List) continue;
            final candidates = files
                .whereType<Map>()
                .where((file) =>
                    file['asset'] is String &&
                    (file['asset'] as String).trim().isNotEmpty)
                .toList();
            if (candidates.isEmpty) continue;
            final regular = candidates.where((file) =>
                (file['weight'] ?? 400) == 400 &&
                (file['style'] ?? 'normal') == 'normal');
            final selected =
                regular.isNotEmpty ? regular.first : candidates.first;
            assets.putIfAbsent((entry['family'] as String).trim(),
                () => (selected['asset'] as String).trim());
          }
        }
      } catch (error) {
        log('⚠️ 无法读取字体声明 ${pubspec.path}: $error');
      }
    }
    final tokens = <String, FontToken>{};
    final rawFonts = (root['fonts'] as Map?) ?? const {};
    for (final key in rawFonts.keys.cast<String>().toList()..sort()) {
      final value = rawFonts[key];
      if (value is String) {
        tokens[key] = FontToken(value.trim());
      } else if (value is Map && value['family'] is String) {
        final asset = (value['asset'] as String?)?.trim();
        tokens[key] = FontToken((value['family'] as String).trim(),
            asset: asset?.isNotEmpty == true ? asset : null,
            system: value['system'] == true);
      } else {
        throw FormatException('fonts.$key must be a family string or '
            '{family: ..., asset: ..., system: ...}');
      }
    }
    return FontDeclarations._(tokens, assets, packageRoot);
  }

  Map<String, String> get families =>
      tokens.map((key, token) => MapEntry(key, token.family));

  /// An explicit system override applies to that token. Literal families can
  /// also use an explicit asset declared by another token of the same family.
  bool isBundled(String family, {String? token}) {
    final declaration = tokens[token];
    if (declaration != null && declaration.family == family) {
      return !declaration.system &&
          (declaration.asset != null || _familyAsset(family) != null);
    }
    return _familyAsset(family) != null;
  }

  String? assetFor(String token) {
    final declaration = tokens[token]!;
    if (!isBundled(declaration.family, token: token)) return null;
    return declaration.asset ?? _familyAsset(declaration.family);
  }

  String? _familyAsset(String family) {
    if (assets.containsKey(family)) return assets[family];
    for (final declaration in tokens.values) {
      if (declaration.family == family &&
          !declaration.system &&
          declaration.asset != null) {
        return declaration.asset;
      }
    }
    return null;
  }

  String resolveAsset(String asset) => p.normalize(p.join(packageRoot, asset));
}
