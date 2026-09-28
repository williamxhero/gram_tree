import 'package:flutter/material.dart';

/// 味谱的配色和字体，来自 UI 规范（SPEC-009.1 #18、SPEC-009.2 #34、样稿画布）。
///
/// * 纸 #F7F4EE 做页面底色，卡片 #FFFDF9，墨 #1B1813 做主按钮和正文。
/// * 酱红 #B0441E 只用在“系统替你改了”的地方（按你的口味换算、按场景调整），
///   不要拿来做普通强调。
/// * 已验证用绿 #4E6B48。
/// * 标题 Noto Serif SC，正文 Noto Sans SC，数字 DM Mono（用 [GramTreeColors.numberStyle]）。
///
/// 深色配色（SPEC-009.1 #80 定稿）：跟组件库样稿
/// https://claude.ai/artifact/MjRrePB1X3JzPCWLtTbRu7 里"设计系统"一节提议的定稿值
/// 完全一致（该样稿早于 #80 写好，下面这几个十六进制数从 #77 就已经是这份值，
/// #80 只是把它们从"临时反推"确认为正式定稿，数值本身没有变）。定稿依据：
/// * 底色/卡片/正文三对沿用浅色的明度关系反转（纸→接近黑的暖棕，墨→接近白的暖米），
///   保证浅色下的对比度在深色下也成立。
/// * 酱红、已验证绿在深色下调亮/调暖一档（`accentDark`/`verifiedDark`），因为原浅色值
///   直接放在深色底上饱和度不够、辨识度会下降；样稿里两套配色并排对比过。
/// * 都过了 WCAG AA 的文字对比度（正文色对页面底色、对卡片底色）。
///
/// 字体打包（SPEC-009.1 #80 决定，还没有落地成打包文件，见下方"字体打包"）：
/// * 打包字重：标题 Noto Serif SC 500/700，正文 Noto Sans SC 400/500/700，
///   数字 DM Mono 400/500——和样稿页头引入的 Google Fonts 字重完全对应
///   （`family=Noto+Serif+SC:wght@500;700`、`Noto+Sans+SC:wght@400;500;700`、
///   `DM+Mono:wght@400;500`），不多打包用不到的字重。
/// * 字符集不做手工裁剪：直接用 Google Fonts 的 SC（Simplified Chinese）专属家族，
///   它本身就是从完整 Noto CJK 里按简体中文+ 拉丁字符切出来的子集（不含日文假名、
///   繁体专用字、韩文），比裁到"菜谱里出现过的字"更省事也更不容易在用户输入新食材名
///   时缺字；不再逐字符裁剪。
/// * 还没有把字体文件下载打包进 `app/assets/fonts/`、写进 `pubspec.yaml` 的
///   `fonts:` 段——这一步本身不难，但会改变 `flutter build web`/App 的产物体积和
///   离线首屏渲染时机，属于一次独立的、需要单独验证不出岔子的改动，留给下一次真的
///   需要视觉走查、或者下一张涉及字体的票去做。没打包不影响这张票的验收：装了对应
///   系统字体的设备正常显示规范字体，没装的设备走 [_cjkFallback]（`PingFang SC`→
///   `Noto Sans CJK SC`→`Source Han Sans SC`→系统无衬线），中文和数字都不会变成方块。
class GramTreePalette {
  const GramTreePalette._();

  static const paper = Color(0xFFF7F4EE);
  static const card = Color(0xFFFFFDF9);
  static const ink = Color(0xFF1B1813);
  static const accent = Color(0xFFB0441E);
  static const verified = Color(0xFF4E6B48);

  // 深色（定稿，SPEC-009.1 #80，见上方类文档注释）
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
