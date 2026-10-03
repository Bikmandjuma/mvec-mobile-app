// Lightweight validation helpers used across the auth screens.
// Mirrors client-side checks from the MVEC web frontend.

bool isEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());

bool isPhone(String value) {
  final digits = value.replaceAll(RegExp(r'[^\d]'), '');
  return digits.length >= 9 && digits.length <= 15;
}

String? validateEmailOrPhone(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Enter your email or telephone.';
  if (v.contains('@')) {
    if (!isEmail(v)) return 'Enter a valid email address.';
  } else if (!isPhone(v)) {
    return 'Enter a valid telephone number.';
  }
  return null;
}

String? validatePhone(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Enter your telephone number.';
  if (!isPhone(v)) return 'Enter a valid telephone number.';
  return null;
}

String? validateEmail(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return null;
  if (!isEmail(v)) return 'Enter a valid email address.';
  return null;
}

String? validateFullName(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Enter your full name.';
  if (v.split(RegExp(r'\s+')).length < 2) {
    return 'Enter your first and last name.';
  }
  return null;
}

String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Enter your password.';
  if (v.length < 6) return 'Password must be at least 6 characters.';
  return null;
}

String? validateConfirmPassword(String? value, String? password) {
  if (value == null || value.isEmpty) return 'Confirm your password.';
  if (value != password) return 'Passwords do not match.';
  return null;
}

String? validateOtp(String? value) {
  final v = (value ?? '').trim();
  if (v.length != 6) return 'Enter the complete 6-digit code.';
  if (RegExp(r'^\d{6}$').hasMatch(v) == false) {
    return 'The code contains digits only.';
  }
  return null;
}