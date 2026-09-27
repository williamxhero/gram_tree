import 'package:flutter/material.dart';

/// 味谱的配色和字体，来自 UI 规范（SPEC-009.1 #18、SPEC-009.2 #34、样稿画布）。
///
/// * 纸 #F7F4EE 做页面底色，卡片 #FFFDF9，墨 #1B1813 做主按钮和正文。
/// * 酱红 #B0441E 只用在“系统替你改了”的地方（按你的口味换算、按场景调整），
///   不要拿来做普通强调。
/// * 已验证用绿 #4E6B48。
/// * 标题 Noto Serif SC，正文 Noto Sans SC，数字 DM Mono（用 [GramTreeColors.numberStyle]）。
///
/// 深色配色规范里还没定，下面的深色值是按浅色反推的临时值，#18 做组件库时定稿。
/// 字体目前只写了字体名，没有打包字体文件，装了对应字体的设备才会显示；
/// 打包哪些字重、要不要裁剪字符集，在 #18 决定。
class GramTreePalette {
  const GramTreePalette._();

  static const paper = Color(0xFFF7F4EE);
  static const card = Color(0xFFFFFDF9);
  static const ink = Color(0xFF1B1813);
  static const accent = Color(0xFFB0441E);
  static const verified = Color(0xFF4E6B48);

  // 深色（临时）
  static const paperDark = Color(0xFF171511);
  static const cardDark = Color(0xFF221F1A);
  static const inkDark = Color(0xFFF1ECE3);
  static const accentDark = Color(0xFFE07A52);
  static const verifiedDark = Color(0xFF8DAE84);
}

const titleFont = 'Noto Serif SC';
const bodyFont = 'Noto Sans SC';
const numberFont = 'DM Mono';

/// 没装规范字体时的回退顺序，保证中文能正常显示。
const _cjkFallback = [
  'PingFang SC',
  'Noto Sans CJK SC',
  'Source Han Sans SC',
  'sans-serif',
];

/// 组件用到的、Material 配色里没有对应位置的颜色。
@immutable
class GramTreeColors extends ThemeExtension<GramTreeColors> {
  const GramTreeColors({
    required this.paper,
    required this.card,
    required this.ink,
    required this.accent,
    required this.verified,
  });

  final Color paper;
  final Color card;
  final Color ink;

  /// 只用于“系统替你改了”的数值和标记。
  final Color accent;

  /// “已验证”标记。
  final Color verified;

  /// 数字用等宽字体，方便对齐和比较。
  TextStyle numberStyle(TextStyle base) => base.copyWith(
    fontFamily: numberFont,
    fontFamilyFallback: const ['monospace'],
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static GramTreeColors of(BuildContext context) =>
      Theme.of(context).extension<GramTreeColors>()!;

  @override
  GramTreeColors copyWith({
    Color? paper,
    Color? card,
    Color? ink,
    Color? accent,
    Color? verified,
  }) => GramTreeColors(
    paper: paper ?? this.paper,
    card: card ?? this.card,
    ink: ink ?? this.ink,
    accent: accent ?? this.accent,
    verified: verified ?? this.verified,
  );

  @override
  GramTreeColors lerp(GramTreeColors? other, double t) {
    if (other == null) return this;
    return GramTreeColors(
      paper: Color.lerp(paper, other.paper, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      verified: Color.lerp(verified, other.verified, t)!,
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = dark
      ? const GramTreeColors(
          paper: GramTreePalette.paperDark,
          card: GramTreePalette.cardDark,
          ink: GramTreePalette.inkDark,
          accent: GramTreePalette.accentDark,
          verified: GramTreePalette.verifiedDark,
        )
      : const GramTreeColors(
          paper: GramTreePalette.paper,
          card: GramTreePalette.card,
          ink: GramTreePalette.ink,
          accent: GramTreePalette.accent,
          verified: GramTreePalette.verified,
        );

  // 主按钮用墨色；酱红不进 Material 的 primary/secondary，避免被普通控件用掉
  final scheme =
      ColorScheme.fromSeed(
        seedColor: GramTreePalette.ink,
        brightness: brightness,
      ).copyWith(
        primary: colors.ink,
        onPrimary: colors.paper,
        primaryContainer: dark
            ? const Color(0xFF3A342C)
            : const Color(0xFFE6DFD3),
        onPrimaryContainer: colors.ink,
        surface: colors.paper,
        onSurface: colors.ink,
        surfaceContainerLowest: colors.card,
        surfaceContainerLow: colors.card,
        surfaceContainer: colors.card,
        onSurfaceVariant: dark
            ? const Color(0xFFB9B1A4)
            : const Color(0xFF5E574C),
        outline: dark ? const Color(0xFF5A5247) : const Color(0xFFCFC6B8),
        outlineVariant: dark
            ? const Color(0xFF3A342C)
            : const Color(0xFFE6DFD3),
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
  );
  TextStyle? title(TextStyle? s) =>
      s?.copyWith(fontFamily: titleFont, fontFamilyFallback: _cjkFallback);
  final body = base.textTheme.apply(
    fontFamily: bodyFont,
    fontFamilyFallback: _cjkFallback,
    bodyColor: colors.ink,
    displayColor: colors.ink,
  );
  return base.copyWith(
    scaffoldBackgroundColor: colors.paper,
    cardColor: colors.card,
    textTheme: body.copyWith(
      displayLarge: title(body.displayLarge),
      displayMedium: title(body.displayMedium),
      displaySmall: title(body.displaySmall),
      headlineLarge: title(body.headlineLarge),
      headlineMedium: title(body.headlineMedium),
      headlineSmall: title(body.headlineSmall),
      titleLarge: title(body.titleLarge),
    ),
    extensions: [colors],
  );
}
