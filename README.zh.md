# 🌈 Flutter 主题生成器

[English](README.md) | 中文

`flex_theme_gen` 是一个由 YAML/JSON Design Tokens 驱动的 Flutter 主题代码生成器。它可以统一生成颜色、字体、排版、间距、圆角、阴影和边框，并提供类似 Tailwind CSS 的 Widget 链式扩展。

## 功能

- 生成亮色和暗色主题颜色
- 生成间距、圆角、阴影、边框及其他设计 Token
- 生成字体映射和 `TextStyle`
- 生成 `.twP4()`、`.twBg()`、`.twRounded4()` 等链式扩展
- 支持自定义链式方法前缀
- 支持 `build` 一次性生成和 `watch` 持续监听
- 支持通过 `pubspec.yaml` 或命令行指定输入、输出和模板目录

## 安装

在 Flutter 项目的 `pubspec.yaml` 中添加：

```yaml
dev_dependencies:
  flex_theme_gen: ^1.0.5
```

安装依赖：

```bash
flutter pub get
```

也可以全局安装 CLI：

```bash
dart pub global activate flex_theme_gen
```

## 快速开始

### 1. 配置输入和输出路径

在项目的 `pubspec.yaml` 根节点添加：

```yaml
flex_theme_gen:
  input: apps_config/design_tokens.yaml
  output: lib/generated/
```

### 2. 创建 Design Tokens 文件

创建 `apps_config/design_tokens.yaml`：

```yaml
fontsPackage: res

fonts:
  number: InterRes
  english: Roboto
  normal: Noto Sans SC

colors:
  light:
    colorFFFFFFFF: FFFFFFFF
    colorFF121212: FF121212
    colorFF33A9FF: FF33A9FF
  dark:
    colorFFFFFFFF: FF121212
    colorFF121212: FFFFFFFF
    colorFF33A9FF: FF005EA2

tokens:
  prefix: tw
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
    2: 2
    8: 8
  misc:
    opacityDisabled: 0.5
  border:
    default:
      colorToken: colorFF33A9FF
      width: 1
    2: 2
    4: 4

typography:
  normal:
    fontFamilyToken: normal
    sizes:
      H1_B: { fontSize: 24, fontWeight: w700, lineHeight: 24 }
      P1_R: { fontSize: 14, fontWeight: w400, lineHeight: 20 }
```

完整配置可以参考 [`example/apps_config/design_tokens.yaml`](example/apps_config/design_tokens.yaml)。

### 3. 生成主题代码

项目内运行：

```bash
dart run flex_theme_gen:gen_flex_theme build
```

全局安装后运行：

```bash
gen_flex_theme build
```

默认生成以下文件：

```text
lib/generated/
├── app_colors.g.dart
├── fonts.g.dart
├── tokens.g.dart
├── tw_alias.g.dart
├── tw_font.g.dart
├── typography.g.dart
└── typography_resolved.g.dart
```

`tw_alias.g.dart` 中的 `tw` 来自 `tokens.prefix`；修改前缀后，该别名文件及其中的方法名会相应变化。

## CLI 用法

```text
gen_flex_theme build [--input <path>] [--out <dir>] [--tpl <dir>]
gen_flex_theme watch [--input <path>] [--out <dir>] [--tpl <dir>]
gen_flex_theme --help
```

| 参数 | 说明 |
| --- | --- |
| `--input` | Design Tokens 文件路径 |
| `--out` | 生成代码的输出目录 |
| `--tpl` | 自定义模板目录 |

配置优先级为：命令行参数 → `pubspec.yaml` → 默认值。默认输入为 `design_tokens.yaml`，默认输出为 `output/`。

监听配置变化并自动重新生成：

```bash
dart run flex_theme_gen:gen_flex_theme watch
```

临时覆盖配置：

```bash
dart run flex_theme_gen:gen_flex_theme build \
  --input apps_config/design_tokens.yaml \
  --out lib/generated
```

## 在 Flutter 中使用

生成的文件需要由你的业务代码按需导入。例如：

```dart
import 'package:your_app/generated/app_colors.g.dart';
import 'package:your_app/generated/tokens.g.dart';
import 'package:your_app/generated/tw_alias.g.dart';
import 'package:your_app/generated/typography.g.dart';
```

链式构建 Widget：

```dart
Text(
  '注册',
  style: TextStyles.normal_P1_R.copyWith(
    color: AppColors.light().colorFFFFFFFF,
  ),
)
    .twPHx8()
    .twPVy4()
    .twBg(AppColors.light().colorFF33A9FF)
    .twRounded4();
```

实际生成的类名和成员以你的 Design Tokens 配置为准。

## 自定义字体

先在 Flutter 项目的 `pubspec.yaml` 注册字体：

```yaml
flutter:
  fonts:
    - family: InterRes
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

然后在 Design Tokens 中引用相同的 family：

```yaml
fonts:
  number: InterRes
```

## 常见问题

### 找不到输入文件

确认 `flex_theme_gen.input` 是相对于执行命令所在目录的正确路径，或使用 `--input` 显式指定。

### 命令不存在

项目内优先使用：

```bash
dart run flex_theme_gen:gen_flex_theme build
```

若使用 `gen_flex_theme`，需要先全局激活包，并确保 Dart Pub 的全局可执行目录已加入 `PATH`。

### 字体没有生效

检查 Flutter `pubspec.yaml` 中注册的 `family` 是否与 Design Tokens 的 `fonts` 值完全一致，并重新执行生成命令。

### 生成文件应该提交吗？

如果应用构建依赖这些文件，建议提交，确保 CI 和其他开发者拉取后可以直接构建；如果 CI 会稳定执行生成命令，也可以选择忽略，但团队应保持一致。

## 参与贡献

欢迎提交 Issue 和 Pull Request。提交前建议运行：

```bash
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
```

## 许可证

本项目采用 [MIT License](LICENSE)。
