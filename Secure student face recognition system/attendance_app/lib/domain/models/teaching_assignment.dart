import 'package:uuid/uuid.dart';

class TeachingAssignment {
  final String id;
  final String semesterId;
  final String moduleId;
  final String groupId;
  final String sessionType; // 'Tutorial' or 'Lab'
  final String? moduleName;
  final String? groupName;

  TeachingAssignment({
    String? id,
    required this.semesterId,
    required this.moduleId,
    required this.groupId,
    required this.sessionType,
    this.moduleName,
    this.groupName,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'semester_id': semesterId,
      'module_id': moduleId,
      'group_id': groupId,
      'session_type': sessionType,
    };
  }

  factory TeachingAssignment.fromMap(Map<String, dynamic> map) {
    return TeachingAssignment(
      id: map['id'],
      semesterId: map['semester_id'],
      moduleId: map['module_id'],
      groupId: map['group_id'],
      sessionType: map['session_type'],
      moduleName: map['module_name'],
      groupName: map['group_name'],
    );
  }
}
