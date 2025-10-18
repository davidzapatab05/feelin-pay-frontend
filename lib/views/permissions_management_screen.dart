import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/system_controller.dart';

class PermissionsManagementScreen extends StatefulWidget {
  const PermissionsManagementScreen({super.key});

  @override
  State<PermissionsManagementScreen> createState() =>
      _PermissionsManagementScreenState();
}

class _PermissionsManagementScreenState
    extends State<PermissionsManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  Future<void> _checkPermissions() async {
    final systemController = context.read<SystemController>();
    await systemController.checkInternetConnection();
    await systemController.checkAndRequestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Permisos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shadowColor: Colors.black26,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: Consumer<SystemController>(
        builder: (context, systemController, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  'Estado del Sistema',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Verifica y gestiona los permisos necesarios para el funcionamiento de la aplicación',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),

                const SizedBox(height: 24),

                // Estado de conectividad
                _buildStatusCard(
                  icon: Icons.wifi,
                  title: 'Conexión a Internet',
                  status: systemController.hasInternetConnection,
                  isLoading: systemController.isCheckingConnectivity,
                  connectionType: systemController.connectionType,
                  description:
                      'Necesario para sincronizar datos y enviar notificaciones',
                ),

                const SizedBox(height: 16),

                // Estado de notificaciones
                _buildStatusCard(
                  icon: Icons.notifications,
                  title: 'Permisos de Notificaciones',
                  status: systemController.hasNotificationPermission,
                  isLoading: systemController.isCheckingPermissions,
                  description:
                      'Permite recibir notificaciones de pagos y actualizaciones',
                ),

                const SizedBox(height: 16),

                // Estado de SMS
                _buildStatusCard(
                  icon: Icons.sms,
                  title: 'Permisos de SMS',
                  status: systemController.hasSMSPermission,
                  isLoading: systemController.isCheckingPermissions,
                  description:
                      'Necesario para enviar confirmaciones de pago a empleados',
                ),

                const SizedBox(height: 32),

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

                const SizedBox(height: 24),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await systemController.restartSystemCheck();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Verificar Nuevamente'),
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

                    const SizedBox(width: 16),

                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await systemController.openAppSettings();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Configuración'),
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

                const SizedBox(height: 24),

                // Información adicional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Información Importante',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• La aplicación requiere conexión a Internet para funcionar correctamente\n'
                        '• Los permisos de notificaciones permiten recibir alertas de pagos\n'
                        '• Los permisos de SMS son necesarios para notificar a empleados\n'
                        '• Puedes modificar estos permisos en la configuración del dispositivo',
                        style: TextStyle(color: Colors.blue[700], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
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
    required String description,
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
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
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
