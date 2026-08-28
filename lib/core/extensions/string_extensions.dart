/// Common string manipulation extensions.
extension StringExtensions on String {
  /// Returns true if the string is empty or contains only whitespace.
  bool get isBlank => trim().isEmpty;

  /// Returns true if the string is not empty and contains non-whitespace characters.
  bool get isNotBlank => !isBlank;
}
