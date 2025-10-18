/// Application constants
class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:3000/api';
  static const String apiVersion = 'v1';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String settingsKey = 'app_settings';
  static const String themeKey = 'theme_mode';

  // OTP Configuration
  static const int otpLength = 6;
  static const Duration otpExpiration = Duration(minutes: 10);
  static const int maxOtpAttempts = 3;
  static const int maxDailyOtpAttempts = 5;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 8.0;
  static const double defaultRadius = 8.0;
  static const double defaultElevation = 2.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Error Messages
  static const String networkErrorMessage = 'No hay conexión a internet';
  static const String serverErrorMessage = 'Error del servidor';
  static const String unknownErrorMessage = 'Error desconocido';
  static const String validationErrorMessage = 'Datos inválidos';

  // Success Messages
  static const String loginSuccessMessage = 'Inicio de sesión exitoso';
  static const String registerSuccessMessage = 'Registro exitoso';
  static const String otpSentMessage = 'Código OTP enviado';
  static const String otpVerifiedMessage = 'Código OTP verificado';
}
