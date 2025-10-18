import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/system_controller.dart';

class SystemCheckScreen extends StatefulWidget {
  const SystemCheckScreen({super.key});

  @override
  State<SystemCheckScreen> createState() => _SystemCheckScreenState();
}

class _SystemCheckScreenState extends State<SystemCheckScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSystem();
    });
  }

  Future<void> _checkSystem() async {
    final systemController = context.read<SystemController>();
    await systemController.checkInternetConnection();
    await systemController.checkAndRequestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<SystemController>(
        builder: (context, systemController, child) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono principal
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: systemController.hasCriticalErrors()
                          ? Colors.red[100]
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      systemController.hasCriticalErrors()
                          ? Icons.warning_rounded
                          : Icons.check_circle_rounded,
                      size: 60,
                      color: systemController.hasCriticalErrors()
                          ? Colors.red[600]
                          : Colors.green[600],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Título
                  Text(
                    'Verificación del Sistema',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Subtítulo
                  Text(
                    'Verificando conectividad y permisos necesarios',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Estado de conectividad
                  _buildStatusCard(
                    icon: Icons.wifi,
                    title: 'Conexión a Internet',
                    status: systemController.hasInternetConnection,
                    isLoading: systemController.isCheckingConnectivity,
                    connectionType: systemController.connectionType,
                  ),

                  const SizedBox(height: 16),

                  // Estado de notificaciones
                  _buildStatusCard(
                    icon: Icons.notifications,
                    title: 'Permisos de Notificaciones',
                    status: systemController.hasNotificationPermission,
                    isLoading: systemController.isCheckingPermissions,
                  ),

                  const SizedBox(height: 16),

                  // Estado de SMS
                  _buildStatusCard(
                    icon: Icons.sms,
                    title: 'Permisos de SMS',
                    status: systemController.hasSMSPermission,
                    isLoading: systemController.isCheckingPermissions,
                  ),

                  const SizedBox(height: 48),

                  // Mensaje de estado
                  if (systemController.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              systemController.errorMessage!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Botones de acción
                  if (systemController.hasCriticalErrors()) ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        await systemController.restartSystemCheck();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Verificar Nuevamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: () async {
                        await systemController.openAppSettings();
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Abrir Configuración'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continuar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Información adicional
                  Text(
                    'La aplicación requiere:\n• Conexión a Internet\n• Permisos de notificaciones\n• Permisos de SMS',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required bool status,
    required bool isLoading,
    String? connectionType,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status ? Colors.green[200]! : Colors.red[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: status ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    status ? Icons.check : Icons.close,
                    color: status ? Colors.green[600] : Colors.red[600],
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (connectionType != null && connectionType != 'Unknown')
                  Text(
                    connectionType,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                if (isLoading)
                  Text(
                    'Verificando...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  )
                else
                  Text(
                    status ? 'Concedido' : 'Requerido',
                    style: TextStyle(
                      color: status ? Colors.green[600] : Colors.red[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            icon,
            color: status ? Colors.green[600] : Colors.red[600],
            size: 24,
          ),
        ],
      ),
    );
  }
}
