import 'package:flutter/material.dart';

/// Common BuildContext extensions for easier access to Theme and MediaQueries.
extension ContextExtensions on BuildContext {
  /// Quick access to Theme.of(this)
  ThemeData get theme => Theme.of(this);

  /// Quick access to Theme.of(this).colorScheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Quick access to Theme.of(this).textTheme
  TextTheme get textTheme => theme.textTheme;

  /// Quick access to MediaQuery.of(this).size
  Size get screenSize => MediaQuery.sizeOf(this);
}
