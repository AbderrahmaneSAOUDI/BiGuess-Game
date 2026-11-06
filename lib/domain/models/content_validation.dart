import 'dart:convert';

/// Shared boundary checks for canonical content. IDs are opaque, case-sensitive
/// values supplied by the content source; names are never used to generate IDs.
class ContentValidation {
  ContentValidation._();

  static String id(String value, String field) {
    if (value.isEmpty ||
        RegExp(r'\s|[\x00-\x1f\x7f]').hasMatch(value) ||
        !_isUtf8(value)) {
      throw ArgumentError.value(value, field, 'Expected a nonblank opaque ID');
    }
    return value;
  }

  static String text(String value, String field) {
    if (value.isEmpty ||
        value.trim() != value ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(value) ||
        !_isUtf8(value)) {
      throw ArgumentError.value(
        value,
        field,
        'Expected nonempty trimmed UTF-8 text without controls',
      );
    }
    return value;
  }

  // Dart strings can contain unpaired UTF-16 surrogates. UTF-8 encoders replace
  // those code units, which would change canonical identities or display text.
  static bool _isUtf8(String value) => utf8.decode(utf8.encode(value)) == value;

  static int revision(int value) {
    if (value < 1) {
      throw RangeError.range(value, 1, null, 'revision');
    }
    return value;
  }

  static String readString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! String) {
      throw FormatException('Expected a string for $field');
    }
    return value;
  }

  static int readRevision(Map<String, dynamic> json) {
    if (!json.containsKey('revision')) return 1;
    final value = json['revision'];
    if (value is! int) {
      throw const FormatException('Expected an integer for revision');
    }
    return value;
  }

  static bool readBool(Map<String, dynamic> json, String field) {
    if (!json.containsKey(field)) return false;
    final value = json[field];
    if (value is! bool) {
      throw FormatException('Expected a boolean for $field');
    }
    return value;
  }
}
