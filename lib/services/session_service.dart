import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SessionService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _sessionKey = 'session_active';
  static const String _lastActivityKey = 'last_activity';

  // Guardar token de autenticación
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setBool(_sessionKey, true);
    await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());
  }

  // Obtener token de autenticación
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Guardar datos del usuario
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
    await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());
  }

  // Obtener datos del usuario
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      return jsonDecode(userString);
    }
    return null;
  }

  // Verificar si hay sesión activa
  static Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final hasToken = prefs.getString(_tokenKey) != null;
    final isActive = prefs.getBool(_sessionKey) ?? false;
    return hasToken && isActive;
  }

  // Actualizar última actividad
  static Future<void> updateLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());
  }

  // Obtener última actividad
  static Future<DateTime?> getLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivityString = prefs.getString(_lastActivityKey);
    if (lastActivityString != null) {
      return DateTime.parse(lastActivityString);
    }
    return null;
  }

  // Verificar si la sesión ha expirado (opcional, para casos específicos)
  static Future<bool> isSessionExpired({
    Duration maxInactivity = const Duration(days: 30),
  }) async {
    final lastActivity = await getLastActivity();
    if (lastActivity == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastActivity);
    return difference > maxInactivity;
  }

  // Mantener sesión activa (llamar periódicamente)
  static Future<void> keepSessionAlive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());
  }

  // Cerrar sesión (solo cuando el usuario presiona logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.setBool(_sessionKey, false);
    await prefs.remove(_lastActivityKey);
  }

  // Verificar si el usuario está logueado
  static Future<bool> isLoggedIn() async {
    final hasSession = await hasActiveSession();
    if (!hasSession) return false;

    // Verificar que el token no haya expirado (opcional)
    final isExpired = await isSessionExpired();
    if (isExpired) {
      await logout();
      return false;
    }

    return true;
  }

  // Obtener información de la sesión
  static Future<Map<String, dynamic>> getSessionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userString = prefs.getString(_userKey);
    final isActive = prefs.getBool(_sessionKey) ?? false;
    final lastActivityString = prefs.getString(_lastActivityKey);

    Map<String, dynamic>? user;
    if (userString != null) {
      user = jsonDecode(userString);
    }

    DateTime? lastActivity;
    if (lastActivityString != null) {
      lastActivity = DateTime.parse(lastActivityString);
    }

    return {
      'hasToken': token != null,
      'hasUser': user != null,
      'isActive': isActive,
      'lastActivity': lastActivity,
      'user': user,
    };
  }
}
