import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String nombre;
  final String email;
  final String telefono;
  final String rol;
  final bool activo;
  final bool emailVerificado;
  final bool licenciaActiva;
  final DateTime? fechaExpiracionLicencia;
  final bool enPeriodoPrueba;
  final int diasPruebaRestantes;

  User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.rol,
    required this.activo,
    required this.emailVerificado,
    required this.licenciaActiva,
    this.fechaExpiracionLicencia,
    required this.enPeriodoPrueba,
    required this.diasPruebaRestantes,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  bool get isSuperAdmin => rol == 'super_admin';
  bool get isPropietario => rol == 'propietario';
  bool get isEmpleado => rol == 'empleado';
}
