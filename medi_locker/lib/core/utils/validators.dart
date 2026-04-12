/// Form field validators — use directly in TextFormField.validator.
class Validators {
  Validators._();

  static String? required(String? v, [String field = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your email';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!regex.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Enter a password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? Function(String?) confirmPassword(String original) {
    return (String? v) {
      if (v == null || v.isEmpty) return 'Confirm your password';
      if (v != original) return 'Passwords do not match';
      return null;
    };
  }

  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your name';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.isEmpty) return null; // Optional field
    if (v.length < 7) return 'Enter a valid phone number';
    return null;
  }
}
