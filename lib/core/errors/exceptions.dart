/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message';
}

/// Network exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

/// Server exceptions
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(super.message, {super.code, this.statusCode});
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}

/// Permission exceptions
class PermissionException extends AppException {
  const PermissionException(super.message, {super.code});
}

/// OTP exceptions
class OtpException extends AppException {
  const OtpException(super.message, {super.code});
}

/// Timeout exceptions
class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.code});
}
