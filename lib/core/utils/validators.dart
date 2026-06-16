class Validators {
  Validators._();

  static String? requiredName(String? value, {required String fieldName}) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return '$fieldName is required.';
    }
    if (name.length < 2) {
      return '$fieldName must contain at least 2 characters.';
    }
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (email.isEmpty) {
      return 'Email is required.';
    }
    if (!emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? optionalPhoneNumber(String? value) {
    final phoneNumber = value?.trim() ?? '';
    final phonePattern = RegExp(r'^\+?[0-9\s()-]{7,20}$');

    if (phoneNumber.isNotEmpty && !phonePattern.hasMatch(phoneNumber)) {
      return 'Enter a valid telephone number.';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < 6) {
      return 'Password must contain at least 6 characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) {
      return 'Confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }
}
