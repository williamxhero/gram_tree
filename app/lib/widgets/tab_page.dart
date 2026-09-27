import 'package:flutter/material.dart';

/// Page frame for a bottom-bar tab. The bottom bar itself lives in the shell.
class TabPage extends StatelessWidget {
  const TabPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: SafeArea(bottom: false, child: child));
}
