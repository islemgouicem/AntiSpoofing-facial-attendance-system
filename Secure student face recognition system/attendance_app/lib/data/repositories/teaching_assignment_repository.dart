import 'package:sqflite/sqflite.dart';
import '../../domain/models/teaching_assignment.dart';
import '../database/app_database.dart';

class TeachingAssignmentRepository {
  final AppDatabase _db;
  final String _table = 'teaching_assignments';

  TeachingAssignmentRepository(this._db);

  Future<List<TeachingAssignment>> getAll(String semesterId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT ta.*, m.name as module_name, g.name as group_name 
      FROM $_table ta
      LEFT JOIN modules m ON ta.module_id = m.id
      LEFT JOIN (SELECT id, name FROM groups) g ON ta.group_id = g.id
      WHERE ta.semester_id = ?
    ''', [semesterId]);
    return maps.map((m) => TeachingAssignment.fromMap(m)).toList();
  }

  Future<void> insert(TeachingAssignment assignment) async {
    final db = await _db.database;
    await db.insert(_table, assignment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
