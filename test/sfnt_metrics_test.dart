import 'dart:typed_data';

import 'package:flex_theme_gen/src/fonts/sfnt_metrics.dart';
import 'package:test/test.dart';

import 'support/sfnt_fixture.dart';

void main() {
  for (final otf in [false, true]) {
    test('${otf ? 'OTF' : 'TTF'} reads signed/unsigned fields by table tag',
        () {
      final metrics = parseFontMetrics(sfntFixture(otf: otf));
      expect(metrics.unitsPerEm, 1000);
      expect(metrics.ascent, 1160);
      expect(metrics.descent, 288);
      expect(metrics.lineGap, -20);
      expect(metrics.typoAscender, 880);
      expect(metrics.typoDescender, -120);
      expect(metrics.typoLineGap, 12);
      expect(metrics.winAscent, 1200);
      expect(metrics.winDescent, 33000);
      expect(metrics.useTypoMetrics, isFalse);
      expect(metrics.opticalCenterOffset, closeTo(0.056, 1e-12));
    });
  }

  test('USE_TYPO_METRICS bit 7; variable font uses base table values', () {
    final metrics =
        parseFontMetrics(sfntFixture(useTypoMetrics: true, variable: true));
    expect(metrics.useTypoMetrics, isTrue);
    expect(metrics.ascent, 1160);
    expect(metrics.opticalCenterOffset, closeTo(0.056, 1e-12));
  });

  test('absent OS/2 retains hhea with unavailable typo metrics and zero offset',
      () {
    final metrics = parseFontMetrics(sfntFixture(includeOs2: false));
    expect(metrics.ascent, 1160);
    expect(metrics.typoAscender, 0);
    expect(metrics.typoDescender, 0);
    expect(metrics.useTypoMetrics, isFalse);
    expect(metrics.winAscent, isNull);
    expect(metrics.winDescent, isNull);
    expect(metrics.opticalCenterOffset, 0);
  });

  test('invalid typo height gives zero offset', () {
    for (final ascender in [-1, 0]) {
      expect(
          parseFontMetrics(
                  sfntFixture(typoAscender: ascender, typoDescender: 0))
              .opticalCenterOffset,
          0);
    }
  });

  test('truncated table and directory are rejected', () {
    final bytes = sfntFixture();
    expect(
        () =>
            parseFontMetrics(Uint8List.sublistView(bytes, 0, bytes.length - 1)),
        throwsFormatException);
    expect(() => parseFontMetrics(Uint8List.sublistView(bytes, 0, 20)),
        throwsFormatException);
    // OS/2 claims only 70 bytes while the file still has bytes after it.
    final shortTable = sfntFixture();
    ByteData.sublistView(shortTable).setUint32(12 + 16 + 12, 70);
    expect(() => parseFontMetrics(shortTable), throwsFormatException);
  });

  test('all truncation points fail cleanly without RangeError', () {
    final bytes = sfntFixture();
    for (var length = 0; length < bytes.length; length++) {
      expect(() => parseFontMetrics(Uint8List.sublistView(bytes, 0, length)),
          throwsFormatException,
          reason: 'length=$length');
    }
  });

  test('non-font, TTC and WOFF signatures are rejected explicitly', () {
    for (final signature in ['ttcf', 'wOFF', 'wOF2', 'nope']) {
      final bytes = Uint8List(12)..setRange(0, 4, signature.codeUnits);
      expect(() => parseFontMetrics(bytes), throwsFormatException);
    }
  });

  test('invalid unitsPerEm and missing required tables are rejected', () {
    expect(() => parseFontMetrics(sfntFixture(unitsPerEm: 0)),
        throwsFormatException);
    final missingHead = sfntFixture();
    missingHead.setRange(12 + 32, 12 + 36, 'xxxx'.codeUnits);
    expect(() => parseFontMetrics(missingHead), throwsFormatException);
  });
}
