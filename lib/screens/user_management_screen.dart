import 'package:flutter/material.dart';
import '../services/feelin_pay_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _usuarios = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _busqueda = '';
  String _filtroRol = '';
  bool _mostrarInhabilitados = false;
  int _paginaActual = 1;

  // Controllers para el formulario de nuevo usuario
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _busquedaController = TextEditingController();
  String _rolSeleccionado = 'propietario';
  bool _mostrarFormulario = false;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await FeelinPayService.obtenerUsuarios(
        busqueda: _busqueda,
        rol: _filtroRol,
        activo: _mostrarInhabilitados ? 'false' : 'true',
        pagina: _paginaActual,
        limite: 20,
      );

      if (result['success']) {
        setState(() {
          _usuarios = List<Map<String, dynamic>>.from(result['usuarios']);
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Error cargando usuarios';
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

  Future<void> _crearUsuario() async {
    if (_nombreController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _telefonoController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los campos son requeridos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FeelinPayService.crearUsuario(
        _nombreController.text,
        _emailController.text,
        _telefonoController.text,
        _passwordController.text,
        _rolSeleccionado,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario creado correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Limpiar formulario
        _nombreController.clear();
        _emailController.clear();
        _telefonoController.clear();
        _passwordController.clear();
        _mostrarFormulario = false;

        // Recargar usuarios
        await _cargarUsuarios();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Error creando usuario'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editarUsuario(Map<String, dynamic> usuario) async {
    // Llenar el formulario con los datos del usuario
    _nombreController.text = usuario['nombre'] ?? '';
    _emailController.text = usuario['email'] ?? '';
    _telefonoController.text = usuario['telefono'] ?? '';
    _rolSeleccionado = usuario['rol'] ?? 'propietario';

    setState(() {
      _mostrarFormulario = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modifica los datos y guarda los cambios'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _eliminarUsuario(String usuarioId, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar desactivación'),
        content: Text(
          '¿Estás seguro de que quieres desactivar al usuario $nombre?\n\nEl usuario no podrá acceder al sistema pero sus datos se mantendrán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await FeelinPayService.eliminarUsuario(usuarioId);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario desactivado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          await _cargarUsuarios();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Error desactivando usuario'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reactivarUsuario(String usuarioId, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar reactivación'),
        content: Text(
          '¿Estás seguro de que quieres reactivar al usuario $nombre?\n\nEl usuario podrá acceder al sistema nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await FeelinPayService.reactivarUsuario(usuarioId);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario reactivado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          await _cargarUsuarios();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Error reactivando usuario'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Filtros
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Barra de búsqueda
                    TextField(
                      controller: _busquedaController,
                      decoration: InputDecoration(
                        hintText: 'Buscar usuarios...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _busqueda.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _busquedaController.clear();
                                  setState(() {
                                    _busqueda = '';
                                    _paginaActual = 1;
                                  });
                                  _cargarUsuarios();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _busqueda = value;
                          _paginaActual = 1;
                        });
                        // Debounce para evitar muchas consultas
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (_busqueda == value) {
                            _cargarUsuarios();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Filtros
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _filtroRol.isEmpty ? null : _filtroRol,
                            decoration: const InputDecoration(
                              labelText: 'Filtrar por rol',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: '',
                                child: Text('Todos los roles'),
                              ),
                              DropdownMenuItem(
                                value: 'super_admin',
                                child: Text('Super Admin'),
                              ),
                              DropdownMenuItem(
                                value: 'propietario',
                                child: Text('Propietario'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _filtroRol = value ?? '';
                                _paginaActual = 1;
                              });
                              _cargarUsuarios();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _mostrarInhabilitados = !_mostrarInhabilitados;
                              _paginaActual = 1;
                            });
                            _cargarUsuarios();
                          },
                          icon: Icon(
                            _mostrarInhabilitados
                                ? Icons.people
                                : Icons.people_outline,
                          ),
                          label: Text(
                            _mostrarInhabilitados
                                ? 'Ver Activos'
                                : 'Ver Inhabilitados',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mostrarInhabilitados
                                ? Colors.orange
                                : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _mostrarFormulario = !_mostrarFormulario;
          });
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(_mostrarFormulario ? Icons.close : Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Formulario de nuevo usuario
                if (_mostrarFormulario) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Crear Nuevo Usuario',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _rolSeleccionado,
                          decoration: const InputDecoration(
                            labelText: 'Rol',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.admin_panel_settings),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'super_admin',
                              child: Text('Super Administrador'),
                            ),
                            DropdownMenuItem(
                              value: 'propietario',
                              child: Text('Propietario'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _rolSeleccionado = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _crearUsuario,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Crear Usuario'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _mostrarFormulario = false;
                                  });
                                },
                                child: const Text('Cancelar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Lista de usuarios
                Expanded(
                  child: _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error,
                                size: 64,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _cargarUsuarios,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : _usuarios.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay usuarios registrados',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _usuarios.length,
                          itemBuilder: (context, index) {
                            final usuario = _usuarios[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getRolColor(usuario['rol']),
                                  child: Icon(
                                    _getRolIcon(usuario['rol']),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(usuario['nombre'] ?? 'Sin nombre'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(usuario['email'] ?? 'Sin email'),
                                    Text(
                                      'Rol: ${_getRolDisplayName(usuario['rol'])}',
                                      style: TextStyle(
                                        color: _getRolColor(usuario['rol']),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        _editarUsuario(usuario);
                                      },
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'Editar usuario',
                                    ),
                                    if (_mostrarInhabilitados)
                                      IconButton(
                                        onPressed: () {
                                          _reactivarUsuario(
                                            usuario['id'],
                                            usuario['nombre'],
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.restore,
                                          color: Colors.green,
                                        ),
                                        tooltip: 'Reactivar usuario',
                                      )
                                    else
                                      IconButton(
                                        onPressed: () {
                                          _eliminarUsuario(
                                            usuario['id'],
                                            usuario['nombre'],
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Eliminar usuario',
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Color _getRolColor(String? rol) {
    switch (rol) {
      case 'super_admin':
        return Colors.red;
      case 'propietario':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRolIcon(String? rol) {
    switch (rol) {
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'propietario':
        return Icons.business;
      default:
        return Icons.person_outline;
    }
  }

  String _getRolDisplayName(String? rol) {
    switch (rol) {
      case 'super_admin':
        return 'Super Administrador';
      case 'propietario':
        return 'Propietario';
      default:
        return 'Sin rol';
    }
  }
}
