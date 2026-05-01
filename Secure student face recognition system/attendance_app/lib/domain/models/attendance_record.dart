import 'package:uuid/uuid.dart';

enum AttendanceStatus { present, absent, manual_present, manual_absent }

/// Single attendance record — one student's status in a session.
class AttendanceRecord {
  final String id;
  final String sessionId;
  final String studentId;
  final AttendanceStatus status;
  final DateTime? recognizedAt;
  final double? confidence;
  final String? studentName; // UI helper

  AttendanceRecord({
    String? id,
    required this.sessionId,
    required this.studentId,
    this.status = AttendanceStatus.absent,
    this.recognizedAt,
    this.confidence,
    this.studentName,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'student_id': studentId,
        'status': status.name,
        'recognized_at': recognizedAt?.millisecondsSinceEpoch,
        'confidence': confidence,
      };

  factory AttendanceRecord.fromMap(Map<String, dynamic> m) => AttendanceRecord(
        id: m['id'] as String,
        sessionId: m['session_id'] as String,
        studentId: m['student_id'] as String,
        status: AttendanceStatus.values.byName(m['status'] ?? 'absent'),
        recognizedAt: m['recognized_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['recognized_at'] as int)
            : null,
        confidence: (m['confidence'] as num?)?.toDouble(),
        studentName: m['student_name'] as String?,
      );
}
