import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain/models/semester.dart';
import '../database/app_database.dart';

class SemesterRepository {
  final AppDatabase _db;
  final String _table = 'semesters';

  SemesterRepository(this._db);

  Future<List<Semester>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(_table, orderBy: 'created_at DESC');
    return maps.map((m) => Semester.fromMap(m)).toList();
  }

  Future<Semester?> getActive() async {
    final db = await _db.database;
    final maps = await db.query(
      _table,
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Semester.fromMap(maps.first);
  }

  Future<void> insert(Semester semester) async {
    final db = await _db.database;
    await db.insert(
      _table,
      semester.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setActive(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update(_table, {'is_active': 0});
      await txn.update(_table, {'is_active': 1},
          where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}