import 'package:uuid/uuid.dart';

class Module {
  final String id;
  final String name;
  final String academicYear;
  final DateTime createdAt;

  Module({
    String? id,
    required this.name,
    required this.academicYear,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'academic_year': academicYear,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Module.fromMap(Map<String, dynamic> map) {
    return Module(
      id: map['id'],
      name: map['name'],
      academicYear: map['academic_year'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
}
