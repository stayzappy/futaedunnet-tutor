// models/course_material.dart

class CourseMaterial {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final String materialFileName;
  final DateTime createdAt; // New field
  final DateTime updatedAt; // New field

  CourseMaterial({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.materialFileName,
    required this.createdAt, // New field
    required this.updatedAt, // New field
  });

  factory CourseMaterial.fromMap(Map<String, dynamic> map) {
    // Parse the manually added createdAt and updatedAt fields
    DateTime parsedCreatedAt = DateTime.now(); // Fallback
    final createdAtStr = map['createdAt'] as String?;
    if (createdAtStr != null) {
      try {
        parsedCreatedAt = DateTime.parse(createdAtStr);
      } catch (e) {
        print('DEBUG: CourseMaterial.fromMap - Failed to parse "createdAt": $createdAtStr, Error: $e. Using fallback.');
      }
    }

    DateTime parsedUpdatedAt = DateTime.now(); // Fallback
    final updatedAtStr = map['updatedAt'] as String?;
    if (updatedAtStr != null) {
      try {
        parsedUpdatedAt = DateTime.parse(updatedAtStr);
      } catch (e) {
        print('DEBUG: CourseMaterial.fromMap - Failed to parse "updatedAt": $updatedAtStr, Error: $e. Using fallback.');
      }
    }

    return CourseMaterial(
      id: map['id'] as String,
      courseId: map['course'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      materialFileName: map['material_file'] as String,
      createdAt: parsedCreatedAt, // Use parsed value
      updatedAt: parsedUpdatedAt, // Use parsed value
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course': courseId,
      'title': title,
      'description': description,
      'material_file': materialFileName,
      'createdAt': createdAt.toIso8601String(), // Include in map
      'updatedAt': updatedAt.toIso8601String(), // Include in map
    };
  }
}