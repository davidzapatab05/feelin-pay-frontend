import 'dart:async';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class YapeNotificationService {
  static const MethodChannel _channel = MethodChannel('yape_notifications');
  static const String _yapePackageName = 'com.bcp.yape';

  // Patrones para identificar notificaciones de Yape reales
  static const List<String> _yapeRealPatterns = [
    'Yape',
    'BCP',
    'Banco de Crédito',
    'Recibiste',
    'Te enviaron',
    'Pago recibido',
    'Transferencia',
  ];

  // Patrones para identificar notificaciones falsas
  static const List<String> _fakePatterns = [
    'Yape Falso',
    'Yape Fake',
    'Yape Simulado',
    'Yape Test',
    'Yape Demo',
    'Yape Prueba',
  ];

  static StreamController<Map<String, dynamic>>? _notificationController;
  static Stream<Map<String, dynamic>>? _notificationStream;

  /// Inicializar el servicio de notificaciones de Yape
  static Future<bool> initialize() async {
    try {
      // Solicitar permisos necesarios
      final notificationPermission = await Permission.notification.request();
      final systemAlertPermission = await Permission.systemAlertWindow
          .request();

      if (!notificationPermission.isGranted ||
          !systemAlertPermission.isGranted) {
        print('❌ Permisos de notificaciones denegados');
        return false;
      }

      // Configurar el canal de notificaciones
      _notificationController =
          StreamController<Map<String, dynamic>>.broadcast();
      _notificationStream = _notificationController!.stream;

      // Configurar listener de notificaciones
      _channel.setMethodCallHandler(_handleNotification);

      print('✅ Servicio de notificaciones Yape inicializado');
      return true;
    } catch (e) {
      print('❌ Error al inicializar servicio Yape: $e');
      return false;
    }
  }

  /// Manejar notificaciones recibidas
  static Future<dynamic> _handleNotification(MethodCall call) async {
    switch (call.method) {
      case 'onNotificationReceived':
        final notificationData = Map<String, dynamic>.from(call.arguments);
        await _processYapeNotification(notificationData);
        break;
      default:
        print('⚠️ Método desconocido: ${call.method}');
    }
  }

  /// Procesar notificación de Yape
  static Future<void> _processYapeNotification(
    Map<String, dynamic> notification,
  ) async {
    try {
      print('📱 Notificación recibida: ${notification['title']}');

      // Validar si es una notificación de Yape real
      final validation = await _validateYapeNotification(notification);

      if (validation['isValid']) {
        print('✅ Notificación Yape válida detectada');

        // Extraer datos del pago
        final paymentData = _extractPaymentData(notification);

        // Enviar al stream para procesamiento
        _notificationController?.add({
          'type': 'yape_payment',
          'data': paymentData,
          'notification': notification,
          'isValid': true,
        });
      } else {
        print('⚠️ Notificación Yape falsa detectada: ${validation['reason']}');

        // Enviar alerta de notificación falsa
        _notificationController?.add({
          'type': 'fake_yape',
          'data': notification,
          'isValid': false,
          'reason': validation['reason'],
        });
      }
    } catch (e) {
      print('❌ Error al procesar notificación: $e');
    }
  }

  /// Validar si es una notificación de Yape real
  static Future<Map<String, dynamic>> _validateYapeNotification(
    Map<String, dynamic> notification,
  ) async {
    final title = notification['title']?.toString().toLowerCase() ?? '';
    final body = notification['body']?.toString().toLowerCase() ?? '';
    final packageName = notification['packageName']?.toString() ?? '';

    // Verificar que sea de la app Yape oficial
    if (packageName != _yapePackageName) {
      return {'isValid': false, 'reason': 'No es de la app Yape oficial'};
    }

    // Verificar patrones de notificaciones falsas
    for (final pattern in _fakePatterns) {
      if (title.contains(pattern.toLowerCase()) ||
          body.contains(pattern.toLowerCase())) {
        return {
          'isValid': false,
          'reason': 'Contiene patrones de notificación falsa',
        };
      }
    }

    // Verificar patrones de notificaciones reales
    bool hasRealPattern = false;
    for (final pattern in _yapeRealPatterns) {
      if (title.contains(pattern.toLowerCase()) ||
          body.contains(pattern.toLowerCase())) {
        hasRealPattern = true;
        break;
      }
    }

    if (!hasRealPattern) {
      return {
        'isValid': false,
        'reason': 'No contiene patrones de notificación real de Yape',
      };
    }

    // Verificar que contenga información de pago
    final hasPaymentInfo = _hasPaymentInformation(notification);
    if (!hasPaymentInfo) {
      return {
        'isValid': false,
        'reason': 'No contiene información de pago válida',
      };
    }

    return {'isValid': true, 'reason': 'Notificación Yape válida'};
  }

  /// Verificar si contiene información de pago
  static bool _hasPaymentInformation(Map<String, dynamic> notification) {
    final body = notification['body']?.toString() ?? '';

    // Buscar patrones de montos (S/ 10.50, S/10, 10.50, etc.)
    final amountPattern = RegExp(r's/[\s]*[\d]+[.,]?[\d]*|[\d]+[.,][\d]+');
    if (amountPattern.hasMatch(body)) {
      return true;
    }

    // Buscar palabras clave de pago
    final paymentKeywords = [
      'recibiste',
      'te enviaron',
      'pago',
      'transferencia',
      'monto',
    ];
    for (final keyword in paymentKeywords) {
      if (body.toLowerCase().contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Extraer datos del pago de la notificación
  static Map<String, dynamic> _extractPaymentData(
    Map<String, dynamic> notification,
  ) {
    final body = notification['body']?.toString() ?? '';

    // Extraer monto
    final amountPattern = RegExp(
      r's/[\s]*([\d]+[.,]?[\d]*)',
      caseSensitive: false,
    );
    final amountMatch = amountPattern.firstMatch(body);
    final amount = amountMatch?.group(1)?.replaceAll(',', '.') ?? '0';

    // Extraer nombre del pagador
    final payerPattern = RegExp(r'de\s+([^,\n]+)', caseSensitive: false);
    final payerMatch = payerPattern.firstMatch(body);
    final payerName = payerMatch?.group(1)?.trim() ?? 'Desconocido';

    // Extraer código de seguridad
    final securityCodePattern = RegExp(
      r'código[:\s]*([a-zA-Z0-9]+)',
      caseSensitive: false,
    );
    final securityCodeMatch = securityCodePattern.firstMatch(body);
    final securityCode = securityCodeMatch?.group(1) ?? '';

    return {
      'amount': double.tryParse(amount) ?? 0.0,
      'payerName': payerName,
      'securityCode': securityCode,
      'timestamp': DateTime.now().toIso8601String(),
      'originalNotification': notification,
    };
  }

  /// Obtener stream de notificaciones
  static Stream<Map<String, dynamic>>? get notificationStream =>
      _notificationStream;

  /// Detener el servicio
  static Future<void> stop() async {
    await _notificationController?.close();
    _notificationController = null;
    _notificationStream = null;
  }

  /// Verificar si el servicio está activo
  static bool get isActive =>
      _notificationController != null && !_notificationController!.isClosed;

  /// Obtener estadísticas de notificaciones
  static Future<Map<String, int>> getNotificationStats() async {
    // Implementar lógica para obtener estadísticas
    return {'total': 0, 'valid': 0, 'fake': 0};
  }
}
