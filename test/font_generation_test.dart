import 'dart:io';

import 'package:flex_theme_gen/flex_theme_gen.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/sfnt_fixture.dart';

void main() {
  late Directory project;
  late Paths paths;
  late List<String> logs;

  void write(String name, String content) => File(p.join(project.path, name))
    ..createSync(recursive: true)
    ..writeAsStringSync(name == 'config/design_tokens.yaml'
        ? 'colors:\n  light: {primary: FF123456}\n  dark: {primary: FF654321}\n$content'
        : content);

  String output(String name) => File(paths.joinOut(name)).readAsStringSync();
  Future<void> generate() =>
      runGenerateThemeTokens(paths: paths, logger: logs.add);

  setUp(() {
    project = Directory.systemTemp.createTempSync('flex_fonts_test_');
    paths = Paths(
      inputPath: p.join(project.path, 'config/design_tokens.yaml'),
      outDir: p.join(project.path, 'lib/generated'),
      templatesDir: p.absolute('lib/src/templates'),
    );
    logs = [];
    write('pubspec.yaml', '''
name: font_fixture
flutter:
  fonts:
    - family: Noto Sans SC
      fonts:
        - asset: assets/bold.ttf
          weight: 700
        - asset: assets/italic.ttf
          weight: 400
          style: italic
        - asset: assets/regular.ttf
          weight: 400
    - family: Custom
      fonts:
        - asset: assets/custom.otf
flutter_gen:
  fonts:
    - family: System Only
      fonts:
        - asset: must_not_read.ttf
''');
    for (final name in [
      'bold.ttf',
      'italic.ttf',
      'regular.ttf',
      'custom.otf'
    ]) {
      File(p.join(project.path, 'assets', name))
        ..createSync(recursive: true)
        ..writeAsBytesSync(sfntFixture(
          otf: name.endsWith('.otf'),
          ascender: name == 'regular.ttf' || name == 'custom.otf' ? 1160 : 900,
          useTypoMetrics: true,
          variable: name == 'regular.ttf',
        ));
    }
    write('config/design_tokens.yaml', '''
fontsPackage: res
fonts:
  notoSansSC: Noto Sans SC
  custom: Custom
  system: System Only
typography:
  body:
    fontFamilyToken: notoSansSC
    sizes:
      regular: {fontSize: 15, fontWeight: 400, lineHeight: 20}
  custom:
    fontFamilyToken: custom
    size: 15
  system:
    fontFamilyToken: system
    size: 15
  direct:
    fontFamily: Noto Sans SC
    size: 15
''');
  });

  tearDown(() => project.deleteSync(recursive: true));

  test('declared fonts share package rules in both typography modes', () async {
    await generate();
    final fonts = output('fonts.g.dart');
    expect(fonts, contains("static const notoSansSC = 'res';"));
    expect(fonts, contains("static const custom = 'res';"));
    expect(fonts, contains('static const system = null;'));
    final styles = output('typography.g.dart').split('\n');
    for (final name in ['body_regular', 'custom', 'direct']) {
      expect(styles.singleWhere((line) => line.contains('TextStyle $name =')),
          contains("package: 'res'"));
    }
    expect(styles.singleWhere((line) => line.contains('TextStyle system =')),
        isNot(contains('package:')));
    expect(logs.join('\n'), isNot(contains('must_not_read')));
  });

  test('metrics only for bundled tokens; picks regular nonitalic default',
      () async {
    await generate();
    final metrics = output('fonts.g.dart').split('class FontMetrics').last;
    expect(metrics, contains('static const notoSansSC = FontVerticalMetrics('));
    expect(metrics, contains('static const custom = FontVerticalMetrics('));
    expect(metrics, isNot(contains('static const system')));
    expect(metrics, contains('ascent: 1160,'));
    expect(metrics, isNot(contains('ascent: 900,')));
    expect(metrics, contains('descent: 288,'));
    expect(metrics, contains('useTypoMetrics: true,'));
  });

  test('generated lookup and optical offset execute correctly', () async {
    await generate();
    // Existing template imports Flutter, though these constants need only Dart.
    final generated = output('fonts.g.dart')
        .replaceAll("import 'package:flutter/material.dart';", '');
    write('check.dart', '''
$generated
void check(bool value) { if (!value) throw StateError('metrics check failed'); }
void main() {
  const metrics = FontMetrics.notoSansSC;
  check((metrics.opticalCenterOffset - 0.056).abs() < 1e-12);
  check(identical(FontMetrics.of(FontFamilies.notoSansSC), metrics));
  check(identical(FontMetrics.of(FontFamilies.notoSansSC, package: 'res'), metrics));
  check(FontMetrics.of(FontFamilies.notoSansSC, package: 'wrong') == null);
  check(FontMetrics.of(null) == null);
  check(FontMetrics.of('unknown') == null);
  check(FontMetrics.of(FontFamilies.system) == null);
  const invalid = FontVerticalMetrics(unitsPerEm: 1000, ascent: 1160,
      descent: 288, lineGap: 0, typoAscender: 0, typoDescender: 0,
      useTypoMetrics: false);
  check(invalid.opticalCenterOffset == 0);
}
''');
    final result = await Process.run(
        Platform.resolvedExecutable, [p.join(project.path, 'check.dart')]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  test('repeated generation is byte identical for every output', () async {
    await generate();
    final before = {
      for (final file in Directory(paths.outDir).listSync().whereType<File>())
        file.path: file.readAsBytesSync(),
    };
    await generate();
    for (final entry in before.entries) {
      expect(File(entry.key).readAsBytesSync(), entry.value, reason: entry.key);
    }
  });

  test('metric changes leave every other generated file byte identical',
      () async {
    await generate();
    final before = {
      for (final file in Directory(paths.outDir).listSync().whereType<File>())
        p.basename(file.path): file.readAsBytesSync(),
    };
    File(p.join(project.path, 'assets/regular.ttf'))
        .writeAsBytesSync(sfntFixture(ascender: 1200, typoAscender: 900));
    await generate();
    for (final entry in before.entries) {
      final actual = File(paths.joinOut(entry.key)).readAsBytesSync();
      expect(actual,
          entry.key == 'fonts.g.dart' ? isNot(entry.value) : entry.value,
          reason: entry.key);
    }
  });

  test('existing custom template directories need no new templates', () async {
    final customTemplates = Directory(p.join(project.path, 'templates'))
      ..createSync();
    for (final file
        in Directory(paths.templatesDir).listSync().whereType<File>()) {
      if (p.basename(file.path) == 'font_metrics.dart.tmpl') continue;
      file.copySync(p.join(customTemplates.path, p.basename(file.path)));
    }
    paths = Paths(
        inputPath: paths.inputPath,
        outDir: paths.outDir,
        templatesDir: customTemplates.path);
    await generate();
    expect(output('fonts.g.dart'), contains('class FontMetrics'));
  });

  test('legacy outputs match unmodified 1.0.8 snapshots', () async {
    paths = Paths(
      inputPath: 'test/fixtures/legacy/design_tokens.yaml',
      outDir: paths.outDir,
      templatesDir: paths.templatesDir,
    );
    // No declarations in the target package either.
    write('pubspec.yaml',
        File('test/fixtures/legacy/pubspec.yaml').readAsStringSync());
    await generate();
    for (final snapshot in Directory('test/fixtures/snapshots/legacy')
        .listSync()
        .whereType<File>()) {
      expect(output(p.basename(snapshot.path).replaceAll('.golden', '.dart')),
          snapshot.readAsStringSync(),
          reason: snapshot.path);
    }
  });

  test('missing file warns with path while other outputs and metrics survive',
      () async {
    File(p.join(project.path, 'assets/regular.ttf')).deleteSync();
    await generate();
    expect(logs.join('\n'), contains('⚠️'));
    expect(logs.join('\n'), contains('assets/regular.ttf'));
    final metrics = output('fonts.g.dart').split('class FontMetrics').last;
    expect(metrics, contains('static const custom = FontVerticalMetrics('));
    expect(metrics, isNot(contains('static const notoSansSC =')));
    expect(output('typography.g.dart'), contains('class TextStyles'));
    // Declaration, not successful parsing, determines the package.
    expect(
        output('fonts.g.dart'), contains("static const notoSansSC = 'res';"));
  });

  for (final extension in ['ttc', 'woff', 'woff2', 'ttf']) {
    test('$extension unsupported/corrupt font warns and skips only that font',
        () async {
      write('pubspec.yaml', '''
flutter:
  fonts:
    - family: Noto Sans SC
      fonts:
        - asset: assets/bad.$extension
    - family: Custom
      fonts:
        - asset: assets/custom.otf
''');
      write(
          'assets/bad.$extension', extension == 'ttf' ? 'garbage' : extension);
      await generate();
      expect(logs.join('\n'), contains('⚠️'));
      expect(logs.join('\n'), contains('assets/bad.$extension'));
      final metrics = output('fonts.g.dart').split('class FontMetrics').last;
      expect(metrics, isNot(contains('static const notoSansSC =')));
      expect(metrics, contains('static const custom = FontVerticalMetrics('));
    });
  }

  test('object tokens allow explicit asset and system override', () async {
    write('config/design_tokens.yaml', '''
fontsPackage: res
fonts:
  notoSansSC: {family: Noto Sans SC, system: true}
  custom: {family: Explicit, asset: assets/custom.otf}
  system: Undeclared Custom Family
typography:
  body:
    fontFamilyToken: notoSansSC
    sizes:
      regular: {fontSize: 15}
  explicit:
    fontFamilyToken: custom
    size: 15
  system:
    fontFamilyToken: system
    size: 15
''');
    await generate();
    expect(output('fonts.g.dart'), contains('static const notoSansSC = null;'));
    expect(output('fonts.g.dart'), contains("static const custom = 'res';"));
    expect(output('fonts.g.dart'), contains('static const system = null;'));
    final styles = output('typography.g.dart').split('\n');
    expect(styles.singleWhere((s) => s.contains('TextStyle body_regular =')),
        isNot(contains('package:')));
    expect(styles.singleWhere((s) => s.contains('TextStyle explicit =')),
        contains("package: 'res'"));
  });

  test('tokens sharing an explicit asset family share metrics and package',
      () async {
    write('pubspec.yaml', 'name: explicit_fixture\n');
    write('config/design_tokens.yaml', '''fontsPackage: res
fonts:
  custom: {family: Explicit, asset: assets/custom.otf}
  alias: Explicit
  system: {family: Explicit, system: true}
''');
    await generate();
    final fonts = output('fonts.g.dart');
    expect(fonts, contains("static const alias = 'res';"));
    final metrics = fonts.split('class FontMetrics').last;
    expect(metrics, contains('static const alias = FontVerticalMetrics('));
    expect(metrics, isNot(contains('static const system =')));
  });

  test('absent weight means 400; otherwise falls back to first asset',
      () async {
    write('pubspec.yaml', '''
flutter:
  fonts:
    - family: Noto Sans SC
      fonts:
        - asset: assets/bold.ttf
          weight: 700
        - asset: assets/regular.ttf
    - family: Custom
      fonts:
        - asset: assets/custom.otf
          style: italic
          weight: 700
        - asset: missing.ttf
          weight: 900
''');
    await generate();
    expect(logs.join('\n'), isNot(contains('⚠️')));
    final metrics = output('fonts.g.dart').split('class FontMetrics').last;
    expect(metrics, isNot(contains('ascent: 900,')));
    expect(metrics, contains('static const custom = FontVerticalMetrics('));
  });
}
