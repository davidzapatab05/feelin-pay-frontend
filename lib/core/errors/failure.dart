/// Clase base para errores en la aplicación
abstract class Failure {
  final String message;
  final String? code;
  final dynamic details;

  const Failure({required this.message, this.code, this.details});

  @override
  String toString() => 'Failure: $message';
}

/// Error de red
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code, super.details});
}

/// Error de servidor
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code, super.details});
}

/// Error de validación
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code, super.details});
}

/// Error de autenticación
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code, super.details});
}

/// Error de permisos
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code, super.details});
}

/// Error de base de datos
class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code, super.details});
}

/// Error genérico
class GenericFailure extends Failure {
  const GenericFailure({required super.message, super.code, super.details});
}
