import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/local_database.dart';

class SMSService {
  static const String _baseUrl = 'http://localhost:3001/api';

  // Enviar SMS a empleados sobre nuevo pago
  static Future<Map<String, dynamic>> enviarSMSAPago({
    required String empleadoId,
    required String pagoId,
    required String mensaje,
    required String numeroDestino,
  }) async {
    try {
      // Crear registro de SMS en base de datos local
      final smsId = await LocalDatabase.createSMS({
        'empleadoId': empleadoId,
        'pagoId': pagoId,
        'mensaje': mensaje,
        'numeroDestino': numeroDestino,
        'enviado': false,
      });

      // Intentar envío real de SMS
      final response = await http.post(
        Uri.parse('$_baseUrl/sms/enviar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'numero': numeroDestino,
          'mensaje': mensaje,
          'empleadoId': empleadoId,
          'pagoId': pagoId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success']) {
          // Marcar SMS como enviado
          await LocalDatabase.marcarSMSEnviado(smsId);

          return {
            'success': true,
            'message': 'SMS enviado correctamente',
            'smsId': smsId,
          };
        } else {
          // Marcar SMS con error
          await LocalDatabase.marcarSMSEnviado(smsId, error: data['error']);

          return {'success': false, 'error': data['error'], 'smsId': smsId};
        }
      } else {
        // Marcar SMS con error
        await LocalDatabase.marcarSMSEnviado(
          smsId,
          error: 'Error HTTP: ${response.statusCode}',
        );

        return {
          'success': false,
          'error': 'Error HTTP: ${response.statusCode}',
          'smsId': smsId,
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Enviar SMS masivo a todos los empleados
  static Future<Map<String, dynamic>> enviarSMSMasivo({
    required String propietarioId,
    required String mensaje,
  }) async {
    try {
      // Obtener empleados del propietario
      final empleados = await LocalDatabase.getEmpleadosByPropietario(
        propietarioId,
      );

      if (empleados.isEmpty) {
        return {'success': false, 'error': 'No hay empleados registrados'};
      }

      int enviados = 0;
      int errores = 0;
      final List<String> erroresDetalle = [];

      for (var empleado in empleados) {
        final numeroCompleto =
            '${empleado['paisCodigo']}${empleado['telefono']}';

        final resultado = await enviarSMSAPago(
          empleadoId: empleado['id'],
          pagoId: '', // No hay pago específico en SMS masivo
          mensaje: mensaje,
          numeroDestino: numeroCompleto,
        );

        if (resultado['success']) {
          enviados++;
        } else {
          errores++;
          erroresDetalle.add('${empleado['telefono']}: ${resultado['error']}');
        }
      }

      return {
        'success': enviados > 0,
        'enviados': enviados,
        'errores': errores,
        'total': empleados.length,
        'erroresDetalle': erroresDetalle,
        'message': 'SMS enviados: $enviados/$empleados.length',
      };
    } catch (e) {
      return {'success': false, 'error': 'Error enviando SMS masivo: $e'};
    }
  }

  // Enviar SMS de confirmación de pago
  static Future<Map<String, dynamic>> enviarConfirmacionPago({
    required String propietarioId,
    required String nombrePagador,
    required double monto,
    required String codigoSeguridad,
  }) async {
    try {
      // Obtener empleados del propietario
      final empleados = await LocalDatabase.getEmpleadosByPropietario(
        propietarioId,
      );

      if (empleados.isEmpty) {
        return {
          'success': false,
          'error': 'No hay empleados registrados para notificar',
        };
      }

      // Crear mensaje de confirmación
      final mensaje =
          'Nuevo pago recibido: S/ ${monto.toStringAsFixed(2)} de $nombrePagador. Código: $codigoSeguridad';

      int enviados = 0;
      int errores = 0;
      final List<String> erroresDetalle = [];

      for (var empleado in empleados) {
        final numeroCompleto =
            '${empleado['paisCodigo']}${empleado['telefono']}';

        final resultado = await enviarSMSAPago(
          empleadoId: empleado['id'],
          pagoId: '', // Se generará automáticamente
          mensaje: mensaje,
          numeroDestino: numeroCompleto,
        );

        if (resultado['success']) {
          enviados++;
        } else {
          errores++;
          erroresDetalle.add('${empleado['telefono']}: ${resultado['error']}');
        }
      }

      return {
        'success': enviados > 0,
        'enviados': enviados,
        'errores': errores,
        'total': empleados.length,
        'erroresDetalle': erroresDetalle,
        'message': 'Confirmaciones enviadas: $enviados/$empleados.length',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error enviando confirmación de pago: $e',
      };
    }
  }

  // Obtener estadísticas de SMS
  static Future<Map<String, dynamic>> getEstadisticasSMS(
    String propietarioId,
  ) async {
    try {
      final db = await LocalDatabase.database;

      // SMS enviados hoy
      final hoy = DateTime.now();
      final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
      final finHoy = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);

      final smsHoy = await db.rawQuery(
        '''
        SELECT COUNT(*) as count
        FROM sms_enviados se
        JOIN empleados e ON se.empleadoId = e.id
        WHERE e.propietarioId = ? AND se.enviado = 1 AND se.fechaEnvio BETWEEN ? AND ?
      ''',
        [propietarioId, inicioHoy.toIso8601String(), finHoy.toIso8601String()],
      );

      // Total de SMS enviados
      final smsTotal = await db.rawQuery(
        '''
        SELECT COUNT(*) as count
        FROM sms_enviados se
        JOIN empleados e ON se.empleadoId = e.id
        WHERE e.propietarioId = ? AND se.enviado = 1
      ''',
        [propietarioId],
      );

      // SMS pendientes
      final smsPendientes = await db.rawQuery(
        '''
        SELECT COUNT(*) as count
        FROM sms_enviados se
        JOIN empleados e ON se.empleadoId = e.id
        WHERE e.propietarioId = ? AND se.enviado = 0
      ''',
        [propietarioId],
      );

      return {
        'smsHoy': smsHoy.first['count'] ?? 0,
        'smsTotal': smsTotal.first['count'] ?? 0,
        'smsPendientes': smsPendientes.first['count'] ?? 0,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo estadísticas de SMS: $e',
      };
    }
  }

  // Procesar SMS pendientes
  static Future<void> procesarSMSPendientes() async {
    try {
      await LocalDatabase.enviarSMSPendientes();
      print('✅ SMS pendientes procesados');
    } catch (e) {
      print('❌ Error procesando SMS pendientes: $e');
    }
  }

  // Verificar estado de SMS
  static Future<Map<String, dynamic>> verificarEstadoSMS(String smsId) async {
    try {
      final db = await LocalDatabase.database;
      final result = await db.query(
        'sms_enviados',
        where: 'id = ?',
        whereArgs: [smsId],
      );

      if (result.isNotEmpty) {
        final sms = result.first;
        return {
          'success': true,
          'enviado': sms['enviado'] == 1,
          'fechaEnvio': sms['fechaEnvio'],
          'error': sms['error'],
        };
      } else {
        return {'success': false, 'error': 'SMS no encontrado'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error verificando estado de SMS: $e'};
    }
  }
}
