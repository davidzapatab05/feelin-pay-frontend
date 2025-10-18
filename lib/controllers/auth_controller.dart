import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/feelin_pay_service.dart';

/// Auth Controller - Controlador simple para autenticación
class AuthController extends ChangeNotifier {
  // Usar FeelinPayService directamente

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoggedIn => _currentUser != null;
  bool get isVerified => _currentUser?.emailVerificado ?? false;
  bool get isSuperAdmin => _currentUser?.rol == 'super_admin';

  /// Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await FeelinPayService.login(
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        _currentUser = UserModel.fromJson(response['data']['user']);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Error en el login');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register
  Future<bool> register({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await FeelinPayService.register(
        nombre: nombre,
        telefono: telefono,
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        _currentUser = UserModel.fromJson(response['data']['user']);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Error en el registro');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await FeelinPayService.logout();
    } catch (e) {
      print('Error en logout: $e');
    } finally {
      _currentUser = null;
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Send OTP - Método no implementado
  Future<bool> sendOTP(String email, String tipo) async {
    _setLoading(true);
    _clearError();
    _setError('Método no implementado');
    _setLoading(false);
    return false;
  }

  /// Forgot Password - Método no implementado
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();
    _setError('Método no implementado');
    _setLoading(false);
    return false;
  }

  /// Reset Password
  Future<bool> resetPassword({
    required String email,
    required String codigo,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await FeelinPayService.cambiarPasswordConCodigo(
        email,
        codigo,
        newPassword,
      );

      if (response['success'] == true) {
        return true;
      } else {
        _setError(response['message'] ?? 'Error reseteando contraseña');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify OTP - Método no implementado
  Future<bool> verifyOTP(String email, String codigo, String tipo) async {
    _setLoading(true);
    _clearError();
    _setError('Método no implementado');
    _setLoading(false);
    return false;
  }

  /// Get current user
  Future<void> getCurrentUser() async {
    if (_currentUser != null) return;

    _setLoading(true);
    _clearError();

    try {
      final response = await FeelinPayService.getCurrentUser();

      if (response != null) {
        _currentUser = UserModel.fromJson(response);
        notifyListeners();
      }
    } catch (e) {
      _setError('Error obteniendo usuario: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Verificar estado de autenticación
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    try {
      // Verificar si hay usuario actual
      final user = await FeelinPayService.getCurrentUser();
      if (user != null) {
        _currentUser = UserModel.fromJson(user);
      }
    } catch (e) {
      _setError('Error verificando autenticación: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Verificar OTP después del login
  Future<bool> verifyOTPAfterLogin(String email, String code) async {
    _setLoading(true);
    _clearError();

    try {
      // Método no implementado
      _setError('Método no implementado');
      return false;
    } catch (e) {
      _setError('Error verificando OTP: $e');
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
