import 'dart:typed_data';

/// Header metrics of an sfnt font at its default variation coordinates.
/// Descent is a positive distance; typoDescender keeps the signed OS/2 value.
class SfntMetrics {
  final int unitsPerEm;
  final int ascent;
  final int descent;
  final int lineGap;
  final int typoAscender;
  final int typoDescender;
  final int typoLineGap;
  final int? winAscent;
  final int? winDescent;
  final bool useTypoMetrics;

  const SfntMetrics({
    required this.unitsPerEm,
    required this.ascent,
    required this.descent,
    required this.lineGap,
    required this.typoAscender,
    required this.typoDescender,
    required this.typoLineGap,
    required this.winAscent,
    required this.winDescent,
    required this.useTypoMetrics,
  });

  double get opticalCenterOffset => typoAscender - typoDescender <= 0
      ? 0.0
      : ((ascent - descent) / 2 - (typoAscender + typoDescender) / 2) /
          unitsPerEm;
}

/// Reads only the sfnt directory and head/hhea/OS/2 headers. No glyph parsing,
/// dependency on Flutter, or variation adjustments (the default instance).
/// Missing OS/2 means unavailable typo metrics, represented by zeroes.
/// Invalid/unsupported data always throws [FormatException].
SfntMetrics parseFontMetrics(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  void requireRange(int offset, int length, String label) {
    if (offset < 0 || length < 0 || offset > bytes.length - length) {
      throw FormatException('Truncated $label');
    }
  }

  requireRange(0, 4, 'sfnt signature');
  final signature = data.getUint32(0);
  if (signature == 0x74746366) {
    throw const FormatException('Unsupported TTC collection (.ttc)');
  }
  if (signature == 0x774f4646 || signature == 0x774f4632) {
    throw const FormatException('Unsupported WOFF/WOFF2 font');
  }
  if (signature != 0x00010000 && signature != 0x4f54544f) {
    throw const FormatException('Not a TrueType/OpenType sfnt font');
  }
  requireRange(0, 12, 'sfnt header');
  final count = data.getUint16(4);
  requireRange(12, count * 16, 'sfnt table directory');
  final tables = <String, ByteData>{};
  for (var i = 0; i < count; i++) {
    final entry = 12 + i * 16;
    final tag = String.fromCharCodes(bytes.sublist(entry, entry + 4));
    final offset = data.getUint32(entry + 8);
    final length = data.getUint32(entry + 12);
    requireRange(offset, length, '$tag table');
    if (tables.containsKey(tag)) {
      throw FormatException('Duplicate $tag table');
    }
    tables[tag] = ByteData.sublistView(bytes, offset, offset + length);
  }

  ByteData table(String tag, int minLength) {
    final value = tables[tag];
    if (value == null) throw FormatException('Missing $tag table');
    if (value.lengthInBytes < minLength) {
      throw FormatException('Truncated $tag metrics header');
    }
    return value;
  }

  final head = table('head', 20);
  final hhea = table('hhea', 10);
  final unitsPerEm = head.getUint16(18);
  if (unitsPerEm < 16 || unitsPerEm > 16384) {
    throw FormatException('Invalid head.unitsPerEm: $unitsPerEm');
  }
  final ascent = hhea.getInt16(4);
  final signedDescent = hhea.getInt16(6);
  if (ascent <= 0 || signedDescent > 0) {
    throw const FormatException('Invalid hhea ascender/descender');
  }
  final os2 = tables.containsKey('OS/2') ? table('OS/2', 78) : null;
  return SfntMetrics(
    unitsPerEm: unitsPerEm,
    ascent: ascent,
    descent: -signedDescent,
    lineGap: hhea.getInt16(8),
    typoAscender: os2?.getInt16(68) ?? 0,
    typoDescender: os2?.getInt16(70) ?? 0,
    typoLineGap: os2?.getInt16(72) ?? 0,
    winAscent: os2?.getUint16(74),
    winDescent: os2?.getUint16(76),
    useTypoMetrics: os2 != null && (os2.getUint16(62) & (1 << 7)) != 0,
  );
}
