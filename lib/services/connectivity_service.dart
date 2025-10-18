import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static final InternetConnectionChecker _connectionChecker =
      InternetConnectionChecker();

  // Verificar si hay conexión a Internet
  static Future<bool> hasInternetConnection() async {
    try {
      // Verificar conectividad básica
      final connectivityResults = await _connectivity.checkConnectivity();

      if (connectivityResults.isEmpty ||
          connectivityResults.first == ConnectivityResult.none) {
        return false;
      }

      // Verificar conexión real a Internet
      final hasConnection = await _connectionChecker.hasConnection;
      return hasConnection;
    } catch (e) {
      print('Error verificando conectividad: $e');
      return false;
    }
  }

  // Verificar tipo de conexión
  static Future<String> getConnectionType() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();

      if (connectivityResults.isEmpty) {
        return 'No Connection';
      }

      // Tomar el primer resultado
      final connectivityResult = connectivityResults.first;

      switch (connectivityResult) {
        case ConnectivityResult.wifi:
          return 'WiFi';
        case ConnectivityResult.mobile:
          return 'Mobile Data';
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.bluetooth:
          return 'Bluetooth';
        case ConnectivityResult.vpn:
          return 'VPN';
        case ConnectivityResult.other:
          return 'Other';
        case ConnectivityResult.none:
          return 'No Connection';
      }
    } catch (e) {
      print('Error obteniendo tipo de conexión: $e');
      return 'Unknown';
    }
  }

  // Escuchar cambios de conectividad
  static Stream<List<ConnectivityResult>> get connectivityStream {
    return _connectivity.onConnectivityChanged;
  }

  // Verificar si la conexión es estable
  static Future<bool> isConnectionStable() async {
    try {
      // Verificar múltiples veces para asegurar estabilidad
      for (int i = 0; i < 3; i++) {
        final hasConnection = await _connectionChecker.hasConnection;
        if (!hasConnection) {
          return false;
        }
        await Future.delayed(Duration(seconds: 1));
      }
      return true;
    } catch (e) {
      print('Error verificando estabilidad de conexión: $e');
      return false;
    }
  }

  // Verificar velocidad de conexión (básica)
  static Future<Map<String, dynamic>> getConnectionInfo() async {
    try {
      final startTime = DateTime.now();
      final hasConnection = await _connectionChecker.hasConnection;
      final endTime = DateTime.now();

      final responseTime = endTime.difference(startTime).inMilliseconds;
      final connectionType = await getConnectionType();

      return {
        'hasConnection': hasConnection,
        'connectionType': connectionType,
        'responseTime': responseTime,
        'isStable': responseTime < 3000, // Menos de 3 segundos es estable
      };
    } catch (e) {
      print('Error obteniendo información de conexión: $e');
      return {
        'hasConnection': false,
        'connectionType': 'Unknown',
        'responseTime': -1,
        'isStable': false,
      };
    }
  }

  // Verificar si la conexión es suficiente para la aplicación
  static Future<bool> isConnectionSufficient() async {
    try {
      final connectionInfo = await getConnectionInfo();

      // Verificar que hay conexión y es estable
      if (!connectionInfo['hasConnection'] || !connectionInfo['isStable']) {
        return false;
      }

      // Verificar que no es solo Bluetooth (insuficiente para la app)
      final connectionType = connectionInfo['connectionType'];
      if (connectionType == 'Bluetooth' || connectionType == 'No Connection') {
        return false;
      }

      return true;
    } catch (e) {
      print('Error verificando suficiencia de conexión: $e');
      return false;
    }
  }
}
