import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../../domain/models/academic_session.dart';
import '../../domain/models/attendance_record.dart';

class AttendanceRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  AttendanceRepository(this._db);

  // ── Sessions ─────────────────────────────────────────────
  Future<AcademicSession> createSession({
    required String assignmentId,
    required int sessionNumber,
  }) async {
    final session = AcademicSession(
      id: _uuid.v4(),
      assignmentId: assignmentId,
      sessionNumber: sessionNumber,
      status: SessionStatus.pending,
    );
    final db = await _db.database;
    await db.insert('academic_sessions', session.toMap());
    return session;
  }

  Future<void> startSession(String id) async {
    final db = await _db.database;
    await db.update(
      'academic_sessions',
      {
        'started_at': DateTime.now().millisecondsSinceEpoch,
        'status': SessionStatus.active.name,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> completeSession(String id) async {
    final db = await _db.database;
    await db.update(
      'academic_sessions',
      {
        'ended_at': DateTime.now().millisecondsSinceEpoch,
        'status': SessionStatus.completed.name,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<AcademicSession>> getSessionsForAssignment(String assignmentId) async {
    final db = await _db.database;
    final rows = await db.query(
      'academic_sessions',
      where: 'assignment_id = ?',
      whereArgs: [assignmentId],
      orderBy: 'session_number ASC',
    );
    return rows.map(AcademicSession.fromMap).toList();
  }

  // ── Attendance Matrix ────────────────────────────────────
  
  /// Returns a matrix of attendance records for an assignment.
  /// Result: Map<StudentId, Map<SessionId, AttendanceRecord>>
  Future<Map<String, Map<String, AttendanceRecord>>> getAttendanceMatrix(String assignmentId) async {
    final db = await _db.database;
    
    // 1. Get all sessions for this assignment
    final sessions = await getSessionsForAssignment(assignmentId);
    if (sessions.isEmpty) return {};

    final sessionIds = sessions.map((s) => s.id).toList();
    
    // 2. Get all records for these sessions
    final placeholders = List.filled(sessionIds.length, '?').join(',');
    final rows = await db.rawQuery('''
      SELECT r.*, s.first_name || ' ' || s.last_name as student_name
      FROM attendance_records r
      JOIN students s ON s.id = r.student_id
      WHERE r.session_id IN ($placeholders)
    ''', sessionIds);

    final matrix = <String, Map<String, AttendanceRecord>>{};
    for (final row in rows) {
      final record = AttendanceRecord.fromMap(row);
      matrix.putIfAbsent(record.studentId, () => {});
      matrix[record.studentId]![record.sessionId] = record;
    }

    return matrix;
  }

  Future<void> updateRecordStatus(String sessionId, String studentId, AttendanceStatus status) async {
    final db = await _db.database;
    final existing = await db.query(
      'attendance_records',
      where: 'session_id = ? AND student_id = ?',
      whereArgs: [sessionId, studentId],
    );

    if (existing.isEmpty) {
      final record = AttendanceRecord(
        sessionId: sessionId,
        studentId: studentId,
        status: status,
        recognizedAt: (status == AttendanceStatus.present || status == AttendanceStatus.manual_present) 
            ? DateTime.now() : null,
      );
      await db.insert('attendance_records', record.toMap());
    } else {
      await db.update(
        'attendance_records',
        {
          'status': status.name,
          'recognized_at': (status == AttendanceStatus.present || status == AttendanceStatus.manual_present) 
              ? DateTime.now().millisecondsSinceEpoch : null,
        },
        where: 'session_id = ? AND student_id = ?',
        whereArgs: [sessionId, studentId],
      );
    }
  }

  // ── Stats ────────────────────────────────────────────────
  Future<Map<String, dynamic>> getStudentStats(String studentId, String assignmentId) async {
    final db = await _db.database;
    
    // Total conducted sessions for this assignment
    final conducted = await db.rawQuery('''
      SELECT COUNT(*) as count FROM academic_sessions 
      WHERE assignment_id = ? AND status = 'completed'
    ''', [assignmentId]);
    
    // Absences for this student in conducted sessions
    final absences = await db.rawQuery('''
      SELECT COUNT(*) as count FROM attendance_records r
      JOIN academic_sessions s ON s.id = r.session_id
      WHERE r.student_id = ? AND s.assignment_id = ? 
      AND s.status = 'completed' AND (r.status = 'absent' OR r.status = 'manual_absent')
    ''', [studentId, assignmentId]);
    return {
      'total_sessions': conducted.first['count'] as int,
      'absences': absences.first['count'] as int,
    };
  }

  Future<List<AcademicSession>> getRecentSessions({int limit = 5}) async {
    final db = await _db.database;
    final rows = await db.query(
      'academic_sessions',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map(AcademicSession.fromMap).toList();
  }
}
