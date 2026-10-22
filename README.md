# 🌈 Flutter Theme Generator

Language: English | [中文文档 🇨🇳](https://github.com/DebugAlvin/flex_theme_gen/blob/main/README.zh.md)

---

A powerful **Flutter theme generation tool** based on YAML design tokens,  
capable of automatically generating typography, colors, tokens, and Tailwind-style widget extensions.

It is designed for design systems that need to maintain consistency between design and code.

---

## ✨ Features

- 🧱 Generate color, font, spacing, radius, shadow, and border tokens  
- 🎨 Support light / dark theme switching  
- 🧩 Tailwind-like chainable widget extensions (`.twBg()`, `.twRadius4()`, `.twBorder2()`)  
- 💡 Automatically read from YAML configuration  
- ⚙️ Fully integrated with `melos` and CI environments  
- 🔠 Support for custom fonts (via Flutter assets)

---

## 🚀 Installation

Add to your `dev_dependencies`:

```yaml
dev_dependencies:
  flex_theme_gen: ^1.1.1
```

Then activate globally (optional):

```bash
dart pub global activate flex_theme_gen
```

You can then run it globally with:

```bash
gen_flex_theme build
```

or from project scripts:

```bash
dart run flex_theme_gen:gen_flex_theme build
```

------

## **📁 Configuration (in** pubspec.yaml)

Add the following under the root of your **design system / resource module** (e.g., res/):

```yaml
flex_theme_gen:
  input: design_tokens.yaml
  output: lib/gen
```

This means:

- input — path to your token definition file (YAML or JSON)
- output — where generated Dart files will be written

------

## **🧩 design_tokens.yaml Example**

```yaml
tokens:
  prefix: tw   # prefix for generated chain methods
  spacing:
    4: 4
    8: 8
    12: 12
    16: 16
  radius:
    4: 4
    8: 8
    12: 12
  shadow:
    1: 2
    2: 4
  misc:
    opacityDisabled: 0.5
  border:
    default:
      colorToken: colorFF33A9FF
      width: 1
    2: 2
    4: 4
    6: 6

colors:
  light:
    colorFFFFFF: "#FFFFFF"
    color000000: "#000000"
    colorFF33A9FF: "#33A9FF"
  dark:
    colorFFFFFF: "#000000"
    color000000: "#FFFFFF"
    colorFF33A9FF: "#33A9FF"

typography:
  fonts:
    default:
      family: InterRes
      size: 16
      weight: 400
      lineHeight: 1.5
    P2_B:
      family: InterRes
      size: 14
      weight: 700
```

## **🔤 Load Custom Fonts Example**

In pubspec.yaml:

```yaml
flutter:
  fonts:
    - family: InterRes
      fonts:
        - asset: assets/fonts/Inter_24pt-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter_24pt-Bold.ttf
          weight: 700
```

You can then use the generated text styles directly:

```dart
Text(
  'Sign Up',
  style: TextStyles.normal_P2_B.copyWith(
    color: colors.colorFFFFFFFF,
  ),
)
.twPHx8()
.twPVy6()
.twBg(colors.colorFF33A9FF)
.twRounded4()
.onTap(() {
  print('Sign up tapped');
}),
```

------

## Font vertical metrics (1.1.0)

Use root-level font tokens matching the registered Flutter family:

```yaml
fontsPackage: res
fonts:
  notoSansSC: Noto Sans SC
  custom: {family: MyFont, asset: assets/fonts/MyFont.otf}
  system: {family: Roboto, system: true}
```

The generator reads **only top-level `flutter.fonts`** in the target package's
`pubspec.yaml`, ignoring `flutter_gen` and any other nested `fonts` keys. The
target pubspec is the nearest ancestor of the output directory; if none exists,
it uses the current working directory's pubspec. Asset paths are relative to
that pubspec's directory. A token's explicit `asset` overrides the pubspec asset.
For multiple files in one family, the first nonitalic weight-400 file is chosen
(omitted weight/style mean 400/normal); otherwise the first asset is used. If a
family is declared more than once, its first declaration with assets wins.

A family with a declared asset is bundled and receives `fontsPackage` when set;
an undeclared family is treated as a system font and receives no package.
`system: true` overrides the corresponding token even if its family is bundled.
This also applies to formerly hardcoded names such as **Noto Sans SC** and
**Roboto**. Missing or invalid asset files still count as declarations for
package assignment, but do not get metrics constants.

For projects with bundled font tokens, `fonts.g.dart` appends:

- `FontVerticalMetrics`, with a const constructor and `unitsPerEm`, `ascent`,
  positive `descent`, `lineGap`, signed `typoAscender` / `typoDescender`, and
  `useTypoMetrics` (OS/2 fsSelection bit 7).
- `FontMetrics.<token>`, a static const for each successfully parsed bundled
  token. System tokens have no metrics field.
- `FontMetrics.of(String? family, {String? package})`, which looks up the raw
  `FontFamilies` value. Null/unknown families return null; when supplied, package
  must match `FontPackages`. When omitted, lookup is by family alone.
  You can pass `TextStyle.fontFamily` directly, including Flutter's
  `packages/<package>/<family>` prefix. Conflicting explicit packages and
  prefixes with a missing package or family return null.

```dart
final metrics = FontMetrics.of(
  FontFamilies.notoSansSC,
  package: FontPackages.notoSansSC,
);
final k = metrics?.opticalCenterOffset ?? 0.0;
final dy = -k * fontSize; // Apply as a visual translation in your own Text component.
```

`opticalCenterOffset` is
`((ascent - descent) / 2 - (typoAscender + typoDescender) / 2) / unitsPerEm`.
The Noto Sans SC values 1000, 1160/−288 and 880/−120 give **0.056**.
If the typo box has nonpositive height, the getter returns zero. Missing OS/2
also gives zero typo values, `useTypoMetrics: false`, and zero offset.

Parsing uses pure Dart, reads the sfnt directory by tag and the `head`, `hhea`,
and `OS/2` metric headers (including typo lineGap and unsigned Windows metrics),
and does not parse glyphs. `.ttf` and `.otf`, including variable fonts at their
**default instance**, are supported. `.ttc`, `.woff`, `.woff2`, missing files,
and malformed/truncated data log explicit warnings containing the asset path
and are skipped while the remaining outputs are generated. Nondefault variable
font instances, glyph bounds and device-specific visual alignment are outside
this generator's scope.

No Widgets or TextStyle height adjustments are generated. Metrics only append
content to `fonts.g.dart`; other files only change when correcting a font's
package. Token ordering is stable and no generation timestamps are written.
Projects with no bundled font tokens do not emit the metrics API. Legacy
projects using undeclared families from the former system-font list retain
byte-identical output. Undeclared custom families now also receive no package;
register their assets to retain a package. Existing custom template folders
need no changes.

------

## **🧠 Generated Files**

After running gen_flex_theme build, the tool will generate files under your output folder:

```
lib/gen/
  ├── app_colors.g.dart
  ├── tokens.g.dart
  ├── tw_alias.g.dart
  ├── fonts.g.dart
  ├── tw_font.g.dart
  ├── typography.g.dart
  └── typography_resolved.g.dart
```

------

## **🧱 Integration with Melos (Optional)**

You can automate theme generation during bootstrap:

```yaml
melos:
  command:
    bootstrap:
      hooks:
        pre: |
          flutter clean
          fvm dart run scripts/clean_generate_dart_file.dart || true
          melos exec --scope="res" -- gen_flex_theme build
```

This ensures your res module automatically generates theme files every time you run:

```dart
This ensures your res module automatically generates theme files every time you run:
```

## **⚙️ CLI Commands**

| **Command**          | **Description**                              |
| -------------------- | -------------------------------------------- |
| gen_flex_theme build | One-time generation                          |
| gen_flex_theme watch | Watch mode (auto re-generate on file change) |

------

## **🧩 Example Project Structure**

```
project_root/
├── modules/
│   ├── res/
│   │   ├── design_tokens.yaml
│   │   ├── lib/gen/               # Generated theme files
│   │   └── pubspec.yaml
│   ├── login/
│   ├── sport/
│   └── ...
└── melos.yaml
```

------

## **📜 License**

This project is released under the MIT License.

------

## **💬 Feedback & Contribution**

Contributions, bug reports, and feature requests are welcome!

Feel free to open an issue or pull request on GitHub.
