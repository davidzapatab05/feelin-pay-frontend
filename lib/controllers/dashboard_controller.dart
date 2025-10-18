import 'package:flutter/material.dart';
import '../services/feelin_pay_service.dart';

class DashboardController extends ChangeNotifier {
  Map<String, dynamic>? _userInfo;
  Map<String, dynamic>? _estadisticas;
  bool _isLoading = true;
  bool _puedeUsarBotonPrueba = false;
  bool _botonPruebaIlimitado = false;
  String _razonBotonPrueba = '';

  Map<String, dynamic>? get userInfo => _userInfo;
  Map<String, dynamic>? get estadisticas => _estadisticas;
  bool get isLoading => _isLoading;
  bool get puedeUsarBotonPrueba => _puedeUsarBotonPrueba;
  bool get botonPruebaIlimitado => _botonPruebaIlimitado;
  String get razonBotonPrueba => _razonBotonPrueba;

  Future<void> loadUserData() async {
    try {
      final userInfo = await FeelinPayService.getProfile();

      if (userInfo.containsKey('error') || userInfo['user'] == null) {
        await FeelinPayService.logout();
        return;
      }

      _userInfo = userInfo['user'];
      notifyListeners();

      await loadEstadisticas();
      await verificarBotonPrueba();
    } catch (e) {
      await FeelinPayService.logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEstadisticas() async {
    try {
      final stats = await FeelinPayService.obtenerEstadisticas(
        _userInfo?['id'] ?? '',
      );
      _estadisticas = stats;
      notifyListeners();
    } catch (e) {
      // Error cargando estadísticas
    }
  }

  Future<void> verificarBotonPrueba() async {
    try {
      final result = await FeelinPayService.verificarBotonPrueba(
        _userInfo?['id'] ?? '',
      );
      _puedeUsarBotonPrueba = result['puedeUsar'] ?? false;
      _botonPruebaIlimitado = result['ilimitado'] ?? false;
      _razonBotonPrueba = result['razon'] ?? '';
      notifyListeners();
    } catch (e) {
      // Error verificando botón de prueba
    }
  }

  Future<Map<String, dynamic>> abrirGoogleSheets() async {
    try {
      return await FeelinPayService.abrirGoogleSheets();
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> compartirGoogleSheets() async {
    try {
      return await FeelinPayService.compartirGoogleSheets();
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> llenarDatosPrueba() async {
    try {
      return await FeelinPayService.llenarDatosPrueba();
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> crearEstructuraSheets() async {
    try {
      return await FeelinPayService.crearEstructuraSheets();
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> procesarPagoPrueba() async {
    try {
      return await FeelinPayService.procesarPagoPrueba(
        propietarioId: _userInfo!['id'],
      );
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }
}
