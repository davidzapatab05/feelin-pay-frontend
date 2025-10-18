import 'dart:async';
import '../database/local_database.dart';

class YapeNotificationService {
  static StreamSubscription? _subscription;
  static bool _isListening = false;

  // Iniciar escucha de notificaciones de Yape
  static Future<void> startListening() async {
    if (_isListening) return;

    try {
      // Simular escucha de notificaciones (en producción se implementaría con plugins nativos)
      _isListening = true;
      print('✅ Escuchando notificaciones de Yape');

      // En producción, aquí se configuraría el listener real
      // _subscription = _channel.receiveBroadcastStream().listen(...)
    } catch (e) {
      print('❌ Error iniciando escucha de notificaciones: $e');
    }
  }

  // Detener escucha de notificaciones
  static Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    print('⏹️ Detenida escucha de notificaciones de Yape');
  }

  // Obtener notificaciones pendientes
  static Future<List<Map<String, dynamic>>>
  getNotificacionesPendientes() async {
    return await LocalDatabase.getNotificacionesPendientes();
  }

  // Procesar notificaciones pendientes
  static Future<void> procesarNotificacionesPendientes() async {
    try {
      final notificaciones = await getNotificacionesPendientes();

      for (var notificacion in notificaciones) {
        await LocalDatabase.procesarNotificacionYape(
          notificacion['mensajeOriginal'],
          notificacion['propietarioId'],
        );
      }

      print('✅ Notificaciones pendientes procesadas: ${notificaciones.length}');
    } catch (e) {
      print('❌ Error procesando notificaciones pendientes: $e');
    }
  }
}
