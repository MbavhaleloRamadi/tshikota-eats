class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
      return 'Enter a valid email';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Minimum 6 characters';
    }

    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    if (!RegExp(r'^\+?[0-9]{10,13}$').hasMatch(value.replaceAll(' ', ''))) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }

    final parsed = double.tryParse(value);

    if (parsed == null || parsed <= 0) {
      return 'Enter a valid price';
    }

    return null;
  }

  static String sanitize(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'[<>"\x27]'), '')
        .trim();
  }
}
