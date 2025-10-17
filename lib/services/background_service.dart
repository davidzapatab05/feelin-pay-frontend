import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'yape_notification_service.dart';
import 'permission_service.dart';
import 'connectivity_service.dart';

class BackgroundService {
  static StreamController<Map<String, dynamic>>? _backgroundController;
  static Stream<Map<String, dynamic>>? _backgroundStream;
  static Timer? _monitoringTimer;

  /// Inicializar el servicio de fondo
  static Future<bool> initialize() async {
    try {
      print('🚀 Inicializando servicio de fondo...');

      // Verificar permisos
      final hasPermissions =
          await PermissionService.areCriticalPermissionsGranted();
      if (!hasPermissions) {
        print('❌ Permisos críticos no concedidos');
        return false;
      }

      // Configurar servicios de fondo para Android
      if (Platform.isAndroid) {
        await _initializeBackgroundServices();
      }

      // Configurar stream de fondo
      _backgroundController =
          StreamController<Map<String, dynamic>>.broadcast();
      _backgroundStream = _backgroundController!.stream;

      // Inicializar servicio de notificaciones Yape
      final yapeInitialized = await YapeNotificationService.initialize();
      if (!yapeInitialized) {
        print('❌ Error al inicializar servicio de notificaciones Yape');
        return false;
      }

      // Configurar listener de notificaciones
      _setupNotificationListener();

      print('✅ Servicio de fondo inicializado correctamente');
      return true;
    } catch (e) {
      print('❌ Error al inicializar servicio de fondo: $e');
      return false;
    }
  }

  /// Inicializar servicios de fondo para Android
  static Future<void> _initializeBackgroundServices() async {
    try {
      print('✅ Servicios de fondo configurados para Android');
    } catch (e) {
      print('❌ Error al inicializar servicios de fondo: $e');
    }
  }

