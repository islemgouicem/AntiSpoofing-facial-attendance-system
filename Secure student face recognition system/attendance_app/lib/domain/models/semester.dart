import 'package:uuid/uuid.dart';

class Semester {
  final String id;
  final String name;
  final String teacherId;
  final bool isActive;
  final DateTime createdAt;

  Semester({
    String? id,
    required this.name,
    required this.teacherId,
    this.isActive = true,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teacher_id': teacherId,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Semester.fromMap(Map<String, dynamic> map) {
    return Semester(
      id: map['id'],
      name: map['name'],
      teacherId: map['teacher_id'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
}
