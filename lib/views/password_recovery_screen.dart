import 'package:flutter/material.dart';
import '../services/feelin_pay_service.dart';
import '../widgets/otp_input_widget.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // OTP code
  String _otpCode = '';

  bool _isLoading = false;
  bool _otpSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _errorMessage = '';
  String _successMessage = '';

  // Focus control
  FocusNode? _passwordFocusNode;
  bool _passwordFieldHasFocus = false;

  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Inicializar FocusNode
    _passwordFocusNode = FocusNode();

    // Inicializar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Iniciar animaciones
    _animationController.forward();
    _slideController.forward();

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

    // Listener para mostrar validaciones de contraseña en tiempo real
    _passwordController.addListener(() {
      print(
        '🔍 [PASSWORD RECOVERY] Texto cambiado: "${_passwordController.text}"',
      );
      setState(() {
        // Forzar rebuild para mostrar/ocultar indicadores de requisitos
      });
    });

    // Listener para controlar el foco del campo de contraseña
    _passwordFocusNode?.addListener(() {
      print(
        '🔍 [PASSWORD RECOVERY] Focus cambiado: ${_passwordFocusNode?.hasFocus}',
      );
      setState(() {
        _passwordFieldHasFocus = _passwordFocusNode?.hasFocus ?? false;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode?.dispose();
    super.dispose();
  }

  void _onOtpChanged(String otp) {
    setState(() {
      _otpCode = otp;
    });
  }

  Future<void> _sendOTP() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingresa tu correo electrónico';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final result = await FeelinPayService.solicitarRecuperacionPassword(
        _emailController.text.trim(),
      );

      if (result['success'] == true) {
        setState(() {
          _otpSent = true;
          _successMessage = 'Código OTP enviado a tu correo electrónico';
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Error al enviar el código';
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

  Future<void> _resetPassword() async {
    print('🔍 [PASSWORD RECOVERY] Iniciando _resetPassword');
    print('🔍 [PASSWORD RECOVERY] OTP Code: $_otpCode');
    print('🔍 [PASSWORD RECOVERY] Email: ${_emailController.text}');
    print('🔍 [PASSWORD RECOVERY] Password: ${_passwordController.text}');

    if (_otpCode.length != 6) {
      setState(() {
        _errorMessage = 'Por favor ingresa el código OTP de 6 dígitos';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Las contraseñas no coinciden';
      });
      return;
    }

    if (_passwordController.text.length < 8) {
      setState(() {
        _errorMessage = 'La contraseña debe tener al menos 8 caracteres';
      });
      return;
    }

    if (!RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)',
    ).hasMatch(_passwordController.text)) {
      setState(() {
        _errorMessage =
            'La contraseña debe contener al menos una letra minúscula, una mayúscula y un número';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final result = await FeelinPayService.cambiarPasswordConCodigo(
        _emailController.text.trim(),
        _otpCode,
        _passwordController.text,
      );

      if (result['success'] == true) {
        setState(() {
          _successMessage = 'Contraseña restablecida exitosamente';
        });

        // Mostrar diálogo de éxito y regresar al login
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '¡Éxito!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Tu contraseña ha sido restablecida exitosamente. Ahora puedes iniciar sesión con tu nueva contraseña.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cerrar diálogo
                    Navigator.of(context).pop(); // Regresar al login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage =
              result['error'] ?? 'Error al restablecer la contraseña';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF64748B),
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Recuperar Contraseña',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Header con icono
                  _buildHeader(),

                  const SizedBox(height: 48),

                  // Card principal
                  _buildMainCard(),

                  const SizedBox(height: 32),

                  // Información adicional
                  _buildAdditionalInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Icono con gradiente
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.3),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.lock_reset, color: Colors.white, size: 40),
        ),

        const SizedBox(height: 24),

        const Text(
          'Recuperar Contraseña',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          _otpSent
              ? 'Ingresa el código que enviamos a tu correo'
              : 'Te enviaremos un código para restablecer tu contraseña',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_otpSent) ...[
            // Paso 1: Ingresar email
            _buildEmailStep(),
          ] else ...[
            // Paso 2: Ingresar OTP y nueva contraseña
            _buildOtpStep(),
          ],

          const SizedBox(height: 32),

          // Botón principal
          _buildMainButton(),

          // Mensajes de error/éxito
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildErrorMessage(),
          ],

          if (_successMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSuccessMessage(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Correo electrónico',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Ingresa tu correo electrónico',
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: Color(0xFF9CA3AF),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // OTP Input
        const Text(
          'Código de verificación',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 16),
        OtpInputWidget(
          onChanged: _onOtpChanged,
          onCompleted: (otp) => _onOtpChanged(otp),
        ),

        const SizedBox(height: 24),

        // Nueva contraseña
        const Text(
          'Nueva contraseña',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode ?? FocusNode(),
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Ingresa tu nueva contraseña',
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF9CA3AF),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
        ),

        // Indicador de requisitos de contraseña (solo si está enfocado, hay texto y no cumple todos los requisitos)
        if (_passwordFieldHasFocus &&
            _passwordController.text.isNotEmpty &&
            !_allPasswordRequirementsMet()) ...[
          // Debug logs
          Builder(
            builder: (context) {
              print(
                '🔍 [PASSWORD RECOVERY] Mostrando validaciones - Focus: $_passwordFieldHasFocus, Text: "${_passwordController.text}", AllMet: ${_allPasswordRequirementsMet()}',
              );
              return const SizedBox.shrink();
            },
          ),
          // Debug logs
          Builder(
            builder: (context) {
              print('🔍 [PASSWORD RECOVERY] Mostrando validaciones');
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),
          _buildPasswordRequirements(),
        ],

        const SizedBox(height: 16),

        // Confirmar contraseña
        const Text(
          'Confirmar contraseña',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            hintText: 'Confirma tu nueva contraseña',
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF9CA3AF),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : (_otpSent ? _resetPassword : _sendOTP),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667EEA),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _otpSent ? 'Restablecer Contraseña' : 'Enviar Código',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF16A34A),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _successMessage,
              style: const TextStyle(
                color: Color(0xFF16A34A),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      children: [
        if (_otpSent) ...[
          TextButton(
            onPressed: _sendOTP,
            child: const Text(
              '¿No recibiste el código? Reenviar',
              style: TextStyle(
                color: Color(0xFF667EEA),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        Text(
          'Si tienes problemas para acceder a tu cuenta, contacta con soporte técnico',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9CA3AF),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisitos de contraseña:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0369A1),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildPasswordRequirement(
            'Al menos 8 caracteres',
            _passwordController.text.length >= 8,
          ),
          _buildPasswordRequirement(
            'Una letra minúscula',
            RegExp(r'[a-z]').hasMatch(_passwordController.text),
          ),
          _buildPasswordRequirement(
            'Una letra mayúscula',
            RegExp(r'[A-Z]').hasMatch(_passwordController.text),
          ),
          _buildPasswordRequirement(
            'Un número',
            RegExp(r'\d').hasMatch(_passwordController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isMet ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? const Color(0xFF10B981) : const Color(0xFF6B7280),
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  bool _allPasswordRequirementsMet() {
    final password = _passwordController.text;
    return password.length >= 8 &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password);
  }
}