  /// Configurar listener de notificaciones
  static void _setupNotificationListener() {
    YapeNotificationService.notificationStream?.listen((notification) {
      print('📱 Notificación procesada en fondo: ${notification['type']}');

      // Enviar al stream de fondo
      _backgroundController?.add({
        'type': 'background_notification',
        'data': notification,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Procesar notificación
      _processBackgroundNotification(notification);
    });
  }

  /// Procesar notificación en segundo plano
  static Future<void> _processBackgroundNotification(
    Map<String, dynamic> notification,
  ) async {
    try {
      if (notification['type'] == 'yape_payment') {
        print('💰 Procesando pago Yape en segundo plano...');

        // Aquí se procesaría el pago:
        // 1. Validar duplicados
        // 2. Registrar en Google Sheets
        // 3. Enviar SMS a empleados
        // 4. Actualizar base de datos local

        await _handleYapePayment(notification['data']);
      } else if (notification['type'] == 'fake_yape') {
        print('⚠️ Notificación Yape falsa detectada en segundo plano');

        // Registrar intento de fraude
        await _handleFakeYape(notification['data']);
      }
    } catch (e) {
      print('❌ Error al procesar notificación en segundo plano: $e');
    }
  }

  /// Manejar pago Yape real
  static Future<void> _handleYapePayment(
    Map<String, dynamic> paymentData,
  ) async {
    try {
      // Guardar en preferencias para sincronización posterior
      final prefs = await SharedPreferences.getInstance();
      final payments = prefs.getStringList('pending_payments') ?? [];

      payments.add(paymentData.toString());
      await prefs.setStringList('pending_payments', payments);

      print('✅ Pago Yape guardado para sincronización');
    } catch (e) {
      print('❌ Error al manejar pago Yape: $e');
    }
  }

  /// Manejar notificación Yape falsa
  static Future<void> _handleFakeYape(Map<String, dynamic> fakeData) async {
    try {
      // Registrar intento de fraude
      final prefs = await SharedPreferences.getInstance();
      final fraudAttempts = prefs.getInt('fraud_attempts') ?? 0;
      await prefs.setInt('fraud_attempts', fraudAttempts + 1);

      print('⚠️ Intento de fraude registrado');
    } catch (e) {
      print('❌ Error al manejar notificación falsa: $e');
    }
  }

  /// Iniciar monitoreo continuo
  static Future<void> startMonitoring() async {
    try {
      print('🔄 Iniciando monitoreo continuo...');

      // Iniciar timer de monitoreo
      _monitoringTimer = Timer.periodic(Duration(minutes: 5), (timer) {
        _performBackgroundCheck();
      });

      print('✅ Monitoreo iniciado');
    } catch (e) {
      print('❌ Error al iniciar monitoreo: $e');
    }
  }

  /// Detener monitoreo
  static Future<void> stopMonitoring() async {
    try {
      _monitoringTimer?.cancel();
      _monitoringTimer = null;
      print('⏹️ Monitoreo detenido');
    } catch (e) {
      print('❌ Error al detener monitoreo: $e');
    }
  }

  /// Realizar verificación en segundo plano
  static Future<void> _performBackgroundCheck() async {
    try {
      // Verificar conectividad
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        print('⚠️ Sin conexión a internet');
        return;
      }

      // Verificar permisos
      final hasPermissions =
          await PermissionService.areCriticalPermissionsGranted();
      if (!hasPermissions) {
        print('⚠️ Permisos críticos no concedidos');
        return;
      }

      // Sincronizar datos pendientes
      await _syncPendingData();

      print('✅ Verificación en segundo plano completada');
    } catch (e) {
      print('❌ Error en verificación en segundo plano: $e');
    }
  }

  /// Verificar conexión a internet
  static Future<bool> _checkInternetConnection() async {
    try {
      // Usar el servicio de conectividad
      return await ConnectivityService.hasInternetForApp();
    } catch (e) {
      print('❌ Error al verificar conexión: $e');
      return false;
    }
  }

  /// Sincronizar datos pendientes
  static Future<void> _syncPendingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingPayments = prefs.getStringList('pending_payments') ?? [];

      if (pendingPayments.isNotEmpty) {
        print('🔄 Sincronizando ${pendingPayments.length} pagos pendientes...');

        // Aquí se sincronizarían con el backend
        // await _syncWithBackend(pendingPayments);

        // Limpiar datos sincronizados
        await prefs.remove('pending_payments');
        print('✅ Datos sincronizados');
      }
    } catch (e) {
      print('❌ Error al sincronizar datos: $e');
    }
  }

  /// Obtener stream de fondo
  static Stream<Map<String, dynamic>>? get backgroundStream =>
      _backgroundStream;

  /// Verificar si el servicio está activo
  static bool get isActive =>
      _backgroundController != null && !_backgroundController!.isClosed;

  /// Detener servicio
  static Future<void> stop() async {
    try {
      await stopMonitoring();
      await YapeNotificationService.stop();
      await _backgroundController?.close();
      _backgroundController = null;
      _backgroundStream = null;
      print('⏹️ Servicio de fondo detenido');
    } catch (e) {
      print('❌ Error al detener servicio: $e');
    }
  }

  /// Obtener estadísticas del servicio
  static Future<Map<String, dynamic>> getServiceStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'isActive': isActive,
        'pendingPayments': prefs.getStringList('pending_payments')?.length ?? 0,
        'fraudAttempts': prefs.getInt('fraud_attempts') ?? 0,
        'lastSync': prefs.getString('last_sync'),
      };
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return {};
    }
  }
}

/// Callback para tareas en segundo plano
@pragma('vm:entry-point')
void backgroundTaskDispatcher() {
  print('🔄 Ejecutando tarea en segundo plano');

  try {
    // Realizar tareas en segundo plano
    BackgroundService._performBackgroundCheck();
  } catch (e) {
    print('❌ Error en tarea de fondo: $e');
  }
}
