import 'package:flutter/material.dart';
import '../services/feelin_pay_service.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  // Información del usuario
  Map<String, dynamic>? _usuario;

  // Controllers para formularios
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordActualController = TextEditingController();
  final _passwordNuevaController = TextEditingController();
  final _passwordConfirmarController = TextEditingController();
  final _nuevoEmailController = TextEditingController();
  final _codigoOtpController = TextEditingController();

  // Estados de formularios
  bool _mostrarFormularioNombre = false;
  bool _mostrarFormularioTelefono = false;
  bool _mostrarFormularioPassword = false;
  bool _mostrarFormularioEmail = false;
  bool _mostrarFormularioOtp = false;
  bool _mostrarPasswordActual = false;
  bool _mostrarPasswordNueva = false;
  bool _mostrarPasswordConfirmar = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _passwordActualController.dispose();
    _passwordNuevaController.dispose();
    _passwordConfirmarController.dispose();
    _nuevoEmailController.dispose();
    _codigoOtpController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await FeelinPayService.getProfile();
      if (result['success']) {
        setState(() {
          _usuario = result['usuario'];
          _nombreController.text = _usuario?['nombre'] ?? '';
          _telefonoController.text = _usuario?['telefono'] ?? '';
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Error cargando perfil';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _actualizarNombre() async {
    if (_nombreController.text.trim().isEmpty) {
      _mostrarError('El nombre no puede estar vacío');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await FeelinPayService.actualizarNombre(
        _nombreController.text.trim(),
      );
      if (result['success']) {
        setState(() {
          _mostrarFormularioNombre = false;
          _successMessage = 'Nombre actualizado correctamente';
        });
        await _cargarPerfil();
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Error actualizando nombre';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _actualizarTelefono() async {
    if (_telefonoController.text.trim().isEmpty) {
      _mostrarError('El teléfono no puede estar vacío');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await FeelinPayService.actualizarTelefono(
        _telefonoController.text.trim(),
      );
      if (result['success']) {
        setState(() {
          _mostrarFormularioTelefono = false;
          _successMessage = 'Teléfono actualizado correctamente';
        });
        await _cargarPerfil();
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Error actualizando teléfono';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cambiarPassword() async {
    if (_passwordActualController.text.isEmpty) {
      _mostrarError('La contraseña actual es requerida');
      return;
    }

    if (_passwordNuevaController.text.length < 8) {
      _mostrarError('La nueva contraseña debe tener al menos 8 caracteres');
      return;
    }

    if (_passwordNuevaController.text != _passwordConfirmarController.text) {
      _mostrarError('Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await FeelinPayService.cambiarPassword(
        _passwordActualController.text,
        _passwordNuevaController.text,
      );
      if (result['success']) {
        setState(() {
          _mostrarFormularioPassword = false;
          _passwordActualController.clear();
          _passwordNuevaController.clear();
          _passwordConfirmarController.clear();
          _successMessage = 'Contraseña actualizada correctamente';
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Error cambiando contraseña';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _solicitarCambioEmail() async {
    if (_nuevoEmailController.text.trim().isEmpty) {
      _mostrarError('El nuevo email es requerido');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await FeelinPayService.solicitarCambioEmail(
        _nuevoEmailController.text.trim(),
      );
      if (result['success']) {
        setState(() {
          _mostrarFormularioEmail = false;
          _mostrarFormularioOtp = true;
          _successMessage = 'Código de verificación enviado al nuevo email';
        });
      } else {
        setState(() {
          _errorMessage =
              result['error'] ?? 'Error solicitando cambio de email';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmarCambioEmail() async {
    if (_codigoOtpController.text.trim().isEmpty) {
      _mostrarError('El código de verificación es requerido');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await FeelinPayService.confirmarCambioEmail(
        _codigoOtpController.text.trim(),
      );
      if (result['success']) {
        setState(() {
          _mostrarFormularioOtp = false;
          _nuevoEmailController.clear();
          _codigoOtpController.clear();
          _successMessage = 'Email actualizado correctamente';
        });
        await _cargarPerfil();
      } else {
        setState(() {
          _errorMessage =
              result['error'] ?? 'Error confirmando cambio de email';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarError(String mensaje) {
    setState(() {
      _errorMessage = mensaje;
      _successMessage = '';
    });
  }

  void _limpiarMensajes() {
    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Perfil'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mensajes de estado
                  if (_errorMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                          ),
                          IconButton(
                            onPressed: _limpiarMensajes,
                            icon: Icon(Icons.close, color: Colors.red.shade600),
                          ),
                        ],
                      ),
                    ),

                  if (_successMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage,
                              style: TextStyle(color: Colors.green.shade600),
                            ),
                          ),
                          IconButton(
                            onPressed: _limpiarMensajes,
                            icon: Icon(
                              Icons.close,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Información del usuario
                  if (_usuario != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información del Usuario',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              'Nombre',
                              _usuario!['nombre'] ?? 'No especificado',
                            ),
                            _buildInfoRow(
                              'Email',
                              _usuario!['email'] ?? 'No especificado',
                            ),
                            _buildInfoRow(
                              'Teléfono',
                              _usuario!['telefono'] ?? 'No especificado',
                            ),
                            _buildInfoRow(
                              'Rol',
                              _getRolDisplayName(_usuario!['rol']),
                            ),
                            _buildInfoRow(
                              'Estado',
                              _usuario!['activo'] == true
                                  ? 'Activo'
                                  : 'Inactivo',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Sección de nombre
                  _buildSectionCard(
                    'Nombre',
                    _usuario?['nombre'] ?? 'No especificado',
                    Icons.person,
                    _mostrarFormularioNombre,
                    () => setState(
                      () =>
                          _mostrarFormularioNombre = !_mostrarFormularioNombre,
                    ),
                    _buildFormularioNombre(),
                  ),

                  const SizedBox(height: 16),

                  // Sección de teléfono
                  _buildSectionCard(
                    'Teléfono',
                    _usuario?['telefono'] ?? 'No especificado',
                    Icons.phone,
                    _mostrarFormularioTelefono,
                    () => setState(
                      () => _mostrarFormularioTelefono =
                          !_mostrarFormularioTelefono,
                    ),
                    _buildFormularioTelefono(),
                  ),

                  const SizedBox(height: 16),

                  // Sección de contraseña
                  _buildSectionCard(
                    'Contraseña',
                    '••••••••',
                    Icons.lock,
                    _mostrarFormularioPassword,
                    () => setState(
                      () => _mostrarFormularioPassword =
                          !_mostrarFormularioPassword,
                    ),
                    _buildFormularioPassword(),
                  ),

                  const SizedBox(height: 16),

                  // Sección de email
                  _buildSectionCard(
                    'Email',
                    _usuario?['email'] ?? 'No especificado',
                    Icons.email,
                    _mostrarFormularioEmail || _mostrarFormularioOtp,
                    () => setState(
                      () => _mostrarFormularioEmail = !_mostrarFormularioEmail,
                    ),
                    _mostrarFormularioOtp
                        ? _buildFormularioOtp()
                        : _buildFormularioEmail(),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    String value,
    IconData icon,
    bool isExpanded,
    VoidCallback onToggle,
    Widget? expandedContent,
  ) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(value),
            trailing: IconButton(
              onPressed: onToggle,
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            ),
          ),
          if (isExpanded && expandedContent != null) ...[
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.all(16), child: expandedContent),
          ],
        ],
      ),
    );
  }

  Widget _buildFormularioNombre() {
    return Column(
      children: [
        TextField(
          controller: _nombreController,
          decoration: const InputDecoration(
            labelText: 'Nuevo nombre',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => _mostrarFormularioNombre = false),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _actualizarNombre,
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormularioTelefono() {
    return Column(
      children: [
        TextField(
          controller: _telefonoController,
          decoration: const InputDecoration(
            labelText: 'Nuevo teléfono',
            border: OutlineInputBorder(),
            hintText: '+51999999999',
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () =>
                  setState(() => _mostrarFormularioTelefono = false),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _actualizarTelefono,
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormularioPassword() {
    return Column(
      children: [
        TextField(
          controller: _passwordActualController,
          decoration: InputDecoration(
            labelText: 'Contraseña actual',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: () => setState(
                () => _mostrarPasswordActual = !_mostrarPasswordActual,
              ),
              icon: Icon(
                _mostrarPasswordActual
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
            ),
          ),
          obscureText: !_mostrarPasswordActual,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordNuevaController,
          decoration: InputDecoration(
            labelText: 'Nueva contraseña',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: () => setState(
                () => _mostrarPasswordNueva = !_mostrarPasswordNueva,
              ),
              icon: Icon(
                _mostrarPasswordNueva ? Icons.visibility : Icons.visibility_off,
              ),
            ),
          ),
          obscureText: !_mostrarPasswordNueva,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordConfirmarController,
          decoration: InputDecoration(
            labelText: 'Confirmar nueva contraseña',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: () => setState(
                () => _mostrarPasswordConfirmar = !_mostrarPasswordConfirmar,
              ),
              icon: Icon(
                _mostrarPasswordConfirmar
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
            ),
          ),
          obscureText: !_mostrarPasswordConfirmar,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () =>
                  setState(() => _mostrarFormularioPassword = false),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _cambiarPassword,
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormularioEmail() {
    return Column(
      children: [
        TextField(
          controller: _nuevoEmailController,
          decoration: const InputDecoration(
            labelText: 'Nuevo email',
            border: OutlineInputBorder(),
            hintText: 'nuevo@email.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => _mostrarFormularioEmail = false),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _solicitarCambioEmail,
              child: const Text('Solicitar Cambio'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormularioOtp() {
    return Column(
      children: [
        Text(
          'Se ha enviado un código de verificación al email: ${_nuevoEmailController.text}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codigoOtpController,
          decoration: const InputDecoration(
            labelText: 'Código de verificación',
            border: OutlineInputBorder(),
            hintText: '123456',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() {
                _mostrarFormularioOtp = false;
                _mostrarFormularioEmail = false;
              }),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _confirmarCambioEmail,
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ],
    );
  }

  String _getRolDisplayName(Map<String, dynamic>? rol) {
    if (rol == null) return 'Sin rol';

    switch (rol['nombre']) {
      case 'super_admin':
        return 'Super Administrador';
      case 'propietario':
        return 'Propietario';
      default:
        return rol['nombre'] ?? 'Sin rol';
    }
  }
}
