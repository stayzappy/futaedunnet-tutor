class Enrollment {
  final String id;
  final String student;
  final String course;
  final DateTime enrolledAt;
  final DateTime created;
  final DateTime updated;
  
  // Expanded fields (from relations)
  final StudentInfo? studentInfo;
  final CourseInfo? courseInfo;

  Enrollment({
    required this.id,
    required this.student,
    required this.course,
    required this.enrolledAt,
    required this.created,
    required this.updated,
    this.studentInfo,
    this.courseInfo,
  });

  /// Create Enrollment from JSON
  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'] ?? '',
      student: json['student'] ?? '',
      course: json['course'] ?? '',
      enrolledAt: json['enrolledAt'] != null 
          ? DateTime.parse(json['enrolledAt']) 
          : DateTime.now(),
      created: json['created'] != null 
          ? DateTime.parse(json['created']) 
          : DateTime.now(),
      updated: json['updated'] != null 
          ? DateTime.parse(json['updated']) 
          : DateTime.now(),
      studentInfo: json['expand'] != null && json['expand']['student'] != null
          ? StudentInfo.fromJson(json['expand']['student'])
          : null,
      courseInfo: json['expand'] != null && json['expand']['course'] != null
          ? CourseInfo.fromJson(json['expand']['course'])
          : null,
    );
  }

  /// Convert Enrollment to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student': student,
      'course': course,
      'enrolledAt': enrolledAt.toIso8601String(),
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Enrollment copyWith({
    String? id,
    String? student,
    String? course,
    DateTime? enrolledAt,
    DateTime? created,
    DateTime? updated,
    StudentInfo? studentInfo,
    CourseInfo? courseInfo,
  }) {
    return Enrollment(
      id: id ?? this.id,
      student: student ?? this.student,
      course: course ?? this.course,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      studentInfo: studentInfo ?? this.studentInfo,
      courseInfo: courseInfo ?? this.courseInfo,
    );
  }

  @override
  String toString() {
    return 'Enrollment(id: $id, student: $student, course: $course, enrolledAt: $enrolledAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Enrollment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Student Info from expanded relation
class StudentInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String matricNumber;
  final String email;
  final String school;
  final String faculty;
  final String? department;
  final String? departmentManual;

  StudentInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.matricNumber,
    required this.email,
    required this.school,
    required this.faculty,
    this.department,
    this.departmentManual,
  });

  String get fullName {
    final names = <String>[
      firstName,
      if (middleName != null && middleName!.isNotEmpty) middleName!,
      lastName,
    ];
    return names.join(' ');
  }

  String get initials {
    return '${firstName[0]}${lastName[0]}'.toUpperCase();
  }

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      middleName: json['middleName'],
      matricNumber: json['matricNumber'] ?? '',
      email: json['email'] ?? '',
      school: json['school'] ?? '',
      faculty: json['faculty'] ?? '',
      department: json['department'],
      departmentManual: json['departmentManual'],
    );
  }
}

// Course Info from expanded relation
class CourseInfo {
  final String id;
  final String title;
  final String code;
  final String level;
  final String semester;

  CourseInfo({
    required this.id,
    required this.title,
    required this.code,
    required this.level,
    required this.semester,
  });

  factory CourseInfo.fromJson(Map<String, dynamic> json) {
    return CourseInfo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      code: json['code'] ?? '',
      level: json['level'] ?? '100',
      semester: json['semester'] ?? '1st Semester',
    );
  }
}