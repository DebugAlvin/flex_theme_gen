# 🌈 Flutter Theme Generator

Language: English | [中文文档 🇨🇳](README.zh.md)

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
  flex_theme_gen: ^1.0.6
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
