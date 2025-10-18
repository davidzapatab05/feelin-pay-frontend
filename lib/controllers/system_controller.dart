import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import '../services/connectivity_service.dart';
import '../services/permission_service.dart';

class SystemController extends ChangeNotifier {
  bool _hasInternetConnection = false;
  bool _hasSMSPermission = false;
  bool _hasNotificationPermission = false;
  bool _isCheckingPermissions = false;
  bool _isCheckingConnectivity = false;
  String _connectionType = 'Unknown';
  String? _errorMessage;

  bool get hasInternetConnection => _hasInternetConnection;
  bool get hasSMSPermission => _hasSMSPermission;
  bool get hasNotificationPermission => _hasNotificationPermission;
  bool get isCheckingPermissions => _isCheckingPermissions;
  bool get isCheckingConnectivity => _isCheckingConnectivity;
  String get connectionType => _connectionType;
  String? get errorMessage => _errorMessage;

  // Verificar conectividad a Internet
  Future<void> checkInternetConnection() async {
    _setCheckingConnectivity(true);
    _clearError();

    try {
      final hasConnection = await ConnectivityService.hasInternetConnection();
      final connectionType = await ConnectivityService.getConnectionType();
      final isSufficient = await ConnectivityService.isConnectionSufficient();

      _hasInternetConnection = hasConnection && isSufficient;
      _connectionType = connectionType;

      if (!_hasInternetConnection) {
        _setError('Sin conexión a Internet o conexión insuficiente');
      }

      notifyListeners();
    } catch (e) {
      _setError('Error verificando conectividad: ${e.toString()}');
      _hasInternetConnection = false;
      notifyListeners();
    } finally {
      _setCheckingConnectivity(false);
    }
  }

  // Verificar y solicitar permisos
  Future<void> checkAndRequestPermissions() async {
    _setCheckingPermissions(true);
    _clearError();

    try {
      final permissions = await PermissionService.checkAndRequestPermissions();

      _hasNotificationPermission = permissions['notifications'] ?? false;
      _hasSMSPermission = permissions['sms'] ?? false;

      if (!_hasNotificationPermission) {
        _setError('Permisos de notificaciones requeridos');
      } else if (!_hasSMSPermission) {
        _setError('Permisos de SMS requeridos');
      }

      notifyListeners();
    } catch (e) {
      _setError('Error verificando permisos: ${e.toString()}');
      notifyListeners();
    } finally {
      _setCheckingPermissions(false);
    }
  }

  // Verificar si el sistema está listo
  Future<bool> isSystemReady() async {
    try {
      await checkInternetConnection();
      await checkAndRequestPermissions();

      return _hasInternetConnection &&
          _hasNotificationPermission &&
          _hasSMSPermission;
    } catch (e) {
      _setError('Error verificando sistema: ${e.toString()}');
      return false;
    }
  }

  // Obtener información del sistema
  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      final connectionInfo = await ConnectivityService.getConnectionInfo();
      // final permissionStatus = await PermissionService.checkPermissionStatus();

      return {
        'connectivity': {
          'hasConnection': _hasInternetConnection,
          'connectionType': _connectionType,
          'responseTime': connectionInfo['responseTime'],
          'isStable': connectionInfo['isStable'],
        },
        'permissions': {
          'notifications': _hasNotificationPermission,
          'sms': _hasSMSPermission,
          'allGranted': await PermissionService.areAllPermissionsGranted(),
        },
        'systemReady': await isSystemReady(),
      };
    } catch (e) {
      return {
        'error': 'Error obteniendo información del sistema: ${e.toString()}',
        'systemReady': false,
      };
    }
  }

  // Escuchar cambios de conectividad
  void startConnectivityListener() {
    ConnectivityService.connectivityStream.listen((results) async {
      await checkInternetConnection();
    });
  }

  // Verificar permisos específicos
  Future<bool> checkSpecificPermission(String permission) async {
    try {
      final status = await PermissionService.checkPermissionStatus();

      switch (permission) {
        case 'notifications':
          return status['notifications'] ==
              permission_handler.PermissionStatus.granted;
        case 'sms':
          return status['sms'] == permission_handler.PermissionStatus.granted;
        default:
          return false;
      }
    } catch (e) {
      _setError('Error verificando permiso específico: ${e.toString()}');
      return false;
    }
  }

  // Abrir configuración de la aplicación
  Future<void> openAppSettings() async {
    try {
      await PermissionService.openAppSettings();
    } catch (e) {
      _setError('Error abriendo configuración: ${e.toString()}');
    }
  }

  // Obtener mensaje de estado del sistema
  String getSystemStatusMessage() {
    if (_isCheckingConnectivity || _isCheckingPermissions) {
      return 'Verificando sistema...';
    }

    if (!_hasInternetConnection) {
      return 'Sin conexión a Internet';
    }

    if (!_hasNotificationPermission) {
      return 'Permisos de notificaciones requeridos';
    }

    if (!_hasSMSPermission) {
      return 'Permisos de SMS requeridos';
    }

    return 'Sistema listo';
  }

  // Verificar si hay errores críticos
  bool hasCriticalErrors() {
    return !_hasInternetConnection ||
        !_hasNotificationPermission ||
        !_hasSMSPermission;
  }

  // Reiniciar verificación del sistema
  Future<void> restartSystemCheck() async {
    _clearError();
    await checkInternetConnection();
    await checkAndRequestPermissions();
  }

  void _setCheckingConnectivity(bool checking) {
    _isCheckingConnectivity = checking;
    notifyListeners();
  }

  void _setCheckingPermissions(bool checking) {
    _isCheckingPermissions = checking;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
