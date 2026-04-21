import 'package:flutter/material.dart';

extension BuildContextThemeX on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;

  ColorScheme get colors => Theme.of(this).colorScheme;
}
