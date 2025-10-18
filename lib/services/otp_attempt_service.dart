import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OTPAttemptService {
  static const String _attemptsKey = 'otp_attempts';
  static const int _maxAttempts = 3;

  // Obtener intentos restantes para un email
  static Future<int> getRemainingAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsData = prefs.getString('${_attemptsKey}_$email');

    if (attemptsData == null) {
      return _maxAttempts;
    }

    final data = jsonDecode(attemptsData);
    final lastReset = DateTime.parse(data['lastReset']);
    final now = DateTime.now();

    // Verificar si es un nuevo día
    if (_shouldResetAttempts(lastReset, now)) {
      await _resetAttempts(email);
      return _maxAttempts;
    }

    return data['attemptsLeft'] ?? _maxAttempts;
  }

  // Registrar un intento fallido
  static Future<bool> recordFailedAttempt(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsData = prefs.getString('${_attemptsKey}_$email');

    int attemptsLeft = _maxAttempts;
    DateTime lastReset = DateTime.now();

    if (attemptsData != null) {
      final data = jsonDecode(attemptsData);
      attemptsLeft = data['attemptsLeft'] ?? _maxAttempts;
      lastReset = DateTime.parse(data['lastReset']);

      // Verificar si es un nuevo día
      if (_shouldResetAttempts(lastReset, DateTime.now())) {
        await _resetAttempts(email);
        attemptsLeft = _maxAttempts;
      }
    }

    if (attemptsLeft <= 0) {
      return false; // No hay intentos disponibles
    }

    attemptsLeft--;

    final newData = {
      'attemptsLeft': attemptsLeft,
      'lastReset': lastReset.toIso8601String(),
      'lastAttempt': DateTime.now().toIso8601String(),
    };

    await prefs.setString('${_attemptsKey}_$email', jsonEncode(newData));
    return attemptsLeft > 0;
  }

  // Verificar si se deben resetear los intentos
  static bool _shouldResetAttempts(DateTime lastReset, DateTime now) {
    // Si es un nuevo día (después de medianoche)
    if (now.day != lastReset.day ||
        now.month != lastReset.month ||
        now.year != lastReset.year) {
      return true;
    }

    // Si han pasado más de 24 horas
    return now.difference(lastReset).inHours >= 24;
  }

  // Resetear intentos para un email
  static Future<void> _resetAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final resetData = {
      'attemptsLeft': _maxAttempts,
      'lastReset': now.toIso8601String(),
      'lastAttempt': null,
    };

    await prefs.setString('${_attemptsKey}_$email', jsonEncode(resetData));
  }

  // Resetear todos los intentos (para limpieza diaria)
  static Future<void> resetAllAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (key) => key.startsWith('${_attemptsKey}_'),
    );

    for (final key in keys) {
      final email = key.replaceFirst('${_attemptsKey}_', '');
      await _resetAttempts(email);
    }
  }

  // Verificar si un usuario puede intentar OTP
  static Future<bool> canAttemptOTP(String email) async {
    final attemptsLeft = await getRemainingAttempts(email);
    return attemptsLeft > 0;
  }

  // Obtener información de intentos
  static Future<Map<String, dynamic>> getAttemptsInfo(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsData = prefs.getString('${_attemptsKey}_$email');

    if (attemptsData == null) {
      return {
        'attemptsLeft': _maxAttempts,
        'canAttempt': true,
        'lastAttempt': null,
        'nextReset': null,
      };
    }

    final data = jsonDecode(attemptsData);
    final lastReset = DateTime.parse(data['lastReset']);
    final now = DateTime.now();

    // Verificar si es un nuevo día
    if (_shouldResetAttempts(lastReset, now)) {
      await _resetAttempts(email);
      return {
        'attemptsLeft': _maxAttempts,
        'canAttempt': true,
        'lastAttempt': null,
        'nextReset': null,
      };
    }

    final attemptsLeft = data['attemptsLeft'] ?? _maxAttempts;
    final nextReset = lastReset.add(const Duration(days: 1));

    return {
      'attemptsLeft': attemptsLeft,
      'canAttempt': attemptsLeft > 0,
      'lastAttempt': data['lastAttempt'] != null
          ? DateTime.parse(data['lastAttempt'])
          : null,
      'nextReset': nextReset,
    };
  }

  // Limpiar datos de intentos para un email específico
  static Future<void> clearAttemptsForEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_attemptsKey}_$email');
  }

  // Obtener estadísticas de intentos
  static Future<Map<String, dynamic>> getAttemptsStats() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (key) => key.startsWith('${_attemptsKey}_'),
    );

    int totalUsers = 0;
    int usersWithAttempts = 0;
    int usersBlocked = 0;

    for (final key in keys) {
      totalUsers++;
      final attemptsData = prefs.getString(key);
      if (attemptsData != null) {
        final data = jsonDecode(attemptsData);
        final attemptsLeft = data['attemptsLeft'] ?? _maxAttempts;

        if (attemptsLeft < _maxAttempts) {
          usersWithAttempts++;
        }
        if (attemptsLeft <= 0) {
          usersBlocked++;
        }
      }
    }

    return {
      'totalUsers': totalUsers,
      'usersWithAttempts': usersWithAttempts,
      'usersBlocked': usersBlocked,
      'maxAttempts': _maxAttempts,
    };
  }
}
