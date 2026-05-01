/// Student domain model.
class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? studentId;
  final bool faceRegistered;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.studentId,
    this.faceRegistered = false,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  Student copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? studentId,
    bool? faceRegistered,
    String? photoPath,
    DateTime? updatedAt,
  }) =>
      Student(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        studentId: studentId ?? this.studentId,
        faceRegistered: faceRegistered ?? this.faceRegistered,
        photoPath: photoPath ?? this.photoPath,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'student_id': studentId,
        'face_registered': faceRegistered ? 1 : 0,
        'photo_path': photoPath,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Student.fromMap(Map<String, dynamic> m) => Student(
        id: m['id'] as String,
        firstName: m['first_name'] as String,
        lastName: m['last_name'] as String,
        email: m['email'] as String?,
        studentId: m['student_id'] as String?,
        faceRegistered: (m['face_registered'] as int? ?? 0) == 1,
        photoPath: m['photo_path'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );
}
