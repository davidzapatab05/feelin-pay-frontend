import 'package:flutter/material.dart';
import '../services/feelin_pay_service.dart';
// StringUtils removed - using built-in string methods

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controllers para cada dígito del OTP
  final List<TextEditingController> _otpDigitControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  bool _otpSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();

    // Configurar listeners para los dígitos del OTP
    for (int i = 0; i < 6; i++) {
      _otpDigitControllers[i].addListener(() {
        _onOtpDigitChanged(i);
      });
    }

    // Listener para limpiar espacios del email en tiempo real
    _emailController.addListener(() {
      final text = _emailController.text;
      final cleanedText = text.trim().toLowerCase();
      if (text != cleanedText) {
        _emailController.value = _emailController.value.copyWith(
          text: cleanedText,
          selection: TextSelection.collapsed(offset: cleanedText.length),
        );
      }
    });
  }

  void _onOtpDigitChanged(int index) {
    String text = _otpDigitControllers[index].text;

    // Si se ingresó más de un dígito, tomar solo el último
    if (text.length > 1) {
      _otpDigitControllers[index].text = text.substring(text.length - 1);
    }

    // Si se ingresó un dígito y no es el último campo, mover al siguiente
    if (text.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    // Si se borró y no es el primer campo, mover al anterior
    if (text.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  String _getOtpCode() {
    return _otpDigitControllers.map((controller) => controller.text).join('');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // Limpiar controllers y focus nodes del OTP
    for (var controller in _otpDigitControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  Future<void> _solicitarRecuperacion() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingresa tu email';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      // Limpiar el email antes de enviarlo
      final emailLimpio = _emailController.text.trim().toLowerCase();

      // Actualizar el campo con el email limpio
      if (_emailController.text != emailLimpio) {
        _emailController.text = emailLimpio;
      }

      final result = await FeelinPayService.solicitarRecuperacionPassword(
        emailLimpio,
      );

      if (result['success']) {
        setState(() {
          _otpSent = true;
          _successMessage = 'Código de recuperación enviado a tu email';
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Error enviando código';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cambiarPassword() async {
    String otpCode = _getOtpCode();
    if (otpCode.length != 6) {
      setState(() {
        _errorMessage = 'El código debe tener 6 dígitos';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'La contraseña debe tener al menos 6 caracteres';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Las contraseñas no coinciden';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      // Usar el email limpio
      final emailLimpio = _emailController.text.trim().toLowerCase();

      final result = await FeelinPayService.cambiarPasswordConCodigo(
        emailLimpio,
        otpCode,
        _passwordController.text,
      );

      if (result['success']) {
        setState(() {
          _successMessage = 'Contraseña cambiada correctamente';
        });

        // Esperar un momento y regresar al login
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Error cambiando contraseña';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          width: isDesktop ? 500 : (isTablet ? 400 : double.infinity),
          padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono y título
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Recuperar Contraseña',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Te enviaremos un código para restablecer tu contraseña',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (!_otpSent) ...[
                // Paso 1: Solicitar email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'tu@email.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _solicitarRecuperacion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Enviar Código',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                // Paso 2: Ingresar código y nueva contraseña
                // Código OTP por dígitos individuales
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Código de Verificación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 45,
                          height: 55,
                          child: TextField(
                            controller: _otpDigitControllers[index],
                            focusNode: _otpFocusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Campo de nueva contraseña con ícono de ojo
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                  ),
                ),
                const SizedBox(height: 16),

                // Campo de confirmar contraseña con ícono de ojo
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _cambiarPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Cambiar Contraseña',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Mensajes
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_successMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage,
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Botón para volver al login
              Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text(
                    '¿Recordaste tu contraseña? Iniciar Sesión',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
