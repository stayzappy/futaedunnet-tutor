class Faculty {
  final String id;
  final String name;
  final String code;
  final String school;
  final DateTime created;
  final DateTime updated;

  Faculty({
    required this.id,
    required this.name,
    required this.code,
    required this.school,
    required this.created,
    required this.updated,
  });

  /// Create Faculty from JSON
  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      school: json['school'] ?? '',
      created: json['created'] != null 
          ? DateTime.parse(json['created']) 
          : DateTime.now(),
      updated: json['updated'] != null 
          ? DateTime.parse(json['updated']) 
          : DateTime.now(),
    );
  }

  /// Convert Faculty to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'school': school,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Faculty copyWith({
    String? id,
    String? name,
    String? code,
    String? school,
    DateTime? created,
    DateTime? updated,
  }) {
    return Faculty(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      school: school ?? this.school,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  String toString() {
    return 'Faculty(id: $id, name: $name, code: $code, school: $school)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Faculty && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}