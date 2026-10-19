// GENERATED CODE - DO NOT MODIFY BY HAND
// ============================================================
//  Design Tokens → Flutter constants
//  Source: {{ source }}
// ============================================================

import 'package:flutter/material.dart';

/// 全局 Design Tokens（间距 / 圆角 / 阴影等）
///
/// ⚙️ 本文件由脚本自动生成，请勿手动修改。
///
/// 示例：
/// ```dart
/// padding: EdgeInsets.all(Tokens.spacingMd),
/// borderRadius: BorderRadius.circular(Tokens.radiusLg),
/// ```
class Tokens {
  // ============================================================
  // 🧩 Spacing Tokens
  // ============================================================
  static const spacing10 = 10.0;
  static const spacing12 = 12.0;
  static const spacing16 = 16.0;
  static const spacing2 = 2.0;
  static const spacing24 = 24.0;
  static const spacing32 = 32.0;
  static const spacing4 = 4.0;
  static const spacing6 = 6.0;
  static const spacing8 = 8.0;

  // ============================================================
  // 🟢 Radius Tokens
  // ============================================================
  static const radius12 = 12.0;
  static const radius16 = 16.0;
  static const radius24 = 24.0;
  static const radius4 = 4.0;
  static const radius8 = 8.0;

  // ============================================================
  // 🌫 Shadow Tokens（可选）
  // ============================================================
  static const shadow12 = 12.0;
  static const shadow16 = 16.0;
  static const shadow2 = 2.0;
  static const shadow24 = 24.0;
  static const shadow8 = 8.0;

  // ============================================================
  // 🟢 Border Tokens
  // ============================================================
  static const border2 = 2.0;
  static const border4 = 4.0;
  static const border6 = 6.0;
  static const border8 = 8.0;

  // ============================================================
  // 🎨 Opacity / Blur / Misc Tokens（可选）
  // ============================================================
  static const miscBlurMd = 6.0;
  static const miscBlurSm = 2.0;
  static const miscOpacityDisabled = 0.5;

  // ---------------- Border Defaults ----------------
  /// 默认边框宽度（可被链式方法 twBorder 的 `width` 覆盖）
  static const double borderDefaultWidth = 1.0;

  /// 默认边框颜色所引用的 AppColors token 名（可为空字符串）
  /// - 非空时，链式扩展优先使用 `colors.<token>`，否则回退到 `borderDefaultColor`
  static const String borderDefaultColorToken = 'colorFF33A9FF';
}