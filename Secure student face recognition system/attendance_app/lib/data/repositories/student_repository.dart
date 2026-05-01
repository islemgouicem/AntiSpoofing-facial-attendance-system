import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../../domain/models/student.dart';

class StudentRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  StudentRepository(this._db);

  Future<List<Student>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('students', orderBy: 'first_name ASC');
    return rows.map(Student.fromMap).toList();
  }

  Future<Student?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('students', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Student.fromMap(rows.first);
  }

  Future<Student> create({
    required String firstName,
    required String lastName,
    String? email,
    String? studentId,
  }) async {
    final now = DateTime.now();
    final student = Student(
      id: _uuid.v4(),
      firstName: firstName,
      lastName: lastName,
      email: email,
      studentId: studentId,
      createdAt: now,
      updatedAt: now,
    );
    final db = await _db.database;
    await db.insert('students', student.toMap());
    return student;
  }

  Future<void> update(Student student) async {
    final db = await _db.database;
    await db.update('students', student.toMap(),
        where: 'id = ?', whereArgs: [student.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Student>> getByGroup(String groupId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT s.* FROM students s
      INNER JOIN student_groups sg ON sg.student_id = s.id
      WHERE sg.group_id = ?
      ORDER BY s.first_name ASC
    ''', [groupId]);
    return rows.map(Student.fromMap).toList();
  }

  Future<List<Student>> search(String query) async {
    final db = await _db.database;
    final q = '%$query%';
    final rows = await db.query('students',
        where: 'first_name LIKE ? OR last_name LIKE ? OR student_id LIKE ?',
        whereArgs: [q, q, q],
        orderBy: 'first_name ASC');
    return rows.map(Student.fromMap).toList();
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM students');
    return result.first['c'] as int;
  }

  Future<void> updateFaceRegistration(String id, bool registered) async {
    final db = await _db.database;
    await db.update(
      'students',
      {'face_registered': registered ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
