import 'package:flutter/material.dart';
import '../services/feelin_pay_service.dart';
import '../widgets/otp_input_widget.dart';
import 'dashboard_improved.dart';

class LoginOTPVerificationScreen extends StatefulWidget {
  final String email;
  final String type; // 'registration' o 'login'

  const LoginOTPVerificationScreen({
    super.key,
    required this.email,
    this.type = 'login',
  });

  @override
  State<LoginOTPVerificationScreen> createState() =>
      _LoginOTPVerificationScreenState();
}

class _LoginOTPVerificationScreenState
    extends State<LoginOTPVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isResending = false;
  bool _isLoading = false;
  String _otpCode = '';

  void _onOtpChanged(String otp) {
    setState(() {
      _otpCode = otp;
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el código completo de 6 dígitos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Usar el servicio correcto según el tipo
      Map<String, dynamic> result;
      if (widget.type == 'registration') {
        result = await FeelinPayService.verifyRegistrationOTP(
          widget.email,
          _otpCode,
        );
      } else {
        result = await FeelinPayService.verifyLoginOTP(widget.email, _otpCode);
      }

      if (result['success'] == true && mounted) {
        // OTP verificado exitosamente
        if (widget.type == 'registration') {
          // Para registro, volver al login
          Navigator.pushReplacementNamed(context, '/login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Email verificado exitosamente. Ya puedes iniciar sesión.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Para login, ir al dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error verificando código'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isResending = true;
    });

    try {
      // Usar el servicio correcto según el tipo
      if (widget.type == 'registration') {
        await FeelinPayService.resendOTP(widget.email, 'EMAIL_VERIFICATION');
      } else {
        await FeelinPayService.resendOTP(widget.email, 'LOGIN_VERIFICATION');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código OTP reenviado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reenviando código: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Título
                  const Text(
                    'Verifica tu identidad',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Mensaje
                  Text(
                    'Hemos enviado un código de 6 dígitos a ${widget.email}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // OTP Input Widget
                  OtpInputWidget(
                    onChanged: _onOtpChanged,
                    onCompleted: (otp) {
                      _onOtpChanged(otp);
                      _verifyOTP();
                    },
                  ),

                  const SizedBox(height: 32),

                  // Botón verificar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón reenviar
                  TextButton(
                    onPressed: _isResending ? null : _resendOTP,
                    child: _isResending
                        ? const Text('Reenviando...')
                        : const Text('Reenviar código'),
                  ),

                  const SizedBox(height: 16),

                  // Información adicional
                  Text(
                    'No recibiste el código? Revisa tu carpeta de spam o reenvía el código.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 4),

                  // Información de expiración
                  Text(
                    'El código expira en 10 minutos',
                    style: TextStyle(fontSize: 11, color: Colors.orange[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
