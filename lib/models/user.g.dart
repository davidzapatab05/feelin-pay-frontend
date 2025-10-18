// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  email: json['email'] as String,
  telefono: json['telefono'] as String,
  rol: json['rol'] as String,
  activo: json['activo'] as bool,
  emailVerificado: json['emailVerificado'] as bool,
  licenciaActiva: json['licenciaActiva'] as bool,
  fechaExpiracionLicencia: json['fechaExpiracionLicencia'] == null
      ? null
      : DateTime.parse(json['fechaExpiracionLicencia'] as String),
  enPeriodoPrueba: json['enPeriodoPrueba'] as bool,
  diasPruebaRestantes: (json['diasPruebaRestantes'] as num).toInt(),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'email': instance.email,
  'telefono': instance.telefono,
  'rol': instance.rol,
  'activo': instance.activo,
  'emailVerificado': instance.emailVerificado,
  'licenciaActiva': instance.licenciaActiva,
  'fechaExpiracionLicencia': instance.fechaExpiracionLicencia
      ?.toIso8601String(),
  'enPeriodoPrueba': instance.enPeriodoPrueba,
  'diasPruebaRestantes': instance.diasPruebaRestantes,
};
