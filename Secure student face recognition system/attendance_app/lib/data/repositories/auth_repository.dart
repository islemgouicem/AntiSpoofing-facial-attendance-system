import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class AuthRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  AuthRepository(this._db);

  String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Future<bool> hasTeacher() async {
    final db = await _db.database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM teachers');
    return (r.first['c'] as int) > 0;
  }

  Future<bool> register({
    required String username,
    required String password,
    required String displayName,
  }) async {
    final db = await _db.database;
    try {
      await db.insert('teachers', {
        'id': _uuid.v4(),
        'username': username,
        'password_hash': _hash(password),
        'display_name': displayName,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
  }) async {
    final db = await _db.database;
    final rows = await db.query('teachers',
        where: 'username = ? AND password_hash = ?',
        whereArgs: [username, _hash(password)]);
    return rows.isEmpty ? null : rows.first;
  }
}
