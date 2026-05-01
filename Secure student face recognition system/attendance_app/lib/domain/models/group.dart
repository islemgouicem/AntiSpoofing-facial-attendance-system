import 'package:uuid/uuid.dart';

/// Group domain model.
class Group {
  final String id;
  final String name; // e.g. "G1", "G2"
  final String academicYear; // e.g. "Year 1", "Year 2"
  final DateTime createdAt;
  final DateTime updatedAt;
  final int studentCount;

  Group({
    String? id,
    required this.name,
    required this.academicYear,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.studentCount = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Group copyWith({
    String? name,
    String? academicYear,
    DateTime? updatedAt,
    int? studentCount,
  }) =>
      Group(
        id: id,
        name: name ?? this.name,
        academicYear: academicYear ?? this.academicYear,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
        studentCount: studentCount ?? this.studentCount,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'academic_year': academicYear,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Group.fromMap(Map<String, dynamic> m) => Group(
        id: m['id'] as String,
        name: m['name'] as String,
        academicYear: m['academic_year'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
        studentCount: m['student_count'] as int? ?? 0,
      );
}
