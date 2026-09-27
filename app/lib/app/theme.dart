import 'package:flutter/material.dart';

/// Warm seed color shared by the light and dark themes.
const seedColor = Color(0xFFD9772B);

ThemeData buildTheme(Brightness brightness) => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  ),
);
