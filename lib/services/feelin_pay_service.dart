import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/local_database.dart';

/// Servicio principal de Feelin Pay que integra todas las funcionalidades
class FeelinPayService {
  static const String baseUrl = 'http://localhost:3001/api';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Headers comunes
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Obtener token de autenticación
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Headers con autenticación
  static Future<Map<String, String>> get _authHeaders async {
    final token = await _getToken();
    return {..._headers, if (token != null) 'Authorization': 'Bearer $token'};
  }

  // Obtener datos del usuario actual
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    return userData != null ? jsonDecode(userData) : null;
  }

  // Obtener perfil del usuario desde el backend
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Error obteniendo perfil'};
      }
    } catch (e) {
      return {'error': 'Error de conexión: $e'};
    }
  }

  // Verificar si el usuario está logueado
  static Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null;
  }

  // Register
  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'telefono': telefono,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveToken(data['token']);
        await saveUserData(data['user']);
        return {'success': true, 'user': data['user']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['error']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Guardar datos del usuario
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  // Limpiar datos del usuario
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// ===== AUTENTICACIÓN =====

  /// Login híbrido (online/offline)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Intentar login online primero
      final headers = await _authHeaders;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Guardar datos del usuario
        await saveUserData(data['user']);
        await _saveToken(data['token']);

        return {
          'success': true,
          'user': data['user'],
          'token': data['token'],
          'message': 'Login exitoso',
          'online': true,
        };
      } else {
        // Si falla online, intentar offline
        return await _loginOffline(email, password);
      }
    } catch (e) {
      // Si no hay internet, intentar offline
      return await _loginOffline(email, password);
    }
  }

  /// Login offline
  static Future<Map<String, dynamic>> _loginOffline(
    String email,
    String password,
  ) async {
    try {
      final user = await LocalDatabase.getUsuarioByEmail(email);

      if (user == null) {
        return {'success': false, 'error': 'Usuario no encontrado offline'};
      }

      // Verificar contraseña (simplificado para offline)
      if (user['password'] != password) {
        return {'success': false, 'error': 'Contraseña incorrecta'};
      }

      // Generar token offline (simplificado)
      final token = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      await _saveToken(token);

      return {
        'success': true,
        'user': user,
        'token': token,
        'message': 'Login offline exitoso',
        'offline': true,
      };
    } catch (e) {
      return {'success': false, 'error': 'Error en login offline: $e'};
    }
  }

  /// Guardar token
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      await clearUserData();
      return {'success': true, 'message': 'Logout exitoso'};
    } catch (e) {
      return {'success': false, 'error': 'Error al hacer logout: $e'};
    }
  }

  /// ===== GESTIÓN DE EMPLEADOS =====

  /// Crear empleado
  static Future<Map<String, dynamic>> crearEmpleado({
    required String propietarioId,
    required String nombre,
    required String telefono,
    String? canal,
  }) async {
    try {
      final headers = await _authHeaders;

      final response = await http.post(
        Uri.parse('$baseUrl/empleados'),
        headers: headers,
        body: jsonEncode({
          'propietarioId': propietarioId,
          'nombre': nombre,
          'telefono': telefono,
          'canal': canal ?? 'sms',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Guardar empleado localmente
        await LocalDatabase.createEmpleado({
          'propietarioId': propietarioId,
          'nombre': nombre,
          'telefono': telefono,
          'canal': canal ?? 'sms',
          'activo': true,
        });

        return {
          'success': true,
          'empleado': data['empleado'],
          'message': 'Empleado creado exitosamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error al crear empleado',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// Obtener empleados del propietario
  static Future<Map<String, dynamic>> obtenerEmpleados(
    String propietarioId,
  ) async {
    try {
      final headers = await _authHeaders;

      final response = await http.get(
        Uri.parse('$baseUrl/empleados/propietario/$propietarioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'empleados': data['empleados'],
          'total': data['total'],
        };
      } else {
        // Si falla online, obtener offline
        return await _obtenerEmpleadosOffline(propietarioId);
      }
    } catch (e) {
      // Si no hay internet, obtener offline
      return await _obtenerEmpleadosOffline(propietarioId);
    }
  }

  /// Obtener empleados offline
  static Future<Map<String, dynamic>> _obtenerEmpleadosOffline(
    String propietarioId,
  ) async {
    try {
      final empleados = await LocalDatabase.getEmpleadosByPropietario(
        propietarioId,
      );
      return {
        'success': true,
        'empleados': empleados,
        'total': empleados.length,
        'offline': true,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al obtener empleados offline: $e',
      };
    }
  }

  /// ===== PROCESAMIENTO DE PAGOS =====

  /// Procesar pago completo (validar + Google Sheets + SMS)
  static Future<Map<String, dynamic>> procesarPagoCompleto({
    required String propietarioId,
    required String nombrePagador,
    required double monto,
    required String codigoSeguridad,
    required DateTime fechaPago,
    String? telefonoPagador,
    bool notificarEmpleados = true,
  }) async {
    try {
      final headers = await _authHeaders;

      final response = await http.post(
        Uri.parse('$baseUrl/pago-integrado/procesar-pago'),
        headers: headers,
        body: jsonEncode({
          'propietarioId': propietarioId,
          'nombrePagador': nombrePagador,
          'monto': monto,
          'codigoSeguridad': codigoSeguridad,
          'fechaPago': fechaPago.toIso8601String(),
          'telefonoPagador': telefonoPagador,
          'notificarEmpleados': notificarEmpleados,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Guardar pago localmente para respaldo
        await _guardarPagoLocalmente({
          'propietarioId': propietarioId,
          'clienteNombre': nombrePagador,
          'monto': monto,
          'fecha': fechaPago.toIso8601String(),
          'codigoSeguridad': codigoSeguridad,
          'telefonoPagador': telefonoPagador,
          'notificadoEmpleados': data['data']['sms']['enviados'] > 0,
          'registradoEnSheets': data['data']['googleSheets']['registrado'],
          'sincronizado': true,
        });

        return {
          'success': true,
          'data': data['data'],
          'message': 'Pago procesado exitosamente',
          'online': true,
        };
      } else {
        // Si falla online, procesar offline
        return await _procesarPagoOffline(
          propietarioId: propietarioId,
          nombrePagador: nombrePagador,
          monto: monto,
          codigoSeguridad: codigoSeguridad,
          fechaPago: fechaPago,
          telefonoPagador: telefonoPagador,
        );
      }
    } catch (e) {
      // Si no hay internet, procesar offline
      return await _procesarPagoOffline(
        propietarioId: propietarioId,
        nombrePagador: nombrePagador,
        monto: monto,
        codigoSeguridad: codigoSeguridad,
        fechaPago: fechaPago,
        telefonoPagador: telefonoPagador,
      );
    }
  }

  /// Procesar pago offline
  static Future<Map<String, dynamic>> _procesarPagoOffline({
    required String propietarioId,
    required String nombrePagador,
    required double monto,
    required String codigoSeguridad,
    required DateTime fechaPago,
    String? telefonoPagador,
  }) async {
    try {
      // Guardar pago localmente
      await _guardarPagoLocalmente({
        'propietarioId': propietarioId,
        'clienteNombre': nombrePagador,
        'monto': monto,
        'fecha': fechaPago.toIso8601String(),
        'codigoSeguridad': codigoSeguridad,
        'telefonoPagador': telefonoPagador,
        'notificadoEmpleados': false,
        'registradoEnSheets': false,
        'sincronizado': false,
      });

      return {
        'success': true,
        'message':
            'Pago guardado localmente. Se sincronizará cuando haya internet.',
        'offline': true,
      };
    } catch (e) {
      return {'success': false, 'error': 'Error al guardar pago offline: $e'};
    }
  }

  /// Guardar pago localmente
  static Future<void> _guardarPagoLocalmente(
    Map<String, dynamic> pagoData,
  ) async {
    try {
      await LocalDatabase.createPago(pagoData);
    } catch (e) {
      print('Error al guardar pago localmente: $e');
    }
  }

  /// ===== GOOGLE SHEETS =====

  /// Obtener enlace de compartir para empleados
  static Future<Map<String, dynamic>> obtenerEnlaceCompartir(
    String propietarioId,
  ) async {
    try {
      final headers = await _authHeaders;

      final response = await http.get(
        Uri.parse('$baseUrl/pago-integrado/enlace-compartir/$propietarioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'url': data['url'],
          'message': 'Enlace obtenido exitosamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error al obtener enlace',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// ===== ESTADÍSTICAS =====

  /// Obtener estadísticas del propietario
  static Future<Map<String, dynamic>> obtenerEstadisticas(
    String propietarioId,
  ) async {
    try {
      // Intentar obtener online primero
      final headers = await _authHeaders;

      final response = await http.get(
        Uri.parse('$baseUrl/pago-integrado/verificar-saldo-sms/$propietarioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'saldoDisponible': data['saldoDisponible'],
          'empleadosActivos': data['empleadosActivos'],
          'online': true,
        };
      }
    } catch (e) {
      // Si falla online, obtener offline
    }

    // Obtener estadísticas offline
    try {
      final estadisticas = await LocalDatabase.getEstadisticasPagos(
        propietarioId,
      );
      return {'success': true, 'estadisticas': estadisticas, 'offline': true};
    } catch (e) {
      return {'success': false, 'error': 'Error al obtener estadísticas: $e'};
    }
  }

  /// ===== SINCRONIZACIÓN =====

  /// Sincronizar pagos pendientes
  static Future<Map<String, dynamic>> sincronizarPagosPendientes(
    String propietarioId,
  ) async {
    try {
      final headers = await _authHeaders;

      final response = await http.post(
        Uri.parse('$baseUrl/pago-integrado/sincronizar/$propietarioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'sincronizados': data['sincronizados'],
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error al sincronizar',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// ===== BOTÓN DE PRUEBAS =====

  /// Procesar pago de prueba (sin Yape real)
  static Future<Map<String, dynamic>> procesarPagoPrueba({
    required String propietarioId,
    String nombrePagador = 'Cliente de Prueba',
    double monto = 25.50,
    String codigoSeguridad = 'TEST123',
    String telefonoPagador = '+51987654321',
  }) async {
    try {
      final headers = await _authHeaders;

      final response = await http.post(
        Uri.parse('$baseUrl/test/procesar-pago-prueba/$propietarioId'),
        headers: headers,
        body: jsonEncode({
          'nombrePagador': nombrePagador,
          'monto': monto,
          'codigoSeguridad': codigoSeguridad,
          'telefonoPagador': telefonoPagador,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Guardar pago localmente para respaldo
        await _guardarPagoLocalmente({
          'propietarioId': propietarioId,
          'clienteNombre': nombrePagador,
          'monto': monto,
          'fecha': DateTime.now().toIso8601String(),
          'codigoSeguridad': codigoSeguridad,
          'telefonoPagador': telefonoPagador,
          'notificadoEmpleados': data['data']['sms']['enviados'] > 0,
          'registradoEnSheets': data['data']['googleSheets']['registrado'],
          'sincronizado': true,
        });

        return {
          'success': true,
          'data': data['data'],
          'message': 'Pago de prueba procesado exitosamente',
          'esPrueba': true,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error al procesar pago de prueba',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// Verificar si se puede usar el botón de prueba
  static Future<Map<String, dynamic>> verificarBotonPrueba(
    String propietarioId,
  ) async {
    try {
      final headers = await _authHeaders;

      final response = await http.get(
        Uri.parse('$baseUrl/test/verificar-boton-prueba/$propietarioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'puedeUsar': data['puedeUsar'],
          'ilimitado': data['ilimitado'] ?? false,
          'razon': data['razon'],
          'fechaUso': data['fechaUso'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error al verificar botón de prueba',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// ===== ACCESO DE EMPLEADOS =====

  /// Obtener enlace de Google Sheets para empleados (público)
  static Future<Map<String, dynamic>> obtenerEnlaceGoogleSheetsEmpleados(
    String propietarioId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/empleado-access/google-sheets/$propietarioId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'url': data['url'],
          'accessType': data['accessType'],
          'description': data['description'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error al obtener enlace',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// Verificar acceso de empleado
  static Future<Map<String, dynamic>> verificarAccesoEmpleado(
    String empleadoId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/empleado-access/verificar/$empleadoId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'acceso': data['acceso'],
          'empleado': data['empleado'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error al verificar acceso',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // ==================== MÉTODOS OTP ====================

  /// Verificar código OTP
  static Future<Map<String, dynamic>> verificarCodigoOTP(
    String userId,
    String codigo,
  ) async {
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        Uri.parse('$baseUrl/otp/verificar-codigo'),
        headers: headers,
        body: jsonEncode({'usuarioId': userId, 'codigo': codigo}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Código verificado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Error verificando código',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Reenviar código OTP
  static Future<Map<String, dynamic>> reenviarCodigoOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/otp/reenviar'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Código reenviado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Error reenviando código',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Solicitar recuperación de contraseña
  static Future<Map<String, dynamic>> solicitarRecuperacionPassword(
    String email,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/otp/recuperar-password'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Código de recuperación enviado',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Error enviando código',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Cambiar contraseña con código OTP
  static Future<Map<String, dynamic>> cambiarPasswordConCodigo(
    String email,
    String codigo,
    String nuevaPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/otp/cambiar-password'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'codigo': codigo,
          'nuevaPassword': nuevaPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Contraseña cambiada correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Error cambiando contraseña',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Gestión de usuarios
  static Future<Map<String, dynamic>> obtenerUsuarios({
    String busqueda = '',
    String rol = '',
    String activo = 'true',
    int pagina = 1,
    int limite = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'busqueda': busqueda,
        'rol': rol,
        'activo': activo,
        'pagina': pagina.toString(),
        'limite': limite.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/api/admin/usuarios',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _authHeaders);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'usuarios': data['usuarios'],
          'paginacion': data['paginacion'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error obteniendo usuarios',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> crearUsuario(
    String nombre,
    String email,
    String telefono,
    String password,
    String rol,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/usuarios'),
        headers: await _authHeaders,
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'telefono': telefono,
          'password': password,
          'rol': rol,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Usuario creado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error creando usuario',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> eliminarUsuario(String usuarioId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/usuarios/$usuarioId'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Usuario eliminado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error eliminando usuario',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> reactivarUsuario(String usuarioId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/admin/usuarios/$usuarioId/reactivar'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Usuario reactivado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error reactivando usuario',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Google Sheets
  static Future<Map<String, dynamic>> obtenerConfiguracionSheets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reportes/sheets-config'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'configuracion': data['configuracion']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error obteniendo configuración',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> abrirGoogleSheets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reportes/abrir-sheets'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'url': data['url']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error abriendo Google Sheets',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> compartirGoogleSheets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reportes/compartir-sheets'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'url': data['url']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error obteniendo enlace de compartir',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Llenar Google Sheets con datos de prueba
  static Future<Map<String, dynamic>> llenarDatosPrueba() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/reportes/llenar-datos-prueba'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error llenando datos de prueba',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Crear estructura de Google Sheets
  static Future<Map<String, dynamic>> crearEstructuraSheets() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/reportes/crear-estructura'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error creando estructura',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Llenar Google Sheets automáticamente con pago de prueba
  static Future<Map<String, dynamic>> llenarAutomaticamente({
    required String pagador,
    required double monto,
    required String codigoSeguridad,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/reportes/llenar-automatico'),
        headers: await _authHeaders,
        body: jsonEncode({
          'pagador': pagador,
          'monto': monto,
          'codigoSeguridad': codigoSeguridad,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error llenando automáticamente',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // ========== MÉTODOS DE CONFIGURACIÓN DE PERFIL ==========

  // Obtener perfil del usuario
  static Future<Map<String, dynamic>> obtenerPerfil() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/profile'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'usuario': data['usuario']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error obteniendo perfil',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Actualizar nombre del usuario
  static Future<Map<String, dynamic>> actualizarNombre(String nombre) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/profile/profile/name'),
        headers: await _authHeaders,
        body: jsonEncode({'nombre': nombre}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Nombre actualizado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error actualizando nombre',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Actualizar teléfono del usuario
  static Future<Map<String, dynamic>> actualizarTelefono(
    String telefono,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/profile/profile/phone'),
        headers: await _authHeaders,
        body: jsonEncode({'telefono': telefono}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Teléfono actualizado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error actualizando teléfono',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Cambiar contraseña del usuario
  static Future<Map<String, dynamic>> cambiarPassword(
    String passwordActual,
    String passwordNueva,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/profile/profile/password'),
        headers: await _authHeaders,
        body: jsonEncode({
          'passwordActual': passwordActual,
          'passwordNueva': passwordNueva,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Contraseña actualizada correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error cambiando contraseña',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Solicitar cambio de email
  static Future<Map<String, dynamic>> solicitarCambioEmail(
    String nuevoEmail,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/profile/profile/email/request'),
        headers: await _authHeaders,
        body: jsonEncode({'nuevoEmail': nuevoEmail}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message':
              data['message'] ??
              'Código de verificación enviado al nuevo email',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error solicitando cambio de email',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Confirmar cambio de email con OTP
  static Future<Map<String, dynamic>> confirmarCambioEmail(
    String codigo,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/profile/profile/email/confirm'),
        headers: await _authHeaders,
        body: jsonEncode({'codigo': codigo}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Email actualizado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error confirmando cambio de email',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Obtener historial de cambios del perfil
  static Future<Map<String, dynamic>> obtenerHistorialPerfil({
    int pagina = 1,
    int limite = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'pagina': pagina.toString(),
        'limite': limite.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/api/profile/profile/history',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _authHeaders);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'historial': data['historial'],
          'paginacion': data['paginacion'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error obteniendo historial',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }
}
