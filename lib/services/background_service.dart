import 'dart:async';
import '../database/local_database.dart';
import '../services/connectivity_service.dart';
import '../services/session_service.dart';

class BackgroundService {
  static Timer? _connectivityTimer;
  static Timer? _sessionTimer;
  static bool _isRunning = false;

  // Iniciar servicio en segundo plano
  static Future<void> start() async {
    if (_isRunning) return;

    _isRunning = true;
    print('🔄 Iniciando servicio en segundo plano');

    // Verificar conectividad cada 30 segundos
    _connectivityTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      await _checkConnectivity();
    });

    // Mantener sesión activa cada 5 minutos
    _sessionTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _keepSessionAlive();
    });

    // Verificación inicial
    await _checkConnectivity();
    await _keepSessionAlive();
  }

  // Detener servicio en segundo plano
  static Future<void> stop() async {
    _isRunning = false;
    _connectivityTimer?.cancel();
    _sessionTimer?.cancel();
    print('⏹️ Deteniendo servicio en segundo plano');
  }

  // Verificar conectividad
  static Future<void> _checkConnectivity() async {
    try {
      final hasConnection = await ConnectivityService.hasInternetConnection();
      if (!hasConnection) {
        print('⚠️ Sin conexión a Internet');
        // Aquí podrías implementar lógica para manejar la falta de conexión
      } else {
        print('✅ Conexión a Internet activa');
      }
    } catch (e) {
      print('❌ Error verificando conectividad: $e');
    }
  }

  // Mantener sesión activa
  static Future<void> _keepSessionAlive() async {
    try {
      final hasSession = await SessionService.isLoggedIn();
      if (hasSession) {
        await SessionService.keepSessionAlive();
        print('✅ Sesión mantenida activa');
      } else {
        print('⚠️ No hay sesión activa');
      }
    } catch (e) {
      print('❌ Error manteniendo sesión: $e');
    }
  }

  // Procesar notificaciones pendientes
  static Future<void> processPendingNotifications() async {
    try {
      final notifications = await LocalDatabase.getNotificacionesPendientes();
      if (notifications.isNotEmpty) {
        print(
          '📱 Procesando ${notifications.length} notificaciones pendientes',
        );

        for (var notification in notifications) {
          await LocalDatabase.procesarNotificacionYape(
            notification['mensajeOriginal'],
            notification['propietarioId'],
          );
        }
      }
    } catch (e) {
      print('❌ Error procesando notificaciones: $e');
    }
  }

  // Procesar SMS pendientes
  static Future<void> processPendingSMS() async {
    try {
      await LocalDatabase.enviarSMSPendientes();
      print('📨 SMS pendientes procesados');
    } catch (e) {
      print('❌ Error procesando SMS: $e');
    }
  }

  // Verificar si el servicio está corriendo
  static bool get isRunning => _isRunning;

  // Obtener estado del servicio
  static Map<String, dynamic> getServiceStatus() {
    return {
      'isRunning': _isRunning,
      'connectivityTimer': _connectivityTimer?.isActive ?? false,
      'sessionTimer': _sessionTimer?.isActive ?? false,
    };
  }
}
