import '../models/user.dart';

class RouteGuardService {
  // Rutas públicas (no requieren autenticación)
  static const List<String> publicRoutes = [
    '/login',
    '/register',
    '/password-recovery',
    '/otp-verification',
    '/login-otp',
  ];

  // Rutas que requieren verificación de email
  static const List<String> verificationRequiredRoutes = [
    '/dashboard',
    '/user-management',
    '/permissions',
    '/system-check',
  ];

  // Rutas que requieren rol de super admin
  static const List<String> superAdminRoutes = ['/user-management'];

  // Rutas que requieren cualquier rol autenticado
  static const List<String> authenticatedRoutes = [
    '/dashboard',
    '/permissions',
    '/system-check',
  ];

  /// Verificar si una ruta es pública
  static bool isPublicRoute(String route) {
    return publicRoutes.contains(route);
  }

  /// Verificar si una ruta requiere verificación de email
  static bool requiresVerification(String route) {
    return verificationRequiredRoutes.contains(route);
  }

  /// Verificar si una ruta requiere rol de super admin
  static bool requiresSuperAdmin(String route) {
    return superAdminRoutes.contains(route);
  }

  /// Verificar si una ruta requiere autenticación
  static bool requiresAuthentication(String route) {
    return authenticatedRoutes.contains(route);
  }

  /// Verificar si el usuario puede acceder a una ruta
  static bool canAccessRoute(String route, User? user) {
    // Rutas públicas siempre accesibles
    if (isPublicRoute(route)) {
      return true;
    }

    // Si no hay usuario, no puede acceder a rutas protegidas
    if (user == null) {
      return false;
    }

    // Verificar si requiere autenticación
    if (requiresAuthentication(route)) {
      // Verificar si requiere verificación de email
      if (requiresVerification(route) && !user.emailVerificado) {
        return false;
      }

      // Verificar si requiere super admin
      if (requiresSuperAdmin(route) && !user.isSuperAdmin) {
        return false;
      }

      return true;
    }

    return false;
  }

  /// Obtener la ruta de redirección según el estado del usuario
  static String getRedirectRoute(User? user, String requestedRoute) {
    // Si no hay usuario, ir a login
    if (user == null) {
      return '/login';
    }

    // Si el usuario no está verificado y la ruta lo requiere
    if (requiresVerification(requestedRoute) && !user.emailVerificado) {
      return '/login-otp';
    }

    // Si la ruta requiere super admin y el usuario no lo es
    if (requiresSuperAdmin(requestedRoute) && !user.isSuperAdmin) {
      return '/dashboard'; // Redirigir al dashboard si no es super admin
    }

    // Si todo está bien, permitir acceso
    return requestedRoute;
  }

  /// Verificar si el usuario necesita verificación
  static bool needsVerification(User? user) {
    if (user == null) return false;
    return !user.emailVerificado;
  }

  /// Verificar si el usuario es super admin
  static bool isSuperAdmin(User? user) {
    if (user == null) return false;
    return user.isSuperAdmin;
  }

  /// Obtener mensaje de error según el tipo de restricción
  static String getAccessDeniedMessage(String route, User? user) {
    if (user == null) {
      return 'Debes iniciar sesión para acceder a esta función';
    }

    if (requiresVerification(route) && !user.emailVerificado) {
      return 'Debes verificar tu email para acceder a esta función';
    }

    if (requiresSuperAdmin(route) && !user.isSuperAdmin) {
      return 'Solo los super administradores pueden acceder a esta función';
    }

    return 'No tienes permisos para acceder a esta función';
  }
}
