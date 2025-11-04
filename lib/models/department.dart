class Department {
  final String id;
  final String name;
  final String code;
  final String faculty;
  final DateTime created;
  final DateTime updated;

  Department({
    required this.id,
    required this.name,
    required this.code,
    required this.faculty,
    required this.created,
    required this.updated,
  });

  /// Create Department from JSON
  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      faculty: json['faculty'] ?? '',
      created: json['created'] != null 
          ? DateTime.parse(json['created']) 
          : DateTime.now(),
      updated: json['updated'] != null 
          ? DateTime.parse(json['updated']) 
          : DateTime.now(),
    );
  }

  /// Convert Department to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'faculty': faculty,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Department copyWith({
    String? id,
    String? name,
    String? code,
    String? faculty,
    DateTime? created,
    DateTime? updated,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      faculty: faculty ?? this.faculty,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  String toString() {
    return 'Department(id: $id, name: $name, code: $code, faculty: $faculty)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Department && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}