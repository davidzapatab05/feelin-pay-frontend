import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../services/otp_attempt_service.dart';

class LoginOTPVerificationScreen extends StatefulWidget {
  final String email;

  const LoginOTPVerificationScreen({super.key, required this.email});

  @override
  State<LoginOTPVerificationScreen> createState() =>
      _LoginOTPVerificationScreenState();
}

class _LoginOTPVerificationScreenState
    extends State<LoginOTPVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isResending = false;
  int _attemptsLeft = 3;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    _loadAttemptsInfo();
  }

  Future<void> _loadAttemptsInfo() async {
    final attemptsInfo = await OTPAttemptService.getAttemptsInfo(widget.email);
    setState(() {
      _attemptsLeft = attemptsInfo['attemptsLeft'];
      _canResend = attemptsInfo['canAttempt'];
    });
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    if (_attemptsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Has excedido el número máximo de intentos. Intenta mañana.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authController = context.read<AuthController>();
    final success = await authController.verifyOTPAfterLogin(
      widget.email,
      _otpController.text.trim(),
    );

    if (success && mounted) {
      // OTP verificado exitosamente
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      // Error en la verificación - actualizar información de intentos
      await _loadAttemptsInfo();

      if (_attemptsLeft <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Has excedido el número máximo de intentos. Intenta mañana.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isResending = true;
    });

    try {
      final authController = context.read<AuthController>();
      await authController.sendOTP(widget.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código OTP reenviado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Deshabilitar reenvío por 60 segundos
      setState(() {
        _canResend = false;
      });

      Future.delayed(const Duration(seconds: 60), () {
        if (mounted) {
          setState(() {
            _canResend = true;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reenviando OTP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Verificación OTP'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shadowColor: Colors.black26,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AuthController>(
        builder: (context, authController, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono principal
                Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    Icons.security,
                    size: 60,
                    color: Colors.blue[600],
                  ),
                ),

                // Título
                Text(
                  'Verificación de Seguridad',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),

                const SizedBox(height: 16),

                // Subtítulo
                Text(
                  'Se ha enviado un código de verificación a:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),

                const SizedBox(height: 8),

                // Email
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.email,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Formulario OTP
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Código de Verificación',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          hintText: 'Ingresa el código de 6 dígitos',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa el código OTP';
                          }
                          if (value.length != 6) {
                            return 'El código debe tener 6 dígitos';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Información de intentos
                if (_attemptsLeft < 3)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _attemptsLeft <= 1
                          ? Colors.red[50]
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _attemptsLeft <= 1
                            ? Colors.red[200]!
                            : Colors.orange[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _attemptsLeft <= 1 ? Icons.warning : Icons.info,
                          color: _attemptsLeft <= 1
                              ? Colors.red[600]
                              : Colors.orange[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _attemptsLeft <= 1
                                ? 'Último intento. Si fallas, tendrás que esperar hasta mañana.'
                                : 'Intentos restantes: $_attemptsLeft',
                            style: TextStyle(
                              color: _attemptsLeft <= 1
                                  ? Colors.red[700]
                                  : Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Botón de verificación
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authController.isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authController.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Verificar Código',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Botón de reenvío
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _canResend && !_isResending ? _resendOTP : null,
                    icon: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(
                      _isResending
                          ? 'Reenviando...'
                          : _canResend
                          ? 'Reenviar Código'
                          : 'Espera 60 segundos',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Información adicional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Información Importante',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• El código OTP expira en 10 minutos\n'
                        '• Tienes 3 intentos para verificar el código\n'
                        '• Si excedes los intentos, podrás intentar mañana\n'
                        '• El código se reenvía cada 60 segundos',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
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

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
