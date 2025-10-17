import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'connectivity_service.dart';

class PermissionService {
  /// Verificar y solicitar todos los permisos necesarios
  static Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};

    try {
      // Permisos básicos
      results['notification'] = await _requestNotificationPermission();
      results['internet'] = await _requestInternetPermission();
      results['sms'] = await _requestSMSPermission();

      // Permisos específicos de plataforma
      if (Platform.isAndroid) {
        results['systemAlert'] = await _requestSystemAlertPermission();
        results['notificationListener'] =
            await _requestNotificationListenerPermission();
        results['backgroundLocation'] =
            await _requestBackgroundLocationPermission();
        results['foregroundService'] =
            await _requestForegroundServicePermission();
      } else if (Platform.isIOS) {
        results['criticalAlerts'] = await _requestCriticalAlertsPermission();
        results['backgroundAppRefresh'] =
            await _requestBackgroundAppRefreshPermission();
      }

      print('📋 Resultados de permisos: $results');
      return results;
    } catch (e) {
      print('❌ Error al solicitar permisos: $e');
      return results;
    }
  }

  /// Verificar estado de todos los permisos
  static Future<Map<String, PermissionStatus>> checkAllPermissions() async {
    final statuses = <String, PermissionStatus>{};

    try {
      statuses['notification'] = await Permission.notification.status;
      statuses['internet'] =
          await Permission.phone.status; // Para verificar conectividad
      statuses['sms'] = await Permission.sms.status;

      if (Platform.isAndroid) {
        statuses['systemAlert'] = await Permission.systemAlertWindow.status;
        statuses['notificationListener'] = await Permission.notification.status;
        statuses['backgroundLocation'] = await Permission.locationAlways.status;
        statuses['foregroundService'] = await Permission.notification.status;
      } else if (Platform.isIOS) {
        statuses['criticalAlerts'] = await Permission.notification.status;
        statuses['backgroundAppRefresh'] = await Permission.notification.status;
      }

      return statuses;
    } catch (e) {
      print('❌ Error al verificar permisos: $e');
      return statuses;
    }
  }

  /// Solicitar permiso de notificaciones
  static Future<bool> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      print('❌ Error al solicitar permiso de notificaciones: $e');
      return false;
    }
  }

  /// Verificar conectividad a internet (sin permisos)
  static Future<bool> _requestInternetPermission() async {
    try {
      // Solo verificar conectividad, no solicitar permisos
      return await _checkInternetConnectivity();
    } catch (e) {
      print('❌ Error al verificar conectividad: $e');
      return false;
    }
  }

  /// Verificar conectividad a internet
  static Future<bool> _checkInternetConnectivity() async {
    try {
      // Usar el servicio de conectividad
      return await ConnectivityService.hasInternetForApp();
    } catch (e) {
      print('❌ Error al verificar conectividad: $e');
      return false;
    }
  }

  /// Solicitar permiso de SMS
  static Future<bool> _requestSMSPermission() async {
    try {
      final status = await Permission.sms.request();
      return status.isGranted;
    } catch (e) {
      print('❌ Error al solicitar permiso de SMS: $e');
      return false;
    }
  }

  /// Solicitar permiso de ventana del sistema (Android)
  static Future<bool> _requestSystemAlertPermission() async {
    try {
      final status = await Permission.systemAlertWindow.request();
      return status.isGranted;
    } catch (e) {
      print('❌ Error al solicitar permiso de ventana del sistema: $e');
      return false;
    }
  }

  /// Solicitar permiso de listener de notificaciones (Android)
  static Future<bool> _requestNotificationListenerPermission() async {
    try {
      // Este permiso se debe configurar manualmente en Android
      // Abrir configuración de accesibilidad
      await openAppSettings();
      return false; // Se debe verificar manualmente
    } catch (e) {
      print('❌ Error al solicitar permiso de listener de notificaciones: $e');
      return false;
    }
  }

  /// Solicitar permiso de ubicación en segundo plano (Android)
  static Future<bool> _requestBackgroundLocationPermission() async {
    try {
      final status = await Permission.locationAlways.request();
      return status.isGranted;
    } catch (e) {
      print('❌ Error al solicitar permiso de ubicación en segundo plano: $e');
      return false;
    }
  }

  /// Solicitar permiso de servicio en primer plano (Android)
  static Future<bool> _requestForegroundServicePermission() async {
    try {
      // En Android 10+, se requiere permiso para servicios en primer plano
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      print('❌ Error al solicitar permiso de servicio en primer plano: $e');
      return false;
    }
  }

  /// Solicitar permiso de alertas críticas (iOS)
  static Future<bool> _requestCriticalAlertsPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      print('❌ Error al solicitar permiso de alertas críticas: $e');
      return false;
    }
  }

  /// Solicitar permiso de actualización en segundo plano (iOS)
  static Future<bool> _requestBackgroundAppRefreshPermission() async {
    try {
      // En iOS, esto se configura en Configuración > General > Actualización en segundo plano
      await openAppSettings();
      return false; // Se debe verificar manualmente
    } catch (e) {
      print(
        '❌ Error al solicitar permiso de actualización en segundo plano: $e',
      );
      return false;
    }
  }

  /// Verificar si todos los permisos críticos están concedidos
  static Future<bool> areCriticalPermissionsGranted() async {
    try {
      final statuses = await checkAllPermissions();

      // Permisos críticos
      final criticalPermissions = ['notification', 'internet', 'sms'];

      for (final permission in criticalPermissions) {
        if (statuses[permission] != PermissionStatus.granted) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('❌ Error al verificar permisos críticos: $e');
      return false;
    }
  }

  /// Obtener información del dispositivo
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return {
          'platform': 'Android',
          'version': 'Unknown',
          'sdkInt': 0,
          'model': 'Unknown',
          'brand': 'Unknown',
        };
      } else if (Platform.isIOS) {
        return {
          'platform': 'iOS',
          'version': 'Unknown',
          'model': 'Unknown',
          'name': 'Unknown',
        };
      }

      return {'platform': 'Unknown'};
    } catch (e) {
      print('❌ Error al obtener información del dispositivo: $e');
      return {'platform': 'Unknown', 'error': e.toString()};
    }
  }

  /// Abrir configuración de la aplicación
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('❌ Error al abrir configuración: $e');
    }
  }

  /// Verificar si la aplicación puede ejecutarse en segundo plano
  static Future<bool> canRunInBackground() async {
    try {
      final deviceInfo = await getDeviceInfo();

      if (Platform.isAndroid) {
        final sdkInt = deviceInfo['sdkInt'] as int? ?? 0;
        // Android 8.0+ requiere permisos especiales para ejecutar en segundo plano
        return sdkInt >= 26;
      } else if (Platform.isIOS) {
        // iOS requiere configuración especial para ejecutar en segundo plano
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error al verificar capacidad de ejecución en segundo plano: $e');
      return false;
    }
  }
}
