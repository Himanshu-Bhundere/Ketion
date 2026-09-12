import 'package:flutter/material.dart';

/// Canonical radius tokens as defined in the UI architecture.
class AppRadius {
  const AppRadius._();

  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 16.0;

  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(large));
}
