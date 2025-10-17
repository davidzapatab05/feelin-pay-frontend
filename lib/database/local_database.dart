import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'dart:io';

class LocalDatabase {
  static Database? _database;
  static const String _dbName = 'feelin_pay_local.db';
  static const int _dbVersion = 1;

  // Claves de encriptación (en producción usar claves más seguras)
  static const String _encryptionKey =
      'feelin_pay_encryption_key_2024_32_chars_long';
  static const String _ivKey = 'feelin_pay_iv_key_16';

  static Future<Database> get database async {
    if (_database != null) return _database!;

    // Inicializar databaseFactory para Windows
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Tabla de usuarios (incluye Super Admin y Propietarios)
    await db.execute('''
      CREATE TABLE usuarios (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        telefono TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        rol TEXT NOT NULL DEFAULT 'propietario',
        saldo REAL DEFAULT 0.0,
        googleSpreadsheetId TEXT,
        fechaCreacion TEXT NOT NULL,
        licenciaActiva INTEGER DEFAULT 0,
        fechaExpiracionLicencia TEXT,
        activo INTEGER DEFAULT 1,
        creadoPor TEXT,
        
        -- Campos de prueba
        enPeriodoPrueba INTEGER DEFAULT 0,
        fechaInicioPrueba TEXT,
        diasPruebaRestantes INTEGER DEFAULT 0,
        
        -- Verificación de email
        emailVerificado INTEGER DEFAULT 0,
        emailVerificadoAt TEXT,
        
        -- Auditoría
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        lastLoginAt TEXT,
        loginAttempts INTEGER DEFAULT 0,
        lockedUntil TEXT,
        
        datosEncriptados TEXT
      )
    ''');

    // Tabla de empleados
    await db.execute('''
      CREATE TABLE empleados (
        id TEXT PRIMARY KEY,
        propietarioId TEXT NOT NULL,
        nombre TEXT NOT NULL,
        paisCodigo TEXT NOT NULL,
        telefono TEXT NOT NULL,
        canal TEXT NOT NULL,
        activo INTEGER DEFAULT 1,
        FOREIGN KEY (propietarioId) REFERENCES usuarios (id)
      )
    ''');

    // Tabla de pagos
    await db.execute('''
      CREATE TABLE pagos (
        id TEXT PRIMARY KEY,
        propietarioId TEXT NOT NULL,
        clienteNombre TEXT NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        notificacionRaw TEXT,
        registradoEnSheets INTEGER DEFAULT 0,
        notificadoEmpleados INTEGER DEFAULT 0,
        codigoSeguridad TEXT,
        telefonoPagador TEXT,
        nombrePagador TEXT,
        mensajeOriginal TEXT,
        sincronizado INTEGER DEFAULT 0,
        fechaSincronizacion TEXT,
        FOREIGN KEY (propietarioId) REFERENCES usuarios (id)
      )
    ''');

    // Tabla de licencias
    await db.execute('''
      CREATE TABLE licencias (
        codigo TEXT PRIMARY KEY,
        propietarioId TEXT,
        tipo TEXT NOT NULL,
        fechaEmision TEXT NOT NULL,
        fechaExpiracion TEXT NOT NULL,
        firma TEXT NOT NULL,
        activa INTEGER DEFAULT 0,
        creadoPor TEXT,
        FOREIGN KEY (propietarioId) REFERENCES usuarios (id)
      )
    ''');

    // Tabla de configuración
    await db.execute('''
      CREATE TABLE configuracion (
        clave TEXT PRIMARY KEY,
        valor TEXT NOT NULL,
        encriptado INTEGER DEFAULT 0
      )
    ''');

    // Insertar configuración inicial
    await db.insert('configuracion', {
      'clave': 'app_version',
      'valor': '1.0.0',
      'encriptado': 0,
    });
  }

  // Métodos de encriptación
  static String _encrypt(String text) {
    final key = Key.fromUtf8(_encryptionKey);
    final iv = IV.fromUtf8(_ivKey);
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(text, iv: iv);
    return encrypted.base64;
  }

