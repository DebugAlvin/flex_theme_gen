// Kept in Dart so existing custom template directories remain compatible.
const fontMetricsTemplate = r'''


/// Vertical font header metrics in font units (default variable-font instance).
class FontVerticalMetrics {
  final int unitsPerEm;
  final int ascent;
  /// Positive hhea descent distance below the baseline.
  final int descent;
  final int lineGap;
  final int typoAscender;
  /// Signed OS/2 typo descender, usually negative; zero if OS/2 is absent.
  final int typoDescender;
  final bool useTypoMetrics;

  const FontVerticalMetrics({
    required this.unitsPerEm,
    required this.ascent,
    required this.descent,
    required this.lineGap,
    required this.typoAscender,
    required this.typoDescender,
    required this.useTypoMetrics,
  });

  /// Visual correction factor k. Consumers may translate by -k * fontSize.
  /// Returns zero when no valid OS/2 typo box is available.
  double get opticalCenterOffset => typoAscender - typoDescender <= 0
      ? 0.0
      : ((ascent - descent) / 2 - (typoAscender + typoDescender) / 2) /
          unitsPerEm;
}

/// Metrics for declared, successfully parsed font assets only.
class FontMetrics {
{{metrics}}

  /// Looks up a FontFamilies or TextStyle.fontFamily value.
  /// An optional package must match, including any packages/ prefix.
  static FontVerticalMetrics? of(String? family, {String? package}) {
    if (family == null) {
      return null;
    }
    if (family.startsWith('packages/')) {
      final separator = family.indexOf('/', 9);
      if (separator <= 9 || separator == family.length - 1) {
        return null;
      }
      final prefixedPackage = family.substring(9, separator);
      if (package != null && package != prefixedPackage) {
        return null;
      }
      package = prefixedPackage;
      family = family.substring(separator + 1);
    }
{{lookups}}
    return null;
  }
}
''';
