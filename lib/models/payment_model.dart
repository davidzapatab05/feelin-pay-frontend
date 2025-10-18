/// Payment Model - Modelo simple para pagos
class PaymentModel {
  final String id;
  final String propietarioId;
  final String nombrePagador;
  final double monto;
  final DateTime fecha;
  final String? codigoSeguridad;
  final bool registradoEnSheets;
  final bool notificadoEmpleados;
  final String? numeroTelefono;
  final DateTime createdAt;
  final DateTime? procesadoAt;

  const PaymentModel({
    required this.id,
    required this.propietarioId,
    required this.nombrePagador,
    required this.monto,
    required this.fecha,
    this.codigoSeguridad,
    required this.registradoEnSheets,
    required this.notificadoEmpleados,
    this.numeroTelefono,
    required this.createdAt,
    this.procesadoAt,
  });

  /// Crear desde JSON
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      propietarioId: json['propietarioId'] ?? '',
      nombrePagador: json['nombrePagador'] ?? '',
      monto: (json['monto'] ?? 0.0).toDouble(),
      fecha: DateTime.parse(json['fecha'] ?? DateTime.now().toIso8601String()),
      codigoSeguridad: json['codigoSeguridad'],
      registradoEnSheets: json['registradoEnSheets'] ?? false,
      notificadoEmpleados: json['notificadoEmpleados'] ?? false,
      numeroTelefono: json['numeroTelefono'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      procesadoAt: json['procesadoAt'] != null
          ? DateTime.parse(json['procesadoAt'])
          : null,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propietarioId': propietarioId,
      'nombrePagador': nombrePagador,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'codigoSeguridad': codigoSeguridad,
      'registradoEnSheets': registradoEnSheets,
      'notificadoEmpleados': notificadoEmpleados,
      'numeroTelefono': numeroTelefono,
      'createdAt': createdAt.toIso8601String(),
      'procesadoAt': procesadoAt?.toIso8601String(),
    };
  }

  /// Copiar con cambios
  PaymentModel copyWith({
    String? id,
    String? propietarioId,
    String? nombrePagador,
    double? monto,
    DateTime? fecha,
    String? codigoSeguridad,
    bool? registradoEnSheets,
    bool? notificadoEmpleados,
    String? numeroTelefono,
    DateTime? createdAt,
    DateTime? procesadoAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      propietarioId: propietarioId ?? this.propietarioId,
      nombrePagador: nombrePagador ?? this.nombrePagador,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      codigoSeguridad: codigoSeguridad ?? this.codigoSeguridad,
      registradoEnSheets: registradoEnSheets ?? this.registradoEnSheets,
      notificadoEmpleados: notificadoEmpleados ?? this.notificadoEmpleados,
      numeroTelefono: numeroTelefono ?? this.numeroTelefono,
      createdAt: createdAt ?? this.createdAt,
      procesadoAt: procesadoAt ?? this.procesadoAt,
    );
  }

  /// Obtener monto formateado
  String get formattedAmount => 'S/ ${monto.toStringAsFixed(2)}';

  /// Verificar si está procesado
  bool get isProcessed => procesadoAt != null;

  /// Obtener estado del pago
  String get status {
    if (isProcessed) return 'Procesado';
    if (registradoEnSheets) return 'Registrado';
    return 'Pendiente';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PaymentModel(id: $id, monto: $monto, fecha: $fecha)';
}
