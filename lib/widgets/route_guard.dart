import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../services/route_guard_service.dart';

class RouteGuard extends StatelessWidget {
  final Widget child;
  final String route;

  const RouteGuard({super.key, required this.child, required this.route});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        final user = authController.currentUser;

        // Verificar si la ruta es pública
        if (RouteGuardService.isPublicRoute(route)) {
          return child;
        }

        // Verificar si el usuario está autenticado
        if (!authController.isLoggedIn) {
          return _buildAccessDeniedScreen(
            context,
            'Debes iniciar sesión para acceder a esta función',
            '/login',
          );
        }

        // Verificar si el usuario está verificado
        if (RouteGuardService.requiresVerification(route) &&
            !authController.isVerified) {
          return _buildAccessDeniedScreen(
            context,
            'Debes verificar tu email para acceder a esta función',
            '/login-otp',
            arguments: {'email': user!.email},
          );
        }

        // Verificar si requiere super admin
        if (RouteGuardService.requiresSuperAdmin(route) &&
            !authController.isSuperAdmin) {
          return _buildAccessDeniedScreen(
            context,
            'Solo los super administradores pueden acceder a esta función',
            '/dashboard',
          );
        }

        // Si todo está bien, mostrar el contenido
        return child;
      },
    );
  }

  Widget _buildAccessDeniedScreen(
    BuildContext context,
    String message,
    String redirectRoute, {
    Map<String, dynamic>? arguments,
  }) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de acceso denegado
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: Colors.red[600],
                ),
              ),

              const SizedBox(height: 32),

              // Título
              Text(
                'Acceso Restringido',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 16),

              // Mensaje
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Botón de acción
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (arguments != null) {
                      Navigator.pushNamed(
                        context,
                        redirectRoute,
                        arguments: arguments,
                      );
                    } else {
                      Navigator.pushNamed(context, redirectRoute);
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(_getButtonLabel(redirectRoute)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botón de retroceso
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getButtonLabel(String route) {
    switch (route) {
      case '/login':
        return 'Ir a Login';
      case '/login-otp':
        return 'Verificar Email';
      case '/dashboard':
        return 'Ir al Dashboard';
      default:
        return 'Continuar';
    }
  }
}
