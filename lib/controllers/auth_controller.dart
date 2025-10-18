import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/feelin_pay_service.dart';
import '../services/session_service.dart';
import '../services/otp_attempt_service.dart';

class AuthController extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isVerified => _currentUser?.emailVerificado ?? false;
  bool get isSuperAdmin => _currentUser?.isSuperAdmin ?? false;

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await FeelinPayService.login(
        email: email,
        password: password,
      );

      if (result['success']) {
        _currentUser = User.fromJson(result['user']);

        // Verificar si el usuario ya está verificado
        if (_currentUser!.emailVerificado) {
          // Usuario verificado, login exitoso
          if (result.containsKey('token')) {
            await SessionService.saveToken(result['token']);
          }
          await SessionService.saveUser(result['user']);

          notifyListeners();
          return true;
        } else {
          // Usuario no verificado, necesita OTP
          await _sendOTP(email);
          _setError(
            'Se ha enviado un código OTP a tu correo. Por favor, verifica tu email.',
          );
          return false; // No completar login hasta verificar OTP
        }
      } else {
        _setError(result['message'] ?? 'Error al iniciar sesión');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Enviar OTP automáticamente
  Future<void> _sendOTP(String email) async {
    try {
      await FeelinPayService.reenviarCodigoOTP(email);
    } catch (e) {
      // Error enviando OTP
    }
  }

  // Enviar OTP (método público)
  Future<void> sendOTP(String email) async {
    try {
      await FeelinPayService.reenviarCodigoOTP(email);
    } catch (e) {
      // Error enviando OTP
    }
  }

  // Verificar OTP después del login
  Future<bool> verifyOTPAfterLogin(String email, String otpCode) async {
    _setLoading(true);
    _clearError();

    try {
      // Verificar si puede intentar OTP
      final canAttempt = await OTPAttemptService.canAttemptOTP(email);
      if (!canAttempt) {
        _setError('Has excedido el número máximo de intentos. Intenta mañana.');
        return false;
      }

      final result = await FeelinPayService.verificarCodigoOTP(
        email, // userId
        otpCode, // codigo
      );

      if (result['success']) {
        // OTP verificado, completar login
        _currentUser = User.fromJson(result['user']);

        // Marcar usuario como verificado
        _currentUser = User(
          id: _currentUser!.id,
          nombre: _currentUser!.nombre,
          email: _currentUser!.email,
          telefono: _currentUser!.telefono,
          rol: _currentUser!.rol,
          activo: _currentUser!.activo,
          emailVerificado: true, // Marcar como verificado
          licenciaActiva: _currentUser!.licenciaActiva,
          fechaExpiracionLicencia: _currentUser!.fechaExpiracionLicencia,
          enPeriodoPrueba: _currentUser!.enPeriodoPrueba,
          diasPruebaRestantes: _currentUser!.diasPruebaRestantes,
        );

        // Guardar sesión persistente
        if (result.containsKey('token')) {
          await SessionService.saveToken(result['token']);
        }
        await SessionService.saveUser(_currentUser!.toJson());

        // Limpiar intentos exitosos
        await OTPAttemptService.clearAttemptsForEmail(email);

        notifyListeners();
        return true;
      } else {
        // Registrar intento fallido
        final hasAttemptsLeft = await OTPAttemptService.recordFailedAttempt(
          email,
        );

        if (!hasAttemptsLeft) {
          _setError(
            'Has excedido el número máximo de intentos. Intenta mañana.',
          );
        } else {
          _setError(result['message'] ?? 'Código OTP inválido');
        }
        return false;
      }
    } catch (e) {
      _setError('Error verificando OTP: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register
  Future<bool> register({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await FeelinPayService.register(
        nombre: nombre,
        email: email,
        telefono: telefono,
        password: password,
      );

      if (result['success']) {
        return true;
      } else {
        _setError(result['message'] ?? 'Error al registrarse');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await FeelinPayService.logout();
      // Limpiar sesión persistente
      await SessionService.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Error al cerrar sesión: ${e.toString()}');
    }
  }

  // Check if user is logged in
  Future<void> checkAuthStatus() async {
    try {
      // Verificar sesión persistente primero
      final hasSession = await SessionService.isLoggedIn();

      if (hasSession) {
        // Obtener datos del usuario desde la sesión persistente
        final userData = await SessionService.getUser();
        if (userData != null) {
          _currentUser = User.fromJson(userData);
          // Actualizar última actividad
          await SessionService.updateLastActivity();
        } else {
          // Si no hay datos del usuario, intentar obtener del servicio
          final profileResult = await FeelinPayService.getProfile();
          if (profileResult.containsKey('user')) {
            _currentUser = User.fromJson(profileResult['user']);
            // Guardar en sesión persistente
            await SessionService.saveUser(profileResult['user']);
          }
        }
      } else {
        _currentUser = null;
      }
      notifyListeners();
    } catch (e) {
      _setError('Error verificando autenticación: ${e.toString()}');
    }
  }

  // Password recovery
  Future<bool> requestPasswordRecovery(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await FeelinPayService.solicitarRecuperacionPassword(
        email,
      );
      if (result['success']) {
        return true;
      } else {
        _setError(result['message'] ?? 'Error solicitando recuperación');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Change password with OTP
  Future<bool> changePasswordWithOTP({
    required String email,
    required String codigo,
    required String nuevaPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await FeelinPayService.cambiarPasswordConCodigo(
        email,
        codigo,
        nuevaPassword,
      );

      if (result['success']) {
        return true;
      } else {
        _setError(result['message'] ?? 'Error cambiando contraseña');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
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
