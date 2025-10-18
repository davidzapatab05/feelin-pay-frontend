import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

/// Auth Controller - Controlador simple para autenticación
class AuthController extends ChangeNotifier {
  final ApiService _apiService = ApiService();

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
      final response = await _apiService.login(email, password);

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
      final response = await _apiService.register(
        nombre: nombre,
        telefono: telefono,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
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
      await _apiService.logout();
    } catch (e) {
      print('Error en logout: $e');
    } finally {
      _currentUser = null;
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Send OTP
  Future<bool> sendOTP(String email, String tipo) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.sendOTP(email, tipo);

      if (response['success'] == true) {
        return true;
      } else {
        _setError(response['message'] ?? 'Error enviando OTP');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify OTP
  Future<bool> verifyOTP(String email, String codigo, String tipo) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.verifyOTP(email, codigo, tipo);

      if (response) {
        return true;
      } else {
        _setError('Código OTP inválido');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get current user
  Future<void> getCurrentUser() async {
    if (_currentUser != null) return;

    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getCurrentUser();

      if (response != null) {
        _currentUser = response;
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
      // Verificar si hay token guardado
      final token = await _apiService.getStoredToken();
      if (token != null) {
        // Verificar token con el servidor
        final user = await _apiService.getCurrentUser();
        if (user != null) {
          _currentUser = user;
        }
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
      final result = await _apiService.verifyOTP(
        email,
        code,
        'LOGIN_VERIFICATION',
      );
      if (result) {
        // Actualizar usuario después de verificación
        await checkAuthStatus();
      }
      return result;
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
