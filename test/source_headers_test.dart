import 'dart:io';

import 'package:flex_theme_gen/flex_theme_gen.dart';
import 'package:flex_theme_gen/src/utils/template_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  const source = 'test/fixtures/legacy/design_tokens.yaml';

  test('every template renders a relative source regardless of tag spacing',
      () {
    for (final template
        in Directory('lib/src/templates').listSync().whereType<File>()) {
      final rendered = renderTemplate(template.readAsStringSync(), {
        'source': p.absolute(source),
      });
      expect(rendered.split('\n')[3], '//  Source: $source',
          reason: template.path);
    }
    expect(
        renderTemplate(
            '{{source}}|{{ source }}|{{  source  }}', {'source': source}),
        '$source|$source|$source');
  });

  test(
      'all seven generated headers match snapshot and absolute/relative inputs',
      () async {
    final project = Directory.systemTemp.createTempSync('flex_headers_test_');
    addTearDown(() => project.deleteSync(recursive: true));
    File(p.join(project.path, 'pubspec.yaml'))
        .writeAsStringSync('name: headers_fixture\n');
    final paths = Paths(
      inputPath: p.absolute(source),
      outDir: p.join(project.path, 'generated'),
      templatesDir: p.absolute('lib/src/templates'),
    );
    await runGenerateThemeTokens(paths: paths, logger: (_) {});
    final files = Directory(paths.outDir).listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    expect(files, hasLength(7));
    final snapshot = files
        .map((file) => '${p.basename(file.path)}\n'
            '${file.readAsLinesSync().take(5).join('\n')}')
        .join('\n\n');
    expect(
        '$snapshot\n',
        File('test/fixtures/snapshots/source_headers.golden')
            .readAsStringSync());
    final before = {
      for (final file in files) file.path: file.readAsBytesSync()
    };
    await runGenerateThemeTokens(
        paths: Paths(
            inputPath: source,
            outDir: paths.outDir,
            templatesDir: paths.templatesDir),
        logger: (_) {});
    for (final entry in before.entries) {
      expect(File(entry.key).readAsBytesSync(), entry.value, reason: entry.key);
    }
  });
}
