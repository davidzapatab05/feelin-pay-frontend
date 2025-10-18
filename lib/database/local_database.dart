import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _database;
  static const String _databaseName = 'feelin_pay_local.db';
  static const int _databaseVersion = 1;

  // Tablas
  static const String _usuariosTable = 'usuarios';
  static const String _empleadosTable = 'empleados';
  static const String _pagosTable = 'pagos';
  static const String _licenciasTable = 'licencias';
  static const String _auditoriaLogsTable = 'auditoria_logs';
  static const String _otpCodesTable = 'otp_codes';
  static const String _otpAttemptsTable = 'otp_attempts';
  static const String _notificacionesTable = 'notificaciones_yape';
  static const String _smsTable = 'sms_enviados';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    // Configurar para Windows/Linux/macOS
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final path = join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE $_usuariosTable (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        telefono TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        rolId TEXT NOT NULL,
        googleSpreadsheetId TEXT,
        activo INTEGER DEFAULT 1,
        creadoPor TEXT,
        licenciaActiva INTEGER DEFAULT 0,
        fechaExpiracionLicencia TEXT,
        codigoLicencia TEXT,
        enPeriodoPrueba INTEGER DEFAULT 0,
        fechaInicioPrueba TEXT,
        diasPruebaRestantes INTEGER DEFAULT 0,
        emailVerificado INTEGER DEFAULT 0,
        emailVerificadoAt TEXT,
        otpAttemptsToday INTEGER DEFAULT 0,
        lastOtpAttemptDate TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        lastLoginAt TEXT,
        loginAttempts INTEGER DEFAULT 0,
        lockedUntil TEXT
      )
    ''');

    // Tabla de empleados
    await db.execute('''
      CREATE TABLE $_empleadosTable (
        id TEXT PRIMARY KEY,
        propietarioId TEXT NOT NULL,
        paisCodigo TEXT NOT NULL,
        telefono TEXT NOT NULL,
        activo INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (propietarioId) REFERENCES $_usuariosTable (id)
      )
    ''');

    // Tabla de pagos
    await db.execute('''
      CREATE TABLE $_pagosTable (
        id TEXT PRIMARY KEY,
        propietarioId TEXT NOT NULL,
        nombrePagador TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        codigoSeguridad TEXT,
        registradoEnSheets INTEGER DEFAULT 0,
        notificadoEmpleados INTEGER DEFAULT 0,
        hashNotificacion TEXT UNIQUE,
        numeroTelefono TEXT,
        mensajeOriginal TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        procesadoAt TEXT,
        FOREIGN KEY (propietarioId) REFERENCES $_usuariosTable (id)
      )
    ''');

    // Tabla de notificaciones de Yape
    await db.execute('''
      CREATE TABLE $_notificacionesTable (
        id TEXT PRIMARY KEY,
        propietarioId TEXT NOT NULL,
        mensajeOriginal TEXT NOT NULL,
        nombrePagador TEXT,
        monto REAL,
        codigoSeguridad TEXT,
        numeroTelefono TEXT,
        fechaNotificacion TEXT NOT NULL,
        procesado INTEGER DEFAULT 0,
        hashNotificacion TEXT UNIQUE,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (propietarioId) REFERENCES $_usuariosTable (id)
      )
    ''');

    // Tabla de licencias
    await db.execute('''
      CREATE TABLE $_licenciasTable (
        codigo TEXT PRIMARY KEY,
        propietarioId TEXT,
        tipo TEXT NOT NULL,
        fechaEmision TEXT NOT NULL,
        fechaExpiracion TEXT NOT NULL,
        activa INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        activadaAt TEXT,
        creadoPor TEXT,
        FOREIGN KEY (propietarioId) REFERENCES $_usuariosTable (id)
      )
    ''');

    // Tabla de auditoría logs
    await db.execute('''
      CREATE TABLE $_auditoriaLogsTable (
        id TEXT PRIMARY KEY,
        usuarioId TEXT NOT NULL,
        accion TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        metadata TEXT,
        resultado TEXT NOT NULL,
        ipAddress TEXT,
        userAgent TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (usuarioId) REFERENCES $_usuariosTable (id)
      )
    ''');

    // Tabla de códigos OTP
    await db.execute('''
      CREATE TABLE $_otpCodesTable (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        codigo TEXT NOT NULL,
        tipo TEXT NOT NULL,
        expiraEn TEXT NOT NULL,
        usado INTEGER DEFAULT 0,
        intentos INTEGER DEFAULT 0,
        maxIntentos INTEGER DEFAULT 3,
        metadata TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Tabla de intentos OTP
    await db.execute('''
      CREATE TABLE $_otpAttemptsTable (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        intentosHoy INTEGER DEFAULT 0,
        fechaUltimoIntento TEXT,
        bloqueadoHasta TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Tabla de SMS enviados
    await db.execute('''
      CREATE TABLE $_smsTable (
        id TEXT PRIMARY KEY,
        empleadoId TEXT NOT NULL,
        pagoId TEXT NOT NULL,
        mensaje TEXT NOT NULL,
        numeroDestino TEXT NOT NULL,
        enviado INTEGER DEFAULT 0,
        fechaEnvio TEXT,
        error TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (empleadoId) REFERENCES $_empleadosTable (id),
        FOREIGN KEY (pagoId) REFERENCES $_pagosTable (id)
      )
    ''');

    // Índices
    await db.execute(
      'CREATE INDEX idx_usuarios_email ON $_usuariosTable (email)',
    );
    await db.execute(
      'CREATE INDEX idx_usuarios_activo ON $_usuariosTable (activo)',
    );
    await db.execute(
      'CREATE INDEX idx_usuarios_rolId ON $_usuariosTable (rolId)',
    );
    await db.execute(
      'CREATE INDEX idx_usuarios_createdAt ON $_usuariosTable (createdAt)',
    );
    await db.execute(
      'CREATE INDEX idx_empleados_propietario ON $_empleadosTable (propietarioId)',
    );
    await db.execute(
      'CREATE INDEX idx_pagos_propietario ON $_pagosTable (propietarioId)',
    );
    await db.execute('CREATE INDEX idx_pagos_fecha ON $_pagosTable (fecha)');
    await db.execute(
      'CREATE INDEX idx_pagos_registradoEnSheets ON $_pagosTable (registradoEnSheets)',
    );
    await db.execute(
      'CREATE INDEX idx_pagos_hashNotificacion ON $_pagosTable (hashNotificacion)',
    );
    await db.execute(
      'CREATE INDEX idx_licencias_propietario ON $_licenciasTable (propietarioId)',
    );
    await db.execute(
      'CREATE INDEX idx_auditoria_usuario ON $_auditoriaLogsTable (usuarioId)',
    );
    await db.execute(
      'CREATE INDEX idx_otp_codes_email ON $_otpCodesTable (email)',
    );
    await db.execute(
      'CREATE INDEX idx_otp_codes_expiraEn ON $_otpCodesTable (expiraEn)',
    );
    await db.execute(
      'CREATE INDEX idx_otp_attempts_email ON $_otpAttemptsTable (email)',
    );
    await db.execute(
      'CREATE INDEX idx_notificaciones_propietario ON $_notificacionesTable (propietarioId)',
    );
    await db.execute(
      'CREATE INDEX idx_notificaciones_procesado ON $_notificacionesTable (procesado)',
    );
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Implementar migraciones si es necesario
  }

  // ==================== USUARIOS ====================

  static Future<String> createUsuario(Map<String, dynamic> usuario) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert(_usuariosTable, {
      'id': id,
      'nombre': usuario['nombre'],
      'telefono': usuario['telefono'],
      'email': usuario['email'],
      'password': usuario['password'],
      'rolId': usuario['rolId'],
      'googleSpreadsheetId': usuario['googleSpreadsheetId'],
      'activo': usuario['activo'] ? 1 : 0,
      'creadoPor': usuario['creadoPor'],
      'licenciaActiva': usuario['licenciaActiva'] ? 1 : 0,
      'fechaExpiracionLicencia': usuario['fechaExpiracionLicencia']
          ?.toIso8601String(),
      'codigoLicencia': usuario['codigoLicencia'],
      'enPeriodoPrueba': usuario['enPeriodoPrueba'] ? 1 : 0,
      'fechaInicioPrueba': usuario['fechaInicioPrueba']?.toIso8601String(),
      'diasPruebaRestantes': usuario['diasPruebaRestantes'] ?? 0,
      'emailVerificado': usuario['emailVerificado'] ? 1 : 0,
      'emailVerificadoAt': usuario['emailVerificadoAt']?.toIso8601String(),
      'otpAttemptsToday': usuario['otpAttemptsToday'] ?? 0,
      'lastOtpAttemptDate': usuario['lastOtpAttemptDate']?.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'lastLoginAt': usuario['lastLoginAt']?.toIso8601String(),
      'loginAttempts': usuario['loginAttempts'] ?? 0,
      'lockedUntil': usuario['lockedUntil']?.toIso8601String(),
    });

    return id;
  }

  static Future<Map<String, dynamic>?> getUsuarioByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      _usuariosTable,
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      final usuario = result.first;
      // Convertir enteros a booleanos
      usuario['activo'] = usuario['activo'] == 1;
      usuario['licenciaActiva'] = usuario['licenciaActiva'] == 1;
      usuario['enPeriodoPrueba'] = usuario['enPeriodoPrueba'] == 1;
      usuario['emailVerificado'] = usuario['emailVerificado'] == 1;
      return usuario;
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getUsuarios() async {
    final db = await database;
    final result = await db.query(_usuariosTable);

    // Convertir enteros a booleanos
    for (var usuario in result) {
      usuario['activo'] = usuario['activo'] == 1;
      usuario['licenciaActiva'] = usuario['licenciaActiva'] == 1;
      usuario['enPeriodoPrueba'] = usuario['enPeriodoPrueba'] == 1;
      usuario['emailVerificado'] = usuario['emailVerificado'] == 1;
    }

    return result;
  }

  // ==================== EMPLEADOS ====================

  static Future<String> createEmpleado(Map<String, dynamic> empleado) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert(_empleadosTable, {
      'id': id,
      'propietarioId': empleado['propietarioId'],
      'paisCodigo': empleado['paisCodigo'],
      'telefono': empleado['telefono'],
      'activo': empleado['activo'] ? 1 : 0,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    return id;
  }

  static Future<List<Map<String, dynamic>>> getEmpleadosByPropietario(
    String propietarioId,
  ) async {
    final db = await database;
    final result = await db.query(
      _empleadosTable,
      where: 'propietarioId = ? AND activo = 1',
      whereArgs: [propietarioId],
    );

    // Convertir enteros a booleanos
    for (var empleado in result) {
      empleado['activo'] = empleado['activo'] == 1;
    }

    return result;
  }

  // ==================== LICENCIAS ====================

  static Future<String> createLicencia(Map<String, dynamic> licencia) async {
    final db = await database;

    await db.insert(_licenciasTable, {
      'codigo': licencia['codigo'],
      'propietarioId': licencia['propietarioId'],
      'tipo': licencia['tipo'],
      'fechaEmision': licencia['fechaEmision'],
      'fechaExpiracion': licencia['fechaExpiracion'],
      'activa': licencia['activa'] ? 1 : 0,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'activadaAt': licencia['activadaAt']?.toIso8601String(),
      'creadoPor': licencia['creadoPor'],
    });

    return licencia['codigo'];
  }

  static Future<List<Map<String, dynamic>>> getLicenciasByPropietario(
    String propietarioId,
  ) async {
    final db = await database;
    final result = await db.query(
      _licenciasTable,
      where: 'propietarioId = ?',
      whereArgs: [propietarioId],
      orderBy: 'fechaEmision DESC',
    );

    // Convertir enteros a booleanos
    for (var licencia in result) {
      licencia['activa'] = licencia['activa'] == 1;
    }

    return result;
  }

  // ==================== AUDITORÍA ====================

  static Future<String> createAuditoriaLog(Map<String, dynamic> log) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert(_auditoriaLogsTable, {
      'id': id,
      'usuarioId': log['usuarioId'],
      'accion': log['accion'],
      'descripcion': log['descripcion'],
      'metadata': log['metadata'],
      'resultado': log['resultado'],
      'ipAddress': log['ipAddress'],
      'userAgent': log['userAgent'],
      'createdAt': DateTime.now().toIso8601String(),
    });

    return id;
  }

  static Future<List<Map<String, dynamic>>> getAuditoriaLogsByUsuario(
    String usuarioId,
  ) async {
    final db = await database;
    final result = await db.query(
      _auditoriaLogsTable,
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
      orderBy: 'createdAt DESC',
    );

    return result;
  }

  // ==================== OTP CODES ====================

  static Future<String> createOtpCode(Map<String, dynamic> otp) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert(_otpCodesTable, {
      'id': id,
      'email': otp['email'],
      'codigo': otp['codigo'],
      'tipo': otp['tipo'],
      'expiraEn': otp['expiraEn'],
      'usado': otp['usado'] ? 1 : 0,
      'intentos': otp['intentos'] ?? 0,
      'maxIntentos': otp['maxIntentos'] ?? 3,
      'metadata': otp['metadata'],
      'createdAt': DateTime.now().toIso8601String(),
    });

    return id;
  }

  static Future<Map<String, dynamic>?> getOtpCodeByEmailAndCodigo(
    String email,
    String codigo,
  ) async {
    final db = await database;
    final result = await db.query(
      _otpCodesTable,
      where: 'email = ? AND codigo = ? AND usado = 0',
      whereArgs: [email, codigo],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      final otp = result.first;
      otp['usado'] = otp['usado'] == 1;
      return otp;
    }
    return null;
  }

  static Future<void> marcarOtpCodeUsado(String id) async {
    final db = await database;
    await db.update(
      _otpCodesTable,
      {'usado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== OTP ATTEMPTS ====================

  static Future<String> createOtpAttempt(Map<String, dynamic> attempt) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert(_otpAttemptsTable, {
      'id': id,
      'email': attempt['email'],
      'intentosHoy': attempt['intentosHoy'] ?? 0,
      'fechaUltimoIntento': attempt['fechaUltimoIntento']?.toIso8601String(),
      'bloqueadoHasta': attempt['bloqueadoHasta']?.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    return id;
  }

  static Future<Map<String, dynamic>?> getOtpAttemptsByEmail(
    String email,
  ) async {
    final db = await database;
    final result = await db.query(
      _otpAttemptsTable,
      where: 'email = ?',
      whereArgs: [email],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  static Future<void> updateOtpAttempts(String email, int intentos) async {
    final db = await database;
    await db.update(
      _otpAttemptsTable,
      {
        'intentosHoy': intentos,
        'fechaUltimoIntento': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  // ==================== PAGOS ====================

  static Future<String> createPago(Map<String, dynamic> pago) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert(_pagosTable, {
      'id': id,
      'propietarioId': pago['propietarioId'],
      'nombrePagador': pago['nombrePagador'],
      'monto': pago['monto'],
      'fecha': pago['fecha'],
      'codigoSeguridad': pago['codigoSeguridad'],
      'registradoEnSheets': pago['registradoEnSheets'] ? 1 : 0,
      'notificadoEmpleados': pago['notificadoEmpleados'] ? 1 : 0,
      'hashNotificacion': pago['hashNotificacion'],
      'numeroTelefono': pago['numeroTelefono'],
      'mensajeOriginal': pago['mensajeOriginal'],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'procesadoAt': pago['procesadoAt']?.toIso8601String(),
    });

    return id;
  }

  static Future<List<Map<String, dynamic>>> getPagosByPropietario(
    String propietarioId,
  ) async {
    final db = await database;
    final result = await db.query(
      _pagosTable,
      where: 'propietarioId = ?',
      whereArgs: [propietarioId],
      orderBy: 'fecha DESC',
    );

    // Convertir enteros a booleanos
    for (var pago in result) {
      pago['registradoEnSheets'] = pago['registradoEnSheets'] == 1;
      pago['notificadoEmpleados'] = pago['notificadoEmpleados'] == 1;
    }

    return result;
  }

  // ==================== NOTIFICACIONES YAPE ====================

  static Future<String> createNotificacionYape(
    Map<String, dynamic> notificacion,
  ) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert(_notificacionesTable, {
      'id': id,
      'propietarioId': notificacion['propietarioId'],
      'mensajeOriginal': notificacion['mensajeOriginal'],
      'nombrePagador': notificacion['nombrePagador'],
      'monto': notificacion['monto'],
      'codigoSeguridad': notificacion['codigoSeguridad'],
      'numeroTelefono': notificacion['numeroTelefono'],
      'fechaNotificacion': notificacion['fechaNotificacion'],
      'procesado': notificacion['procesado'] ? 1 : 0,
      'hashNotificacion': notificacion['hashNotificacion'],
      'createdAt': DateTime.now().toIso8601String(),
    });

    return id;
  }

  static Future<List<Map<String, dynamic>>>
  getNotificacionesPendientes() async {
    final db = await database;
    final result = await db.query(
      _notificacionesTable,
      where: 'procesado = 0',
      orderBy: 'fechaNotificacion ASC',
    );

    // Convertir enteros a booleanos
    for (var notificacion in result) {
      notificacion['procesado'] = notificacion['procesado'] == 1;
    }

    return result;
  }

  static Future<void> marcarNotificacionProcesada(String id) async {
    final db = await database;
    await db.update(
      _notificacionesTable,
      {'procesado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== SMS ====================

  static Future<String> createSMS(Map<String, dynamic> sms) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert(_smsTable, {
      'id': id,
      'empleadoId': sms['empleadoId'],
      'pagoId': sms['pagoId'],
      'mensaje': sms['mensaje'],
      'numeroDestino': sms['numeroDestino'],
      'enviado': sms['enviado'] ? 1 : 0,
      'fechaEnvio': sms['fechaEnvio']?.toIso8601String(),
      'error': sms['error'],
      'createdAt': DateTime.now().toIso8601String(),
    });

    return id;
  }

  static Future<List<Map<String, dynamic>>> getSMSPendientes() async {
    final db = await database;
    final result = await db.query(
      _smsTable,
      where: 'enviado = 0',
      orderBy: 'createdAt ASC',
    );

    // Convertir enteros a booleanos
    for (var sms in result) {
      sms['enviado'] = sms['enviado'] == 1;
    }

    return result;
  }

  static Future<void> marcarSMSEnviado(String id, {String? error}) async {
    final db = await database;
    await db.update(
      _smsTable,
      {
        'enviado': 1,
        'fechaEnvio': DateTime.now().toIso8601String(),
        if (error != null) 'error': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== PROCESAMIENTO DE NOTIFICACIONES YAPE ====================

  static Future<void> procesarNotificacionYape(
    String mensaje,
    String propietarioId,
  ) async {
    try {
      // Extraer información del mensaje de Yape
      final Map<String, dynamic>? infoPago = _extraerInfoPago(mensaje);
      if (infoPago == null) return;

      // Crear hash único para evitar duplicados
      final hashNotificacion = _generarHash(mensaje);

      // Verificar si ya existe esta notificación
      final db = await database;
      final existing = await db.query(
        _notificacionesTable,
        where: 'hashNotificacion = ?',
        whereArgs: [hashNotificacion],
      );

      if (existing.isNotEmpty) return; // Ya procesada

      // Guardar notificación
      await createNotificacionYape({
        'propietarioId': propietarioId,
        'mensajeOriginal': mensaje,
        'nombrePagador': infoPago['nombrePagador'],
        'monto': infoPago['monto'],
        'codigoSeguridad': infoPago['codigoSeguridad'],
        'numeroTelefono': infoPago['numeroTelefono'],
        'fechaNotificacion': DateTime.now().toIso8601String(),
        'procesado': false,
        'hashNotificacion': hashNotificacion,
      });

      // Procesar pago
      await _procesarPago(infoPago, propietarioId);
    } catch (e) {
      print('Error procesando notificación Yape: $e');
    }
  }

  static Map<String, dynamic>? _extraerInfoPago(String mensaje) {
    try {
      // Patrones comunes de notificaciones de Yape
      final patterns = [
        RegExp(r'Recibiste S/ ([\d.]+) de (.+?)\. Código: (\d{3})'),
        RegExp(r'Pago de S/ ([\d.]+) de (.+?)\. Código: (\d{3})'),
        RegExp(r'Transferencia de S/ ([\d.]+) de (.+?)\. Código: (\d{3})'),
      ];

      for (var pattern in patterns) {
        final match = pattern.firstMatch(mensaje);
        if (match != null) {
          return {
            'monto': double.parse(match.group(1)!),
            'nombrePagador': match.group(2)!.trim(),
            'codigoSeguridad': match.group(3)!,
            'numeroTelefono': null, // No disponible en el mensaje
          };
        }
      }

      return null;
    } catch (e) {
      print('Error extrayendo información del pago: $e');
      return null;
    }
  }

  static String _generarHash(String mensaje) {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        mensaje.hashCode.toString();
  }

  static Future<void> _procesarPago(
    Map<String, dynamic> infoPago,
    String propietarioId,
  ) async {
    try {
      // Crear pago
      final pagoId = await createPago({
        'propietarioId': propietarioId,
        'nombrePagador': infoPago['nombrePagador'],
        'monto': infoPago['monto'],
        'fecha': DateTime.now().toIso8601String(),
        'codigoSeguridad': infoPago['codigoSeguridad'],
        'registradoEnSheets': false,
        'notificadoEmpleados': false,
        'hashNotificacion': _generarHash(
          infoPago['nombrePagador'] + infoPago['monto'].toString(),
        ),
        'numeroTelefono': infoPago['numeroTelefono'],
        'mensajeOriginal': null,
      });

      // Obtener empleados del propietario
      final empleados = await getEmpleadosByPropietario(propietarioId);

      // Enviar SMS a empleados
      for (var empleado in empleados) {
        final mensaje =
            'Nuevo pago recibido: S/ ${infoPago['monto']} de ${infoPago['nombrePagador']}';
        final numeroCompleto =
            '${empleado['paisCodigo']}${empleado['telefono']}';

        await createSMS({
          'empleadoId': empleado['id'],
          'pagoId': pagoId,
          'mensaje': mensaje,
          'numeroDestino': numeroCompleto,
          'enviado': false,
        });
      }

      // Marcar notificación como procesada
      final db = await database;
      final notificacion = await db.query(
        _notificacionesTable,
        where: 'propietarioId = ? AND nombrePagador = ? AND monto = ?',
        whereArgs: [
          propietarioId,
          infoPago['nombrePagador'],
          infoPago['monto'],
        ],
        orderBy: 'createdAt DESC',
        limit: 1,
      );

      if (notificacion.isNotEmpty) {
        await marcarNotificacionProcesada(notificacion.first['id'] as String);
      }
    } catch (e) {
      print('Error procesando pago: $e');
    }
  }

  // ==================== ENVÍO DE SMS ====================

  static Future<void> enviarSMSPendientes() async {
    try {
      final smsPendientes = await getSMSPendientes();

      for (var sms in smsPendientes) {
        try {
          // Aquí implementarías el envío real de SMS
          // Por ahora simulamos el envío
          await _simularEnvioSMS(sms);

          await marcarSMSEnviado(sms['id']);
        } catch (e) {
          await marcarSMSEnviado(sms['id'], error: e.toString());
        }
      }
    } catch (e) {
      print('Error enviando SMS pendientes: $e');
    }
  }

  static Future<void> _simularEnvioSMS(Map<String, dynamic> sms) async {
    // Simular delay de envío
    await Future.delayed(Duration(seconds: 1));

    // Aquí implementarías la lógica real de envío de SMS
    // Por ejemplo, usando un servicio como Twilio, AWS SNS, etc.
    print('SMS enviado a ${sms['numeroDestino']}: ${sms['mensaje']}');
  }

  // ==================== ESTADÍSTICAS ====================

  static Future<Map<String, dynamic>> getEstadisticasPagos(
    String propietarioId,
  ) async {
    final db = await database;

    // Pagos de hoy
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final finHoy = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);

    final pagosHoy = await db.rawQuery(
      '''
      SELECT COUNT(*) as count, SUM(monto) as total
      FROM $_pagosTable 
      WHERE propietarioId = ? AND fecha BETWEEN ? AND ?
    ''',
      [propietarioId, inicioHoy.toIso8601String(), finHoy.toIso8601String()],
    );

    // Total de pagos
    final pagosTotal = await db.rawQuery(
      '''
      SELECT COUNT(*) as count, SUM(monto) as total
      FROM $_pagosTable 
      WHERE propietarioId = ?
    ''',
      [propietarioId],
    );

    return {
      'pagosHoy': pagosHoy.first['count'] ?? 0,
      'totalHoy': pagosHoy.first['total'] ?? 0.0,
      'pagosTotal': pagosTotal.first['count'] ?? 0,
      'totalGeneral': pagosTotal.first['total'] ?? 0.0,
    };
  }

  // ==================== LIMPIEZA ====================

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
