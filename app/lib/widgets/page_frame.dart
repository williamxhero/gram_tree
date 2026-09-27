import 'package:flutter/material.dart';

/// 表单、说明类页面的框架：内容可以滚动，大字号下不溢出；主要操作放在内容末尾。
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    this.title,
    required this.content,
    this.actions = const [],
    this.showBack = false,
  });

  /// 顶栏标题；为 null 且不需要返回按钮时不显示顶栏。
  final String? title;
  final List<Widget> content;

  /// 页面底部的按钮，从上到下排列。
  final List<Widget> actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final hasBar = title != null || showBack;
    return Scaffold(
      appBar: hasBar
          ? AppBar(
              title: title == null ? null : Text(title!),
              backgroundColor: Colors.transparent,
              scrolledUnderElevation: 0,
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, hasBar ? 8 : 28, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._spaced(content),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 32),
                ..._spaced(actions, gap: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static List<Widget> _spaced(List<Widget> items, {double gap = 16}) => [
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) SizedBox(height: gap),
      items[i],
    ],
  ];
}

/// 页面大标题（宋体）。
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key, this.eyebrow});

  final String text;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!,
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(text, style: theme.textTheme.headlineSmall),
      ],
    );
  }
}

/// 一段说明文字。
class BodyText extends StatelessWidget {
  const BodyText(this.text, {super.key, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        height: 1.7,
        color: muted ? theme.colorScheme.onSurfaceVariant : null,
      ),
    );
  }
}

/// 卡片：一个小标签加几条要点。
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, this.label, required this.lines});

  final String? label;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
            ],
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 9, right: 10),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(child: BodyText(line)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 主按钮（墨色、整行宽）。
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    onPressed: busy ? null : onPressed,
    child: busy
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label, textAlign: TextAlign.center),
  );
}

/// 次要按钮（描边或纯文字）。
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.quiet = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
    );
    final child = Text(label, textAlign: TextAlign.center);
    return quiet
        ? TextButton(style: style, onPressed: onPressed, child: child)
        : OutlinedButton(style: style, onPressed: onPressed, child: child);
  }
}

/// 出错提示（验证码不对、发送太频繁等）。
class ErrorText extends StatelessWidget {
  const ErrorText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      key: const ValueKey('error-text'),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
        height: 1.6,
      ),
    );
  }
}

/// 一行“名称 + 值”。平常值在右侧；字号很大时右侧放不下，值换到名称下面。
class ValueTile extends StatelessWidget {
  const ValueTile({
    super.key,
    required this.title,
    this.value,
    this.onTap,
    this.color,
  });

  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final large = MediaQuery.textScalerOf(context).scale(10) > 15;
    final v = value == null
        ? null
        : Text(
            value!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
    final arrow = onTap == null ? null : const Icon(Icons.chevron_right);
    return ListTile(
      title: Text(title, style: color == null ? null : TextStyle(color: color)),
      subtitle: large ? v : null,
      trailing: large ? arrow : (v ?? arrow),
      onTap: onTap,
    );
  }
}
