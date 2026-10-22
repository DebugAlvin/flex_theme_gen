import 'package:flex_theme_gen/flex_theme_gen.dart';
import 'package:flex_theme_gen/src/utils/yaml_util.dart';
import 'package:test/test.dart';

void main() {
  test('public version matches pubspec release version', () {
    expect(genFlexThemeVersion, YamlUtil.load('pubspec.yaml')['version']);
  });
}
