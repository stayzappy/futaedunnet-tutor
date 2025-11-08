// models/course_announcement.dart

class CourseAnnouncement {
  final String id;
  final String courseId;
  final String title;
  final String content;
  final DateTime createdAt; // New field
  final DateTime updatedAt; // New field

  CourseAnnouncement({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.createdAt, // New field
    required this.updatedAt, // New field
  });

  factory CourseAnnouncement.fromMap(Map<String, dynamic> map) {
    // Parse the manually added createdAt and updatedAt fields
    DateTime parsedCreatedAt = DateTime.now(); // Fallback
    final createdAtStr = map['createdAt'] as String?;
    if (createdAtStr != null) {
      try {
        parsedCreatedAt = DateTime.parse(createdAtStr);
      } catch (e) {
        print('DEBUG: CourseAnnouncement.fromMap - Failed to parse "createdAt": $createdAtStr, Error: $e. Using fallback.');
      }
    }

    DateTime parsedUpdatedAt = DateTime.now(); // Fallback
    final updatedAtStr = map['updatedAt'] as String?;
    if (updatedAtStr != null) {
      try {
        parsedUpdatedAt = DateTime.parse(updatedAtStr);
      } catch (e) {
        print('DEBUG: CourseAnnouncement.fromMap - Failed to parse "updatedAt": $updatedAtStr, Error: $e. Using fallback.');
      }
    }

    return CourseAnnouncement(
      id: map['id'] as String,
      courseId: map['course'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: parsedCreatedAt, // Use parsed value
      updatedAt: parsedUpdatedAt, // Use parsed value
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course': courseId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(), // Include in map
      'updatedAt': updatedAt.toIso8601String(), // Include in map
    };
  }
}