import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import '../services/feelin_pay_service.dart';
import '../widgets/country_picker.dart';
import '../utils/string_utils.dart';
import 'dashboard_improved.dart';
import 'password_recovery_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLoginMode = true;
  Country? _selectedCountry;

  @override
  void initState() {
    super.initState();

    // Listener para limpiar automáticamente el email mientras se escribe
    _emailController.addListener(() {
      final currentText = _emailController.text;
      final cleanText = StringUtils.cleanEmail(currentText);
      if (currentText != cleanText) {
        _emailController.value = _emailController.value.copyWith(
          text: cleanText,
          selection: TextSelection.collapsed(offset: cleanText.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = StringUtils.cleanEmail(_emailController.text);
      final password = _passwordController.text;

      // Actualizar el campo de email con la versión limpia
      if (_emailController.text != email) {
        _emailController.text = email;
      }

      final result = await FeelinPayService.login(
        email: email,
        password: password,
      );

      if (result['success']) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        if (mounted) {
          // Solo limpiar la contraseña, no todo el formulario
          _passwordController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al iniciar sesión'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Solo limpiar la contraseña, no todo el formulario
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un país'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nombre = StringUtils.capitalizeWords(
        StringUtils.cleanString(_nombreController.text),
      );
      final email = StringUtils.cleanEmail(_emailController.text);
      // Combinar código de país + número
      final telefono =
          _selectedCountry!.dialCode +
          StringUtils.cleanPhoneNumber(_telefonoController.text);
      final password = _passwordController.text;

      // Validar datos
      if (!StringUtils.isValidEmail(email)) {
        throw Exception('Email inválido');
      }

      if (!StringUtils.isValidPhone(telefono)) {
        throw Exception('Número de teléfono inválido');
      }

      // Actualizar el campo de email con la versión limpia
      if (_emailController.text != email) {
        _emailController.text = email;
      }

      final result = await FeelinPayService.register(
        nombre: nombre,
        email: email,
        telefono: telefono,
        password: password,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registro exitoso. Verifica tu email para activar tu cuenta.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Cambiar a modo login
          setState(() {
            _isLoginMode = true;
            _clearForm();
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al registrarse'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _nombreController.clear();
    _telefonoController.clear();
    _selectedCountry = null;
  }

  Future<void> _forgotPassword() async {
    // Navegar a la pantalla de recuperación de contraseña
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PasswordRecoveryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;
    final maxWidth = isDesktop ? 500.0 : (isTablet ? 400.0 : double.infinity);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            width: maxWidth,
            padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // Logo y título
                    Icon(
                      Icons.payment,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Feelin Pay',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLoginMode
                          ? 'Inicia sesión en tu cuenta'
                          : 'Crea tu cuenta de propietario',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Campos del formulario
                    if (!_isLoginMode) ...[
                      // Campo nombre (solo en registro)
                      TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: ValidationBuilder()
                            .required('El nombre es requerido')
                            .minLength(
                              2,
                              'El nombre debe tener al menos 2 caracteres',
                            )
                            .build(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Campo email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El email es requerido';
                        }
                        final cleanEmail = StringUtils.cleanEmail(value);
                        if (!StringUtils.isValidEmail(cleanEmail)) {
                          return 'Ingresa un email válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo teléfono (solo en registro)
                    if (!_isLoginMode) ...[
                      // Campo teléfono con selector de país compacto
                      Row(
                        children: [
                          // Selector de país compacto
                          CountrySelector(
                            selectedCountry: _selectedCountry,
                            onCountrySelected: (country) {
                              setState(() {
                                _selectedCountry = country;
                              });
                            },
                            hintText: 'País',
                          ),
                          const SizedBox(width: 8),
                          // Campo de teléfono
                          Expanded(
                            child: TextFormField(
                              controller: _telefonoController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Número de teléfono',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: ValidationBuilder()
                                  .required('El teléfono es requerido')
                                  .minLength(
                                    8,
                                    'El teléfono debe tener al menos 8 dígitos',
                                  )
                                  .build(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Campo contraseña
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: ValidationBuilder()
                          .required('La contraseña es requerida')
                          .minLength(
                            6,
                            'La contraseña debe tener al menos 6 caracteres',
                          )
                          .build(),
                    ),

                    // Enlace "¿Olvidaste tu contraseña?" (solo en modo login)
                    if (_isLoginMode) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Botón principal
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_isLoginMode ? _login : _register),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isLoginMode ? 'Iniciar Sesión' : 'Registrarse',
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Botón para cambiar modo
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isLoginMode = !_isLoginMode;
                                _clearForm();
                              });
                            },
                      child: Text(
                        _isLoginMode
                            ? '¿No tienes cuenta? Regístrate'
                            : '¿Ya tienes cuenta? Inicia sesión',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
