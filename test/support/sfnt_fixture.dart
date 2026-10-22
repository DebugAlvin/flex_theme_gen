import 'dart:typed_data';

/// Tiny synthetic sfnt: table headers only, deliberately unsorted directory.
Uint8List sfntFixture({
  bool otf = false,
  bool useTypoMetrics = false,
  bool includeOs2 = true,
  bool variable = false,
  int unitsPerEm = 1000,
  int ascender = 1160,
  int descender = -288,
  int typoAscender = 880,
  int typoDescender = -120,
}) {
  final head = ByteData(54)..setUint16(18, unitsPerEm);
  final hhea = ByteData(36)
    ..setInt16(4, ascender)
    ..setInt16(6, descender)
    ..setInt16(8, -20);
  final os2 = ByteData(96)
    ..setUint16(0, 4)
    ..setUint16(62, useTypoMetrics ? 128 : 0)
    ..setInt16(68, typoAscender)
    ..setInt16(70, typoDescender)
    ..setInt16(72, 12)
    ..setUint16(74, 1200)
    ..setUint16(76, 33000);
  final tables = <String, Uint8List>{
    'hhea': hhea.buffer.asUint8List(),
    if (includeOs2) 'OS/2': os2.buffer.asUint8List(),
    'head': head.buffer.asUint8List(),
    if (variable) 'fvar': Uint8List(16),
  };
  var offset = 12 + tables.length * 16;
  final result = ByteData(
      offset + tables.values.fold<int>(0, (sum, bytes) => sum + bytes.length));
  result.setUint32(0, otf ? 0x4f54544f : 0x00010000);
  result.setUint16(4, tables.length);
  var entry = 12;
  for (final table in tables.entries) {
    for (var i = 0; i < 4; i++) {
      result.setUint8(entry + i, table.key.codeUnitAt(i));
    }
    result.setUint32(entry + 8, offset);
    result.setUint32(entry + 12, table.value.length);
    result.buffer
        .asUint8List()
        .setRange(offset, offset + table.value.length, table.value);
    offset += table.value.length;
    entry += 16;
  }
  return result.buffer.asUint8List();
}
