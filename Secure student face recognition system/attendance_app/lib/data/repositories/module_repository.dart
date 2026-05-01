import 'package:sqflite/sqflite.dart';
import '../../domain/models/module.dart';
import '../database/app_database.dart';

class ModuleRepository {
  final AppDatabase _db;
  final String _table = 'modules';

  ModuleRepository(this._db);

  Future<List<Module>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(_table, orderBy: 'name ASC');
    return maps.map((m) => Module.fromMap(m)).toList();
  }

  Future<void> insert(Module module) async {
    final db = await _db.database;
    await db.insert(_table, module.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
