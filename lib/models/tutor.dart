class Tutor {
  final String id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String academicRank;
  final String school;
  final String faculty;
  final String? department;
  final String? departmentManual;
  final String email;
  final bool emailVisibility;
  final bool verified;
  final DateTime created;
  final DateTime updated;

  Tutor({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.academicRank,
    required this.school,
    required this.faculty,
    this.department,
    this.departmentManual,
    required this.email,
    this.emailVisibility = false,
    this.verified = false,
    required this.created,
    required this.updated,
  });

  /// Get full name
  String get fullName {
    final names = <String>[
      firstName,
      if (middleName != null && middleName!.isNotEmpty) middleName!,
      lastName,
    ];
    return names.join(' ');
  }

  /// Get name with academic rank
  String get fullNameWithRank {
    final rankMap = {
      'Mr': 'Mr.',
      'Mrs': 'Mrs.',
      'Ms': 'Ms.',
      'Dr': 'Dr.',
      'Prof': 'Prof.',
    };
    final title = rankMap[academicRank] ?? academicRank;
    return '$title $fullName';
  }

  /// Get initials
  String get initials {
    return '${firstName[0]}${lastName[0]}'.toUpperCase();
  }

  /// Create Tutor from JSON
  factory Tutor.fromJson(Map<String, dynamic> json) {
    return Tutor(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      middleName: json['middleName'],
      academicRank: json['academicRank'] ?? 'Mr',
      school: json['school'] ?? '',
      faculty: json['faculty'] ?? '',
      department: json['department'],
      departmentManual: json['departmentManual'],
      email: json['email'] ?? '',
      emailVisibility: json['emailVisibility'] ?? false,
      verified: json['verified'] ?? false,
      created: json['created'] != null 
          ? DateTime.parse(json['created']) 
          : DateTime.now(),
      updated: json['updated'] != null 
          ? DateTime.parse(json['updated']) 
          : DateTime.now(),
    );
  }

  /// Convert Tutor to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'academicRank': academicRank,
      'school': school,
      'faculty': faculty,
      'department': department,
      'departmentManual': departmentManual,
      'email': email,
      'emailVisibility': emailVisibility,
      'verified': verified,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Tutor copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? middleName,
    String? academicRank,
    String? school,
    String? faculty,
    String? department,
    String? departmentManual,
    String? email,
    bool? emailVisibility,
    bool? verified,
    DateTime? created,
    DateTime? updated,
  }) {
    return Tutor(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      academicRank: academicRank ?? this.academicRank,
      school: school ?? this.school,
      faculty: faculty ?? this.faculty,
      department: department ?? this.department,
      departmentManual: departmentManual ?? this.departmentManual,
      email: email ?? this.email,
      emailVisibility: emailVisibility ?? this.emailVisibility,
      verified: verified ?? this.verified,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  String toString() {
    return 'Tutor(id: $id, name: $fullName, email: $email, rank: $academicRank)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tutor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}