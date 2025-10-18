import 'dart:io';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Alias para PermissionStatus
typedef PermissionStatus = permission_handler.PermissionStatus;

class PermissionService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Verificar y solicitar permisos necesarios
  static Future<Map<String, bool>> checkAndRequestPermissions() async {
    final results = <String, bool>{};

    // 1. Permisos de notificaciones
    results['notifications'] = await _requestNotificationPermission();

    // 2. Permisos específicos por plataforma
    if (Platform.isAndroid) {
      results['sms'] = await _requestSMSPermission();
      results['phone'] = await _requestPhonePermission();
      results['storage'] = await _requestStoragePermission();
    } else if (Platform.isIOS) {
      results['sms'] = await _requestSMSPermission();
      results['contacts'] = await _requestContactsPermission();
    }

    return results;
  }

  // Solicitar permisos de notificaciones
  static Future<bool> _requestNotificationPermission() async {
    try {
      // Configurar notificaciones locales
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(initSettings);

      // Solicitar permisos
      final permission = await permission_handler.Permission.notification
          .request();
      return permission.isGranted;
    } catch (e) {
      print('Error solicitando permisos de notificación: $e');
      return false;
    }
  }

  // Solicitar permisos de SMS (Android)
  static Future<bool> _requestSMSPermission() async {
    try {
      if (Platform.isAndroid) {
        // Permisos específicos de Android para SMS
        final smsPermission = await permission_handler.Permission.sms.request();

        return smsPermission.isGranted;
      } else if (Platform.isIOS) {
        // En iOS, los permisos de SMS se manejan automáticamente
        // pero necesitamos verificar que el dispositivo puede enviar SMS
        return await _canSendSMS();
      }
      return false;
    } catch (e) {
      print('Error solicitando permisos de SMS: $e');
      return false;
    }
  }

  // Verificar si se puede enviar SMS (iOS)
  static Future<bool> _canSendSMS() async {
    try {
      // En iOS, verificar si el dispositivo puede enviar SMS
      // Esto se hace a través de la configuración del dispositivo
      return true; // Por ahora asumimos que sí
    } catch (e) {
      print('Error verificando capacidad de SMS: $e');
      return false;
    }
  }

  // Solicitar permisos de teléfono (Android)
  static Future<bool> _requestPhonePermission() async {
    try {
      if (Platform.isAndroid) {
        final permission = await permission_handler.Permission.phone.request();
        return permission.isGranted;
      }
      return true; // No necesario en iOS
    } catch (e) {
      print('Error solicitando permisos de teléfono: $e');
      return false;
    }
  }

  // Solicitar permisos de almacenamiento (Android)
  static Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final permission = await permission_handler.Permission.storage
            .request();
        return permission.isGranted;
      }
      return true; // No necesario en iOS
    } catch (e) {
      print('Error solicitando permisos de almacenamiento: $e');
      return false;
    }
  }

  // Solicitar permisos de contactos (iOS)
  static Future<bool> _requestContactsPermission() async {
    try {
      if (Platform.isIOS) {
        final permission = await permission_handler.Permission.contacts
            .request();
        return permission.isGranted;
      }
      return true; // No necesario en Android
    } catch (e) {
      print('Error solicitando permisos de contactos: $e');
      return false;
    }
  }

  // Verificar estado de permisos
  static Future<Map<String, PermissionStatus>> checkPermissionStatus() async {
    final status = <String, PermissionStatus>{};

    status['notifications'] =
        await permission_handler.Permission.notification.status;

    if (Platform.isAndroid) {
      status['sms'] = await permission_handler.Permission.sms.status;
      status['phone'] = await permission_handler.Permission.phone.status;
      status['storage'] = await permission_handler.Permission.storage.status;
    } else if (Platform.isIOS) {
      status['contacts'] = await permission_handler.Permission.contacts.status;
    }

    return status;
  }

  // Abrir configuración de la aplicación
  static Future<void> openAppSettings() async {
    try {
      await permission_handler.openAppSettings();
    } catch (e) {
      print('Error abriendo configuración de la aplicación: $e');
    }
  }

  // Verificar si todos los permisos necesarios están concedidos
  static Future<bool> areAllPermissionsGranted() async {
    try {
      final status = await checkPermissionStatus();

      // Verificar notificaciones
      if (status['notifications'] != PermissionStatus.granted) {
        return false;
      }

      // Verificar permisos específicos por plataforma
      if (Platform.isAndroid) {
        if (status['sms'] != PermissionStatus.granted ||
            status['phone'] != PermissionStatus.granted ||
            status['storage'] != PermissionStatus.granted) {
          return false;
        }
      } else if (Platform.isIOS) {
        if (status['contacts'] != PermissionStatus.granted) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error verificando permisos: $e');
      return false;
    }
  }

  // Obtener mensaje de error para permisos faltantes
  static String getPermissionErrorMessage(
    Map<String, PermissionStatus> status,
  ) {
    final missingPermissions = <String>[];

    if (status['notifications'] != PermissionStatus.granted) {
      missingPermissions.add('Notificaciones');
    }

    if (Platform.isAndroid) {
      if (status['sms'] != PermissionStatus.granted) {
        missingPermissions.add('SMS');
      }
      if (status['phone'] != PermissionStatus.granted) {
        missingPermissions.add('Teléfono');
      }
      if (status['storage'] != PermissionStatus.granted) {
        missingPermissions.add('Almacenamiento');
      }
    } else if (Platform.isIOS) {
      if (status['contacts'] != PermissionStatus.granted) {
        missingPermissions.add('Contactos');
      }
    }

    if (missingPermissions.isEmpty) {
      return 'Todos los permisos están concedidos';
    }

    return 'Permisos faltantes: ${missingPermissions.join(', ')}';
  }
}