  static String _decrypt(String encryptedText) {
    final key = Key.fromUtf8(_encryptionKey);
    final iv = IV.fromUtf8(_ivKey);
    final encrypter = Encrypter(AES(key));
    final encrypted = Encrypted.fromBase64(encryptedText);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  // CRUD para Usuarios
  static Future<Map<String, dynamic>?> getUsuario(String id) async {
    final db = await database;
    final result = await db.query('usuarios', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> getUsuarioByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<List<Map<String, dynamic>>> getUsuariosPorRol(
    String rol,
  ) async {
    final db = await database;
    return await db.query('usuarios', where: 'rol = ?', whereArgs: [rol]);
  }

  static Future<List<Map<String, dynamic>>> getAllUsuarios() async {
    final db = await database;
    return await db.query('usuarios');
  }

  static Future<String> createUsuario(Map<String, dynamic> usuario) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('usuarios', {
      'id': id,
      'nombre': usuario['nombre'],
      'telefono': usuario['telefono'],
      'email': usuario['email'],
      'password': _encrypt(usuario['password']),
      'rol': usuario['rol'] ?? 'propietario',
      'saldo': usuario['saldo'] ?? 0.0,
      'googleSpreadsheetId': usuario['googleSpreadsheetId'],
      'fechaCreacion': DateTime.now().toIso8601String(),
      'licenciaActiva': usuario['licenciaActiva'] ?? 0,
      'activo': usuario['activo'] ?? 1,
      'creadoPor': usuario['creadoPor'],
      'datosEncriptados': _encrypt(json.encode(usuario)),
    });

    return id;
  }

  static Future<void> updateUsuario(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final db = await database;
    await db.update('usuarios', updates, where: 'id = ?', whereArgs: [id]);
  }

  // CRUD para Empleados
  static Future<List<Map<String, dynamic>>> getEmpleados(
    String propietarioId,
  ) async {
    final db = await database;
    return await db.query(
      'empleados',
      where: 'propietarioId = ?',
      whereArgs: [propietarioId],
    );
  }

  // Obtener empleados por propietario (alias para compatibilidad)
  static Future<List<Map<String, dynamic>>> getEmpleadosByPropietario(
    String propietarioId,
  ) async {
    return await getEmpleados(propietarioId);
  }

  static Future<String> createEmpleado(Map<String, dynamic> empleado) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('empleados', {
      'id': id,
      'propietarioId': empleado['propietarioId'],
      'nombre': empleado['nombre'],
      'paisCodigo': empleado['paisCodigo'],
      'telefono': empleado['telefono'],
      'canal': empleado['canal'],
      'activo': empleado['activo'] ? 1 : 0,
    });

    return id;
  }

  static Future<void> updateEmpleado(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final db = await database;
    await db.update('empleados', updates, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteEmpleado(String id) async {
    final db = await database;
    await db.delete('empleados', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD para Pagos
  static Future<List<Map<String, dynamic>>> getPagos(
    String propietarioId,
  ) async {
    final db = await database;
    return await db.query(
      'pagos',
      where: 'propietarioId = ?',
      whereArgs: [propietarioId],
      orderBy: 'fecha DESC',
    );
  }

  static Future<String> createPago(Map<String, dynamic> pago) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('pagos', {
      'id': id,
      'propietarioId': pago['propietarioId'],
      'clienteNombre': pago['clienteNombre'],
      'monto': pago['monto'],
      'fecha': pago['fecha'],
      'notificacionRaw': pago['notificacionRaw'],
      'registradoEnSheets': pago['registradoEnSheets'] ? 1 : 0,
      'notificadoEmpleados': pago['notificadoEmpleados'] ? 1 : 0,
      'codigoSeguridad': pago['codigoSeguridad'],
    });

    return id;
  }

  // CRUD para Licencias
  static Future<Map<String, dynamic>?> getLicencia(String codigo) async {
    final db = await database;
    final result = await db.query(
      'licencias',
      where: 'codigo = ?',
      whereArgs: [codigo],
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<String> createLicencia(Map<String, dynamic> licencia) async {
    final db = await database;

    await db.insert('licencias', {
      'codigo': licencia['codigo'],
      'propietarioId': licencia['propietarioId'],
      'tipo': licencia['tipo'],
      'fechaEmision': licencia['fechaEmision'],
      'fechaExpiracion': licencia['fechaExpiracion'],
      'firma': licencia['firma'],
      'activa': licencia['activa'] ? 1 : 0,
    });

    return licencia['codigo'];
  }

  // Verificar licencia activa
  static Future<bool> verificarLicenciaActiva(String propietarioId) async {
    final db = await database;
    final result = await db.query(
      'propietarios',
      columns: ['licenciaActiva', 'fechaExpiracionLicencia'],
      where: 'id = ?',
      whereArgs: [propietarioId],
    );

    if (result.isEmpty) return false;

    final licenciaActiva = result.first['licenciaActiva'] == 1;
    final fechaExpiracion = result.first['fechaExpiracionLicencia'];

    if (!licenciaActiva || fechaExpiracion == null) return false;

    final fechaExp = DateTime.parse(fechaExpiracion.toString());
    return DateTime.now().isBefore(fechaExp);
  }

  // Actualizar saldo
  static Future<void> updateSaldo(String propietarioId, double monto) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE propietarios SET saldo = saldo + ? WHERE id = ?',
      [monto, propietarioId],
    );
  }

  // Obtener saldo
  static Future<double> getSaldo(String propietarioId) async {
    final db = await database;
    final result = await db.query(
      'propietarios',
      columns: ['saldo'],
      where: 'id = ?',
      whereArgs: [propietarioId],
    );

    return result.isNotEmpty ? (result.first['saldo'] as double) : 0.0;
  }

  // Configuración
  static Future<void> setConfig(
    String clave,
    String valor, {
    bool encriptado = false,
  }) async {
    final db = await database;
    await db.insert('configuracion', {
      'clave': clave,
      'valor': encriptado ? _encrypt(valor) : valor,
      'encriptado': encriptado ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<String?> getConfig(String clave) async {
    final db = await database;
    final result = await db.query(
      'configuracion',
      where: 'clave = ?',
      whereArgs: [clave],
    );

    if (result.isEmpty) return null;

    final config = result.first;
    final valor = config['valor'] as String;
    final encriptado = config['encriptado'] == 1;

    return encriptado ? _decrypt(valor) : valor;
  }

  // Obtener pagos pendientes de sincronización
  static Future<List<Map<String, dynamic>>> getPagosPendientesSincronizacion(
    String propietarioId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT * FROM pagos 
      WHERE propietarioId = ? AND sincronizado = 0
      ORDER BY fecha ASC
    ''',
      [propietarioId],
    );
  }

  // Marcar pago como sincronizado
  static Future<void> marcarPagoSincronizado(String pagoId) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE pagos 
      SET sincronizado = 1, fechaSincronizacion = ?
      WHERE id = ?
    ''',
      [DateTime.now().toIso8601String(), pagoId],
    );
  }

  // Obtener pagos por fecha
  static Future<List<Map<String, dynamic>>> getPagosPorFecha(
    String propietarioId,
    DateTime fecha,
  ) async {
    final db = await database;
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);

    return await db.rawQuery(
      '''
      SELECT * FROM pagos 
      WHERE propietarioId = ? AND fecha BETWEEN ? AND ?
      ORDER BY fecha ASC
    ''',
      [propietarioId, inicioDia.toIso8601String(), finDia.toIso8601String()],
    );
  }

  // Método privado para obtener estadísticas generales
  static Future<Map<String, dynamic>> _getEstadisticasGenerales(
    String propietarioId,
  ) async {
    final db = await database;

    // Pagos de hoy
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final finHoy = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);

    final pagosHoy = await db.rawQuery(
      '''
      SELECT COUNT(*) as total, COALESCE(SUM(monto), 0) as monto
      FROM pagos 
      WHERE propietarioId = ? AND fecha BETWEEN ? AND ?
    ''',
      [propietarioId, inicioHoy.toIso8601String(), finHoy.toIso8601String()],
    );

    // Pagos del mes
    final inicioMes = DateTime(hoy.year, hoy.month, 1);
    final finMes = DateTime(hoy.year, hoy.month + 1, 0, 23, 59, 59);

    final pagosMes = await db.rawQuery(
      '''
      SELECT COUNT(*) as total, COALESCE(SUM(monto), 0) as monto
      FROM pagos 
      WHERE propietarioId = ? AND fecha BETWEEN ? AND ?
    ''',
      [propietarioId, inicioMes.toIso8601String(), finMes.toIso8601String()],
    );

    // Total de pagos
    final totalPagos = await db.rawQuery(
      '''
      SELECT COUNT(*) as total, COALESCE(SUM(monto), 0) as monto
      FROM pagos 
      WHERE propietarioId = ?
    ''',
      [propietarioId],
    );

    return {
      'pagosHoy': pagosHoy.first['total'] ?? 0,
      'montoHoy': ((pagosHoy.first['monto'] ?? 0) as num).toDouble(),
      'pagosMes': pagosMes.first['total'] ?? 0,
      'montoMes': ((pagosMes.first['monto'] ?? 0) as num).toDouble(),
      'totalPagos': totalPagos.first['total'] ?? 0,
      'montoTotal': ((totalPagos.first['monto'] ?? 0) as num).toDouble(),
    };
  }

  // Obtener estadísticas de pagos (método específico para Google Sheets)
  static Future<Map<String, dynamic>> getEstadisticasPagos(
    String propietarioId,
  ) async {
    final db = await database;

    // Estadísticas generales
    final estadisticas = await _getEstadisticasGenerales(propietarioId);

    // Pagos pendientes de sincronización
    final pendientes = await db.rawQuery(
      '''
      SELECT COUNT(*) as total FROM pagos 
      WHERE propietarioId = ? AND sincronizado = 0
    ''',
      [propietarioId],
    );

    // Última sincronización
    final ultimaSync = await db.rawQuery(
      '''
      SELECT MAX(fechaSincronizacion) as ultima FROM pagos 
      WHERE propietarioId = ? AND sincronizado = 1
    ''',
      [propietarioId],
    );

    return {
      ...estadisticas,
      'pagosPendientesSincronizacion': pendientes.first['total'] ?? 0,
      'ultimaSincronizacion': ultimaSync.first['ultima'],
      'necesitaSincronizacion': ((pendientes.first['total'] ?? 0) as int) > 0,
    };
  }

  // Limpiar base de datos
  static Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('usuarios');
    await db.delete('empleados');
    await db.delete('pagos');
    await db.delete('licencias');
    await db.delete('configuracion');
  }
}
