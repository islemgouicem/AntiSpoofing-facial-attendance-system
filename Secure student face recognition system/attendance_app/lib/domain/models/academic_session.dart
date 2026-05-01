import 'package:uuid/uuid.dart';

enum SessionStatus { pending, active, completed }

class AcademicSession {
  final String id;
  final String assignmentId;
  final int sessionNumber; // S1, S2, S3...
  final DateTime? startedAt;
  final DateTime? endedAt;
  final SessionStatus status;

  AcademicSession({
    String? id,
    required this.assignmentId,
    required this.sessionNumber,
    this.startedAt,
    this.endedAt,
    this.status = SessionStatus.pending,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignment_id': assignmentId,
      'session_number': sessionNumber,
      'started_at': startedAt?.millisecondsSinceEpoch,
      'ended_at': endedAt?.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  factory AcademicSession.fromMap(Map<String, dynamic> map) {
    return AcademicSession(
      id: map['id'],
      assignmentId: map['assignment_id'],
      sessionNumber: map['session_number'],
      startedAt: map['started_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['started_at']) : null,
      endedAt: map['ended_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['ended_at']) : null,
      status: SessionStatus.values.byName(map['status'] ?? 'pending'),
    );
  }
}
