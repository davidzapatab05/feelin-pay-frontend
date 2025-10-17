class StringUtils {
  /// Limpia espacios en blanco y caracteres especiales de un string
  static String cleanString(String input) {
    if (input.isEmpty) return input;

    return input
        .trim() // Elimina espacios al inicio y final
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        ) // Reemplaza múltiples espacios con uno solo
        .replaceAll(
          RegExp(r'[^\w\s@.-]'),
          '',
        ) // Elimina caracteres especiales excepto @, ., -
        .trim();
  }

  /// Limpia un número de teléfono
  static String cleanPhoneNumber(String phone) {
    if (phone.isEmpty) return phone;

    return phone
        .replaceAll(RegExp(r'[^\d+]'), '') // Solo números y +
        .replaceAll(RegExp(r'\s+'), '') // Sin espacios
        .trim();
  }

  /// Limpia un email
  static String cleanEmail(String email) {
    if (email.isEmpty) return email;

    return email
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '') // Sin espacios
        .replaceAll(
          RegExp(r'[^\w@.-]'),
          '',
        ); // Solo caracteres válidos para email
  }

  /// Valida formato de email
  static bool isValidEmail(String email) {
    final cleanEmail = StringUtils.cleanEmail(email);
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(cleanEmail);
  }

  /// Valida formato de teléfono
  static bool isValidPhone(String phone) {
    final cleanPhone = StringUtils.cleanPhoneNumber(phone);
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(cleanPhone);
  }

  /// Formatea un número de teléfono para mostrar
  static String formatPhoneForDisplay(String phone) {
    final cleanPhone = StringUtils.cleanPhoneNumber(phone);
    if (cleanPhone.startsWith('+')) {
      return cleanPhone;
    }
    return '+$cleanPhone';
  }

  /// Capitaliza la primera letra de cada palabra
  static String capitalizeWords(String input) {
    if (input.isEmpty) return input;

    return input
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : word,
        )
        .join(' ');
  }
}
