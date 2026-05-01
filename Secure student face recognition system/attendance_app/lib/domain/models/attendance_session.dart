/// Attendance session domain model.
enum SessionStatus { active, completed, cancelled }

class AttendanceSession {
  final String id;
  final String? groupId;
  final String? title;
  final DateTime startedAt;
  final DateTime? endedAt;
  final SessionStatus status;
  final String? groupName;
  final int presentCount;
  final int totalCount;

  const AttendanceSession({
    required this.id,
    this.groupId,
    this.title,
    required this.startedAt,
    this.endedAt,
    this.status = SessionStatus.active,
    this.groupName,
    this.presentCount = 0,
    this.totalCount = 0,
  });

  Duration get duration =>
      (endedAt ?? DateTime.now()).difference(startedAt);

  double get attendanceRate =>
      totalCount > 0 ? presentCount / totalCount : 0;

  AttendanceSession copyWith({
    DateTime? endedAt,
    SessionStatus? status,
    int? presentCount,
    int? totalCount,
  }) =>
      AttendanceSession(
        id: id,
        groupId: groupId,
        title: title,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
        status: status ?? this.status,
        groupName: groupName,
        presentCount: presentCount ?? this.presentCount,
        totalCount: totalCount ?? this.totalCount,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'group_id': groupId,
        'title': title,
        'started_at': startedAt.millisecondsSinceEpoch,
        'ended_at': endedAt?.millisecondsSinceEpoch,
        'status': status.name,
      };

  factory AttendanceSession.fromMap(Map<String, dynamic> m) =>
      AttendanceSession(
        id: m['id'] as String,
        groupId: m['group_id'] as String?,
        title: m['title'] as String?,
        startedAt:
            DateTime.fromMillisecondsSinceEpoch(m['started_at'] as int),
        endedAt: m['ended_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['ended_at'] as int)
            : null,
        status: SessionStatus.values.firstWhere(
            (e) => e.name == (m['status'] as String? ?? 'active')),
        groupName: m['group_name'] as String?,
        presentCount: m['present_count'] as int? ?? 0,
        totalCount: m['total_count'] as int? ?? 0,
      );
}
