import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../core/config/app_config.dart';

/// API Service - Servicio simple para comunicación con backend
class ApiService {
  static const String baseUrl = AppConfig.apiBaseUrl;

  // Headers
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Obtener token almacenado
  Future<String?> getStoredToken() async {
    // Implementación simple - en producción usar SharedPreferences
    return null;
  }

  /// Obtener usuario actual
  Future<UserModel?> getCurrentUser() async {
    try {
      final token = await getStoredToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {..._headers, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return UserModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔍 [API] Intentando login para: $email');

      // Crear el body manualmente para evitar problemas de serialización
      final requestBody = '{"email":"${email.trim()}","password":"$password"}';
      print('🔍 [API] Request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: requestBody,
      );

      print('🔍 [API] Response status: ${response.statusCode}');
      print('🔍 [API] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 [API] Login exitoso');
        return data;
      } else {
        print('❌ [API] Error en login: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [API] Error en login: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Register
  Future<Map<String, dynamic>> register({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      print('🔍 [API] Intentando registro para: $email');

      // Crear el body manualmente para evitar problemas de serialización
      final requestBody =
          '{"nombre":"${nombre.trim()}","telefono":"${telefono.trim()}","email":"${email.trim()}","password":"$password","confirmPassword":"$confirmPassword"}';
      print('🔍 [API] Request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: requestBody,
      );

      print('🔍 [API] Response status: ${response.statusCode}');
      print('🔍 [API] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('🔍 [API] Registro exitoso');
        return data;
      } else {
        print('❌ [API] Error en registro: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [API] Error en registro: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Logout
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Forgot Password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      print('🔍 [API] Intentando forgot password para: $email');

      // Crear el body manualmente para evitar problemas de serialización
      final requestBody = '{"email":"${email.trim()}"}';
      print('🔍 [API] Request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: _headers,
        body: requestBody,
      );

      print('🔍 [API] Response status: ${response.statusCode}');
      print('🔍 [API] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 [API] Forgot password exitoso');
        return data;
      } else {
        print('❌ [API] Error en forgot password: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [API] Error en forgot password: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Send OTP
  Future<Map<String, dynamic>> sendOTP(String email, String tipo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/otp/send'),
        headers: _headers,
        body: jsonEncode({'email': email, 'tipo': tipo}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Get payments
  Future<Map<String, dynamic>> getPayments({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments?page=$page&limit=$limit'),
        headers: _headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Get payment statistics
  Future<Map<String, dynamic>> getPaymentStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/stats'),
        headers: _headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Create payment
  Future<Map<String, dynamic>> createPayment({
    required String nombrePagador,
    required double monto,
    required DateTime fecha,
    String? codigoSeguridad,
    String? numeroTelefono,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: _headers,
        body: jsonEncode({
          'nombrePagador': nombrePagador,
          'monto': monto,
          'fecha': fecha.toIso8601String(),
          'codigoSeguridad': codigoSeguridad,
          'numeroTelefono': numeroTelefono,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Update payment
  Future<Map<String, dynamic>> updatePayment({
    required String paymentId,
    String? nombrePagador,
    double? monto,
    DateTime? fecha,
    String? codigoSeguridad,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: _headers,
        body: jsonEncode({
          'nombrePagador': nombrePagador,
          'monto': monto,
          'fecha': fecha?.toIso8601String(),
          'codigoSeguridad': codigoSeguridad,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Verificar OTP
  Future<bool> verifyOTP(String email, String code, String type) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: _headers,
        body: jsonEncode({'email': email, 'code': code, 'type': type}),
      );

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Delete payment
  Future<Map<String, dynamic>> deletePayment(String paymentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: _headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Get payments by date range
  Future<Map<String, dynamic>> getPaymentsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/payments/date-range?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}',
        ),
        headers: _headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// ===== GESTIÓN DE USUARIOS (Solo Super Admin) =====

  /// Get all users with filters
  Future<Map<String, dynamic>> getAllUsers({
    String search = '',
    String role = '',
    String status = '',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'search': search,
        'role': role,
        'status': status,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/api/user-management',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error obteniendo usuarios',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Get user by ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user-management/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error obteniendo usuario',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Create new user
  Future<Map<String, dynamic>> createUser({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    required String rolId,
    bool activo = true,
    bool licenciaActiva = false,
    int diasPruebaRestantes = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/user-management'),
        headers: _headers,
        body: jsonEncode({
          'nombre': nombre,
          'telefono': telefono,
          'email': email,
          'password': password,
          'rolId': rolId,
          'activo': activo,
          'licenciaActiva': licenciaActiva,
          'diasPruebaRestantes': diasPruebaRestantes,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error creando usuario',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Update user
  Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? nombre,
    String? telefono,
    String? email,
    String? rolId,
    bool? activo,
    bool? licenciaActiva,
    int? diasPruebaRestantes,
    bool? emailVerificado,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (nombre != null) body['nombre'] = nombre;
      if (telefono != null) body['telefono'] = telefono;
      if (email != null) body['email'] = email;
      if (rolId != null) body['rolId'] = rolId;
      if (activo != null) body['activo'] = activo;
      if (licenciaActiva != null) body['licenciaActiva'] = licenciaActiva;
      if (diasPruebaRestantes != null)
        body['diasPruebaRestantes'] = diasPruebaRestantes;
      if (emailVerificado != null) body['emailVerificado'] = emailVerificado;

      final response = await http.put(
        Uri.parse('$baseUrl/api/user-management/$userId'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error actualizando usuario',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Toggle user status (activate/deactivate)
  Future<Map<String, dynamic>> toggleUserStatus({
    required String userId,
    required bool activo,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/user-management/$userId/toggle-status'),
        headers: _headers,
        body: jsonEncode({'activo': activo}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error cambiando estado del usuario',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Change user password (Super Admin only)
  Future<Map<String, dynamic>> changeUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/user-management/$userId/password'),
        headers: _headers,
        body: jsonEncode({'newPassword': newPassword}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error cambiando contraseña',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Change user email (Super Admin only - no verification required)
  Future<Map<String, dynamic>> changeUserEmail({
    required String userId,
    required String newEmail,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/user-management/$userId/email'),
        headers: _headers,
        body: jsonEncode({'newEmail': newEmail}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error cambiando email',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Deactivate user (instead of delete)
  Future<Map<String, dynamic>> deactivateUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/user-management/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error desactivando usuario',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Get all available roles
  Future<Map<String, dynamic>> getAllRoles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user-management/roles'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error obteniendo roles',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user-management/stats'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error obteniendo estadísticas',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
