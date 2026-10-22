# Changelog

## 1.1.0
- Added deterministic `FontVerticalMetrics` / `FontMetrics` output in `fonts.g.dart` for declared font assets, including optical center offsets for visual alignment by consumers. No Widgets or TextStyle height compensation are generated.
- Read TrueType/OpenType headers (including variable fonts at their default instance) in pure Dart without new dependencies. Missing, malformed, TTC and WOFF/WOFF2 assets produce path-specific warnings and are skipped without stopping generation.
- Resolve font assets from the target package's top-level `flutter.fonts`; prefer nonitalic weight 400 (omitted weight means 400), otherwise the first asset. Added optional `{family, asset, system}` token objects while preserving string tokens.
- Fixed font package assignment in both font and typography generators using one declaration-based policy. Bundled families named Roboto, Noto Sans SC, etc. now correctly receive `fontsPackage`; undeclared families are system fonts and receive no package. Explicit `system: true` overrides a token's declaration. Older projects relying on undeclared names from the former system-font list retain the same output.
- Font metrics only add content to `fonts.g.dart`; the other generated files retain their format and content except for the intentional font package correction. Legacy projects using undeclared families from the former system-font list retain byte-identical output; undeclared custom families now also receive no package and should register their font assets. Existing custom template directories need no new templates.

## 1.0.8
- Removed generation timestamps from generated code comments to avoid unnecessary Git changes when regenerating unchanged tokens.

## 1.0.7
- 🔗 Changed the Chinese documentation link to an external GitHub URL for pub.dev compatibility.

## 1.0.6
- 📝 Added comprehensive Chinese documentation and corrected usage examples.
- 🔗 Fixed documentation links and synchronized package version metadata.

## 1.0.5
- 📝 Updated README and English documentation.
- ✨ Improved multilingual support structure for documentation.

## 1.0.4
- 🧩 Initial public release.
- 🎨 Added theme generation for colors, typography, tokens, and Tailwind-style extensions.
- ⚙️ Integrated `melos` bootstrap hooks for automatic generation.
