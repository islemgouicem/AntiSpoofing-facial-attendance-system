import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../../domain/models/group.dart';

class GroupRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  GroupRepository(this._db);

  Future<List<Group>> getAll() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT g.*, (SELECT COUNT(*) FROM student_groups sg WHERE sg.group_id = g.id) as student_count
      FROM groups g
      ORDER BY g.academic_year ASC, g.name ASC
    ''');
    return rows.map(Group.fromMap).toList();
  }

  Future<Group?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT g.*, (SELECT COUNT(*) FROM student_groups sg WHERE sg.group_id = g.id) as student_count
      FROM groups g
      WHERE g.id = ?
    ''', [id]);
    return rows.isEmpty ? null : Group.fromMap(rows.first);
  }

  Future<Group> create({
    required String name,
    required String academicYear,
  }) async {
    final now = DateTime.now();
    final group = Group(
      id: _uuid.v4(),
      name: name,
      academicYear: academicYear,
      createdAt: now,
      updatedAt: now,
    );
    final db = await _db.database;
    await db.insert('groups', group.toMap());
    return group;
  }

  Future<void> update(Group group) async {
    final db = await _db.database;
    await db.update('groups', group.toMap(),
        where: 'id = ?', whereArgs: [group.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('student_groups', where: 'group_id = ?', whereArgs: [id]);
      await txn.delete('groups', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> addStudent(String groupId, String studentId) async {
    final db = await _db.database;
    await db.insert('student_groups', {
      'group_id': groupId,
      'student_id': studentId,
    });
  }

  Future<void> removeStudent(String groupId, String studentId) async {
    final db = await _db.database;
    await db.delete('student_groups',
        where: 'group_id = ? AND student_id = ?',
        whereArgs: [groupId, studentId]);
  }

  Future<void> setStudents(String groupId, List<String> studentIds) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('student_groups', where: 'group_id = ?', whereArgs: [groupId]);
      for (final sid in studentIds) {
        await txn.insert('student_groups', {
          'group_id': groupId,
          'student_id': sid,
        });
      }
    });
  }

  Future<int> count() async {
    final db = await _db.database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM groups');
    return r.first['c'] as int;
  }
}
