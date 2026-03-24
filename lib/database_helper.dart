import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'preset_treatments.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final db = await openDatabase(
      join(await getDatabasesPath(), 'odontologia.db'),
      onCreate: (db, version) {
        return _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _upgradeSchema(db, oldVersion, newVersion);
      },
      version: 3,
    );

    await _ensureSeedData(db);
    return db;
  }

  Future<void> _ensureSeedData(Database db) async {
    final dentistsCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM odontologos'),
        ) ??
        0;

    if (dentistsCount == 0) {
      await db.insert('odontologos', {
        'nombre': 'Odontólogo 1',
        'tarifa_predeterminada': null,
      });
    }

    for (final item in kReceivedTreatmentsPreset) {
      final existing = await db.query(
        'tratamientos',
        where: 'LOWER(nombre) = ?',
        whereArgs: [item.name.toLowerCase()],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert('tratamientos', {
          'nombre': item.name,
          'precio_predeterminado': item.price,
        });
      } else {
        await db.update(
          'tratamientos',
          {
            'nombre': item.name,
            'precio_predeterminado': item.price,
          },
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      }
    }
  }

  Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_registro_doctor_fecha
        ON registro_diario(odontologo_id, fecha)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_pacientes_nombre
        ON pacientes(nombre)
      ''');
    }

    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE tratamientos ADD COLUMN icon_key TEXT',
      );
      await db.execute(
        'ALTER TABLE tratamientos ADD COLUMN color_hex TEXT',
      );
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE odontologos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        tarifa_predeterminada REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE pacientes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE tratamientos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        precio_predeterminado REAL NOT NULL DEFAULT 0,
        icon_key TEXT,
        color_hex TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE registro_diario(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        paciente_id INTEGER NOT NULL,
        odontologo_id INTEGER NOT NULL,
        tratamiento_id INTEGER NOT NULL,
        precio_final REAL NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (paciente_id) REFERENCES pacientes(id),
        FOREIGN KEY (odontologo_id) REFERENCES odontologos(id),
        FOREIGN KEY (tratamiento_id) REFERENCES tratamientos(id)
      )
    ''');

    await db.insert('odontologos', {
      'nombre': 'Odontólogo 1',
      'tarifa_predeterminada': null,
    });

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_registro_doctor_fecha
      ON registro_diario(odontologo_id, fecha)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_pacientes_nombre
      ON pacientes(nombre)
    ''');
  }

  String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<List<Map<String, dynamic>>> getDentists() async {
    final db = await database;
    return db.query('odontologos', orderBy: 'nombre ASC');
  }

  Future<int> insertDentist(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('odontologos', data,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> updateDentist(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update('odontologos', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDentist(int id) async {
    final db = await database;
    return db.delete('odontologos', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getTreatments() async {
    final db = await database;
    return db.query('tratamientos', orderBy: 'nombre ASC');
  }

  Future<int> insertTreatmentType(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('tratamientos', data,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> updateTreatmentType(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update('tratamientos', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTreatmentType(int id) async {
    final db = await database;
    return db.delete('tratamientos', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> upsertPatientByName(String name) async {
    final db = await database;
    final existing = await db.query(
      'pacientes',
      where: 'LOWER(nombre) = ?',
      whereArgs: [name.trim().toLowerCase()],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return db.insert('pacientes', {'nombre': name.trim()});
  }

  Future<List<Map<String, dynamic>>> searchPatientsByName(
    String query, {
    int limit = 8,
  }) async {
    final db = await database;
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return db.query('pacientes', orderBy: 'nombre ASC', limit: limit);
    }

    return db.query(
      'pacientes',
      where: 'LOWER(nombre) LIKE ?',
      whereArgs: ['%$normalized%'],
      orderBy: 'nombre ASC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getPatientsWithStats() async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        p.id,
        p.nombre,
        COUNT(rd.id) AS tratamientos,
        COALESCE(SUM(rd.precio_final), 0) AS total_facturado
      FROM pacientes p
      LEFT JOIN registro_diario rd ON rd.paciente_id = p.id
      GROUP BY p.id, p.nombre
      ORDER BY p.nombre ASC
    ''');
  }

  Future<int> insertDailyRecord(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('registro_diario', data);
  }

  Future<int> updateDailyRecord(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update('registro_diario', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDailyRecord(int id) async {
    final db = await database;
    return db.delete('registro_diario', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getRecordsByDate(DateTime date) async {
    final db = await database;
    final key = dateKey(date);
    return db.rawQuery('''
      SELECT
        rd.*,
        p.nombre AS paciente,
        o.nombre AS odontologo,
        t.nombre AS tratamiento,
        t.precio_predeterminado AS precio_predeterminado_tratamiento,
        t.icon_key AS tratamiento_icon_key,
        t.color_hex AS tratamiento_color_hex
      FROM registro_diario rd
      INNER JOIN pacientes p ON p.id = rd.paciente_id
      INNER JOIN odontologos o ON o.id = rd.odontologo_id
      INNER JOIN tratamientos t ON t.id = rd.tratamiento_id
      WHERE rd.fecha = ?
      ORDER BY rd.created_at DESC
    ''', [key]);
  }

  Future<List<Map<String, dynamic>>> getRecordsByDateAndDoctor(
    DateTime date,
    int dentistId,
  ) async {
    final db = await database;
    final key = dateKey(date);
    return db.rawQuery('''
      SELECT
        rd.*,
        p.nombre AS paciente,
        o.nombre AS odontologo,
        t.nombre AS tratamiento,
        t.precio_predeterminado AS precio_predeterminado_tratamiento,
        t.icon_key AS tratamiento_icon_key,
        t.color_hex AS tratamiento_color_hex
      FROM registro_diario rd
      INNER JOIN pacientes p ON p.id = rd.paciente_id
      INNER JOIN odontologos o ON o.id = rd.odontologo_id
      INNER JOIN tratamientos t ON t.id = rd.tratamiento_id
      WHERE rd.fecha = ? AND rd.odontologo_id = ?
      ORDER BY rd.created_at DESC
    ''', [key, dentistId]);
  }

  Future<List<Map<String, dynamic>>> getRecordsByDoctor(int dentistId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        rd.*,
        p.nombre AS paciente,
        o.nombre AS odontologo,
        t.nombre AS tratamiento,
        t.icon_key AS tratamiento_icon_key,
        t.color_hex AS tratamiento_color_hex
      FROM registro_diario rd
      INNER JOIN pacientes p ON p.id = rd.paciente_id
      INNER JOIN odontologos o ON o.id = rd.odontologo_id
      INNER JOIN tratamientos t ON t.id = rd.tratamiento_id
      WHERE rd.odontologo_id = ?
      ORDER BY rd.fecha DESC, rd.created_at DESC
    ''', [dentistId]);
  }

  Future<List<Map<String, dynamic>>> getRecordsByDoctorBetweenDates(
    int dentistId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startKey = dateKey(start);
    final endKey = dateKey(end);

    return db.rawQuery('''
      SELECT
        rd.*,
        p.nombre AS paciente,
        o.nombre AS odontologo,
        t.nombre AS tratamiento,
        t.icon_key AS tratamiento_icon_key,
        t.color_hex AS tratamiento_color_hex
      FROM registro_diario rd
      INNER JOIN pacientes p ON p.id = rd.paciente_id
      INNER JOIN odontologos o ON o.id = rd.odontologo_id
      INNER JOIN tratamientos t ON t.id = rd.tratamiento_id
      WHERE rd.odontologo_id = ?
      AND rd.fecha >= ?
      AND rd.fecha <= ?
      ORDER BY rd.fecha DESC, rd.created_at DESC
    ''', [dentistId, startKey, endKey]);
  }

  Future<List<Map<String, dynamic>>> getTopTreatmentsByDoctor(
    int dentistId, {
    int limit = 8,
  }) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        t.id,
        t.nombre,
        t.precio_predeterminado,
        t.icon_key,
        t.color_hex,
        COUNT(rd.id) AS usos,
        MAX(rd.created_at) AS ultimo_uso
      FROM registro_diario rd
      INNER JOIN tratamientos t ON t.id = rd.tratamiento_id
      WHERE rd.odontologo_id = ?
      GROUP BY t.id, t.nombre, t.precio_predeterminado, t.icon_key, t.color_hex
      ORDER BY usos DESC, ultimo_uso DESC
      LIMIT ?
    ''', [dentistId, limit]);
  }

  Future<List<String>> getRecordedDates() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT fecha
      FROM registro_diario
      GROUP BY fecha
      ORDER BY fecha DESC
    ''');

    return rows.map((row) => row['fecha'] as String).toList();
  }

  Future<int> clearUnusedTreatmentTypes() async {
    final db = await database;
    return db.delete(
      'tratamientos',
      where: 'id NOT IN (SELECT DISTINCT tratamiento_id FROM registro_diario)',
    );
  }

  Future<Map<String, int>> applyReceivedTreatmentsPreset() async {
    final db = await database;

    return db.transaction((txn) async {
      var inserted = 0;
      var updated = 0;

      for (final item in kReceivedTreatmentsPreset) {
        final existing = await txn.query(
          'tratamientos',
          where: 'LOWER(nombre) = ?',
          whereArgs: [item.name.toLowerCase()],
          limit: 1,
        );

        if (existing.isEmpty) {
          await txn.insert('tratamientos', {
            'nombre': item.name,
            'precio_predeterminado': item.price,
          });
          inserted += 1;
        } else {
          await txn.update(
            'tratamientos',
            {
              'nombre': item.name,
              'precio_predeterminado': item.price,
            },
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
          updated += 1;
        }
      }

      final names = kReceivedTreatmentsPreset.map((e) => e.name).toList();
      final placeholders = List.filled(names.length, '?').join(',');
      final removed = await txn.rawDelete(
        '''
        DELETE FROM tratamientos
        WHERE id NOT IN (SELECT DISTINCT tratamiento_id FROM registro_diario)
        AND nombre NOT IN ($placeholders)
      ''',
        names,
      );

      return {
        'inserted': inserted,
        'updated': updated,
        'removed': removed,
      };
    });
  }

  Future<List<String>> getRecordedDatesByDoctor(int dentistId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT fecha
      FROM registro_diario
      WHERE odontologo_id = ?
      GROUP BY fecha
      ORDER BY fecha DESC
    ''', [dentistId]);

    return rows.map((row) => row['fecha'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getTotalsByDoctorForDate(DateTime date) async {
    final db = await database;
    final key = dateKey(date);
    return db.rawQuery('''
      SELECT
        o.id AS odontologo_id,
        o.nombre AS odontologo,
        SUM(rd.precio_final) AS total
      FROM registro_diario rd
      INNER JOIN odontologos o ON o.id = rd.odontologo_id
      WHERE rd.fecha = ?
      GROUP BY o.id, o.nombre
      ORDER BY o.nombre ASC
    ''', [key]);
  }

  Future<double> getTotalByDoctor(int dentistId) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(precio_final), 0) AS total FROM registro_diario WHERE odontologo_id = ?',
      [dentistId],
    );
    final value = rows.first['total'];
    return value is int ? value.toDouble() : (value as num).toDouble();
  }

  Future<double> getTotalByDoctorForDate(int dentistId, DateTime date) async {
    final db = await database;
    final key = dateKey(date);
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(precio_final), 0) AS total FROM registro_diario WHERE odontologo_id = ? AND fecha = ?',
      [dentistId, key],
    );
    final value = rows.first['total'];
    return value is int ? value.toDouble() : (value as num).toDouble();
  }
}
