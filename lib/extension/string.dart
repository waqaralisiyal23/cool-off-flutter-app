/// Extension methods on [String].
extension XString on String {
  /// Capitalizes the first letter of the string.
  ///
  /// Example: `'hello'.capitalize` -> `'Hello'`
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
