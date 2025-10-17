import 'dart:async';
import 'package:http/http.dart' as http;

class ConnectivityService {
  static const String _testUrl = 'https://www.google.com';
  static const Duration _timeout = Duration(seconds: 5);

  static StreamController<bool>? _connectivityController;
  static Stream<bool>? _connectivityStream;
  static Timer? _connectivityTimer;
  static bool _lastConnectivityStatus = false;

  /// Inicializar servicio de conectividad
  static Future<bool> initialize() async {
    try {
      print('🌐 Inicializando servicio de conectividad...');

      // Configurar stream de conectividad
      _connectivityController = StreamController<bool>.broadcast();
      _connectivityStream = _connectivityController!.stream;

      // Verificar conectividad inicial
      final hasInternet = await checkInternetConnection();
      _lastConnectivityStatus = hasInternet;

      // Iniciar monitoreo periódico
      _startConnectivityMonitoring();

      print('✅ Servicio de conectividad inicializado');
      return true;
    } catch (e) {
      print('❌ Error al inicializar servicio de conectividad: $e');
      return false;
    }
  }

  /// Verificar conexión a internet
  static Future<bool> checkInternetConnection() async {
    try {
      // Intentar hacer una petición HTTP simple
      final response = await http.get(Uri.parse(_testUrl)).timeout(_timeout);

      final hasInternet = response.statusCode == 200;

      // Notificar cambio de estado
      if (hasInternet != _lastConnectivityStatus) {
        _lastConnectivityStatus = hasInternet;
        _connectivityController?.add(hasInternet);

        if (hasInternet) {
          print('✅ Conexión a internet restaurada');
        } else {
          print('⚠️ Conexión a internet perdida');
        }
      }

      return hasInternet;
    } catch (e) {
      print('❌ Sin conexión a internet: $e');

      // Notificar pérdida de conexión
      if (_lastConnectivityStatus) {
        _lastConnectivityStatus = false;
        _connectivityController?.add(false);
        print('⚠️ Conexión a internet perdida');
      }

      return false;
    }
  }

  /// Iniciar monitoreo de conectividad
  static void _startConnectivityMonitoring() {
    _connectivityTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      await checkInternetConnection();
    });
  }

  /// Detener monitoreo de conectividad
  static void stopConnectivityMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
    print('⏹️ Monitoreo de conectividad detenido');
  }

  /// Obtener stream de conectividad
  static Stream<bool>? get connectivityStream => _connectivityStream;

  /// Verificar si hay conexión actual
  static bool get isConnected => _lastConnectivityStatus;

  /// Verificar conectividad con timeout personalizado
  static Future<bool> checkConnectionWithTimeout(Duration timeout) async {
    try {
      final response = await http.get(Uri.parse(_testUrl)).timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Verificar conectividad a un servidor específico
  static Future<bool> checkConnectionToServer(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error al conectar con $url: $e');
      return false;
    }
  }

  /// Verificar si el usuario tiene internet (requisito para la app)
  static Future<bool> hasInternetForApp() async {
    try {
      // Verificar conectividad básica
      final hasInternet = await checkInternetConnection();

      if (!hasInternet) {
        print('⚠️ Usuario no tiene conexión a internet');
        print(
          '📱 La aplicación requiere internet para funcionar correctamente',
        );
        return false;
      }

      print('✅ Usuario tiene conexión a internet');
      return true;
    } catch (e) {
      print('❌ Error al verificar internet del usuario: $e');
      return false;
    }
  }

  /// Obtener información de conectividad
  static Future<Map<String, dynamic>> getConnectivityInfo() async {
    try {
      final hasInternet = await checkInternetConnection();

      return {
        'hasInternet': hasInternet,
        'lastCheck': DateTime.now().toIso8601String(),
        'testUrl': _testUrl,
        'timeout': _timeout.inSeconds,
      };
    } catch (e) {
      return {
        'hasInternet': false,
        'error': e.toString(),
        'lastCheck': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Detener servicio de conectividad
  static Future<void> stop() async {
    try {
      stopConnectivityMonitoring();
      await _connectivityController?.close();
      _connectivityController = null;
      _connectivityStream = null;
      print('⏹️ Servicio de conectividad detenido');
    } catch (e) {
      print('❌ Error al detener servicio de conectividad: $e');
    }
  }
}
