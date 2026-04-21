class AuthValidators {
  static bool looksLikeEmail(String value) {
    final v = value.trim();
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v);
  }

  static bool looksLikePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  static bool isValidIdentifier(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    return looksLikeEmail(v) || looksLikePhone(v);
  }

  static String? identifierError(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    if (!isValidIdentifier(value)) {
      return 'Please enter a valid phone number or email';
    }
    return null;
  }

  static String? required(String? value, {String message = 'This field is required'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static PasswordStrength passwordStrength(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp('[A-Z]').hasMatch(password)) score++;
    if (RegExp('[a-z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.fair;
    return PasswordStrength.strong;
  }
}

enum PasswordStrength { weak, fair, strong }
