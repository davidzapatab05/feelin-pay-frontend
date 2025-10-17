import 'package:json_annotation/json_annotation.dart';

part 'propietario.g.dart';

@JsonSerializable()
class Propietario {
  final String id;
  final String nombre;
  final String telefono;
  final String email;
  final double saldo;
  final String? googleSpreadsheetId;
  @JsonKey(name: 'fechaCreacion')
  final DateTime fechaCreacion;
  final List<Empleado>? empleados;
  final List<Pago>? pagos;
  final List<Licencia>? licencias;

  Propietario({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.email,
    required this.saldo,
    this.googleSpreadsheetId,
    required this.fechaCreacion,
    this.empleados,
    this.pagos,
    this.licencias,
  });

  factory Propietario.fromJson(Map<String, dynamic> json) =>
      _$PropietarioFromJson(json);
  Map<String, dynamic> toJson() => _$PropietarioToJson(this);
}

@JsonSerializable()
class Empleado {
  final String id;
  @JsonKey(name: 'propietarioId')
  final String propietarioId;
  final String nombre;
  @JsonKey(name: 'paisCodigo')
  final String paisCodigo;
  final String telefono;
  final String canal;
  final bool activo;
  final Propietario? propietario;

  Empleado({
    required this.id,
    required this.propietarioId,
    required this.nombre,
    required this.paisCodigo,
    required this.telefono,
    required this.canal,
    required this.activo,
    this.propietario,
  });

  factory Empleado.fromJson(Map<String, dynamic> json) =>
      _$EmpleadoFromJson(json);
  Map<String, dynamic> toJson() => _$EmpleadoToJson(this);
}

@JsonSerializable()
class Pago {
  final String id;
  @JsonKey(name: 'propietarioId')
  final String propietarioId;
  @JsonKey(name: 'clienteNombre')
  final String clienteNombre;
  final double monto;
  final DateTime fecha;
  @JsonKey(name: 'notificacionRaw')
  final String? notificacionRaw;
  @JsonKey(name: 'registradoEnSheets')
  final bool registradoEnSheets;
  @JsonKey(name: 'notificadoEmpleados')
  final bool notificadoEmpleados;
  final Propietario? propietario;

  Pago({
    required this.id,
    required this.propietarioId,
    required this.clienteNombre,
    required this.monto,
    required this.fecha,
    this.notificacionRaw,
    required this.registradoEnSheets,
    required this.notificadoEmpleados,
    this.propietario,
  });

  factory Pago.fromJson(Map<String, dynamic> json) => _$PagoFromJson(json);
  Map<String, dynamic> toJson() => _$PagoToJson(this);
}

@JsonSerializable()
class Licencia {
  final String codigo;
  @JsonKey(name: 'propietarioId')
  final String? propietarioId;
  final String tipo;
  @JsonKey(name: 'fechaEmision')
  final DateTime fechaEmision;
  @JsonKey(name: 'fechaExpiracion')
  final DateTime fechaExpiracion;
  final String firma;
  final Propietario? propietario;

  Licencia({
    required this.codigo,
    this.propietarioId,
    required this.tipo,
    required this.fechaEmision,
    required this.fechaExpiracion,
    required this.firma,
    this.propietario,
  });

  factory Licencia.fromJson(Map<String, dynamic> json) =>
      _$LicenciaFromJson(json);
  Map<String, dynamic> toJson() => _$LicenciaToJson(this);
}
