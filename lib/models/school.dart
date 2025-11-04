class School {
  final String id;
  final String name;
  final String code;
  final DateTime created;
  final DateTime updated;

  School({
    required this.id,
    required this.name,
    required this.code,
    required this.created,
    required this.updated,
  });

  /// Create School from JSON
  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      created: json['created'] != null 
          ? DateTime.parse(json['created']) 
          : DateTime.now(),
      updated: json['updated'] != null 
          ? DateTime.parse(json['updated']) 
          : DateTime.now(),
    );
  }

  /// Convert School to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  School copyWith({
    String? id,
    String? name,
    String? code,
    DateTime? created,
    DateTime? updated,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  String toString() {
    return 'School(id: $id, name: $name, code: $code)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is School && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}