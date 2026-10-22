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
  flex_theme_gen: ^1.1.1
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

## 字体垂直度量（1.1.0）

生成器只读取目标 package 的 `pubspec.yaml` 中**顶层 `flutter.fonts`**，忽略
`flutter_gen` 等其他节点下的 `fonts`。从输出目录逐级向上寻找最近的
`pubspec.yaml`；找不到时使用执行命令目录下的 pubspec。asset 路径相对于该
pubspec 所在目录解析。同 family 有多个文件时，优先取第一个 weight 为 400、
style 为 normal 的文件（省略时分别默认为 400 / normal），否则取第一个。
同 family 重复声明时，采用第一组含 asset 的声明。

保留字符串写法，同时支持显式 asset 或系统字体覆盖：

```yaml
fontsPackage: res
fonts:
  notoSansSC: Noto Sans SC
  custom: {family: MyFont, asset: assets/fonts/MyFont.otf}
  system: {family: Roboto, system: true}
```

显式 `asset` 优先于 pubspec 中选出的文件。family 有 asset 声明就是打包字体，
设置了 `fontsPackage` 时带 package；未声明的 family 按系统字体处理，不带
package。`system: true` 对该 Token 优先，即使 pubspec 已声明同名字体，也不带
package、不生成度量。两个生成器共用此判断，**Noto Sans SC、Roboto 等名字不再
被硬编码为系统字体**。文件缺失或损坏不会改变 package 判断，但不会生成其度量字段。

项目存在打包字体 Token 时，`fonts.g.dart` 会追加：

- `FontVerticalMetrics`：const 构造；字段包括 `unitsPerEm`、`ascent`、正数
  `descent`、`lineGap`、保留符号的 `typoAscender` / `typoDescender` 和
  `useTypoMetrics`（OS/2 fsSelection bit 7）。
- `FontMetrics.<token>`：每个解析成功的打包字体一个 static const；系统字体没有字段。
- `FontMetrics.of(String? family, {String? package})`：以 `FontFamilies` 的原始值
  查找，null 或未知 family 返回 null；传入 package 时必须匹配 `FontPackages`，
  省略则只按 family 查找。可以直接传 `TextStyle.fontFamily`，支持 Flutter 的
  `packages/<package>/<family>` 前缀；显式 package 冲突，或前缀缺少 package / family
  时返回 null。

```dart
final metrics = FontMetrics.of(
  FontFamilies.notoSansSC,
  package: FontPackages.notoSansSC,
);
final k = metrics?.opticalCenterOffset ?? 0.0;
final dy = -k * fontSize; // 由使用方的 Text 组件做纯视觉平移。
```

偏移系数为
`((ascent - descent) / 2 - (typoAscender + typoDescender) / 2) / unitsPerEm`。
Noto Sans SC 的真实值 upem 1000、hhea 1160/−288、typo 880/−120 得到 **0.056**。
`typoAscender - typoDescender <= 0` 时返回 0。缺少 OS/2 表时，typo 字段为 0、
`useTypoMetrics` 为 false、偏移为 0，仍保留 hhea 度量。

使用纯 Dart 按 tag 读取 sfnt 表目录及 `head`、`hhea`、`OS/2` 度量表头，包含
有符号的 typo lineGap 和无符号的 Windows ascent/descent，不解析字形，不新增依赖。
支持 `.ttf` / `.otf`，可变字体取**默认实例**。不支持 `.ttc` / `.woff` / `.woff2`；
文件缺失、截断或损坏时输出包含路径及原因的警告，跳过该字体，其余输出继续生成。
不处理非默认可变字体实例、字形边界或设备渲染验证。

生成器不生成 Widget，也不向 TextStyle 添加 height 补偿。新增度量只追加到
`fonts.g.dart`，其他文件仅在修正字体 package 时有预期变化。Token 顺序固定，
没有生成时间戳。未声明打包字体 Token 的项目不生成度量 API；使用原系统字体名单内
未声明 family 的旧项目保持逐字节一致。未声明的自定义 family 现在也不带 package，
需要注册 asset 才会保留 package。旧版自定义模板目录无需添加新模板。

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
