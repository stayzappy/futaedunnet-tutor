class Course {
  final String id;
  final String title;
  final String code;
  final String description;
  final String? displayPicture;
  final String tutor;
  final String department;
  final String level;
  final String semester;
  final bool isPublic;
  final DateTime created;
  final DateTime updated;

  Course({
    required this.id,
    required this.title,
    required this.code,
    required this.description,
    this.displayPicture,
    required this.tutor,
    required this.department,
    required this.level,
    required this.semester,
    this.isPublic = false,
    required this.created,
    required this.updated,
  });

  /// Get display picture URL
  String? getDisplayPictureUrl(String collectionId) {
    if (displayPicture == null || displayPicture!.isEmpty) return null;
    return 'http://127.0.0.1:8090/api/files/$collectionId/$id/$displayPicture';
  }

  /// Get thumbnail URL
  String? getThumbnailUrl(String collectionId, {String size = '200x200'}) {
    if (displayPicture == null || displayPicture!.isEmpty) return null;
    return 'http://127.0.0.1:8090/api/files/$collectionId/$id/$displayPicture?thumb=$size';
  }

  /// Create Course from JSON
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      displayPicture: json['displayPicture'],
      tutor: json['tutor'] ?? '',
      department: json['department'] ?? '',
      level: json['level'] ?? '100',
      semester: json['semester'] ?? '1st Semester',
      isPublic: json['isPublic'] ?? false,
      created: json['created'] != null 
          ? DateTime.parse(json['created']) 
          : DateTime.now(),
      updated: json['updated'] != null 
          ? DateTime.parse(json['updated']) 
          : DateTime.now(),
    );
  }

  /// Convert Course to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'code': code,
      'description': description,
      'displayPicture': displayPicture,
      'tutor': tutor,
      'department': department,
      'level': level,
      'semester': semester,
      'isPublic': isPublic,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Course copyWith({
    String? id,
    String? title,
    String? code,
    String? description,
    String? displayPicture,
    String? tutor,
    String? department,
    String? level,
    String? semester,
    bool? isPublic,
    DateTime? created,
    DateTime? updated,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      code: code ?? this.code,
      description: description ?? this.description,
      displayPicture: displayPicture ?? this.displayPicture,
      tutor: tutor ?? this.tutor,
      department: department ?? this.department,
      level: level ?? this.level,
      semester: semester ?? this.semester,
      isPublic: isPublic ?? this.isPublic,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  String toString() {
    return 'Course(id: $id, title: $title, code: $code, level: $level, semester: $semester)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}