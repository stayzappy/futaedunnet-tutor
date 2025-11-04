class Unit {
  final String id;
  final String title;
  final String content;
  final String? video;
  final String course;
  final double order;
  final DateTime created;
  final DateTime updated;

  Unit({
    required this.id,
    required this.title,
    required this.content,
    this.video,
    required this.course,
    required this.order,
    required this.created,
    required this.updated,
  });

  /// Get video URL
  String? getVideoUrl(String collectionId) {
    if (video == null || video!.isEmpty) return null;
    return 'http://127.0.0.1:8090/api/files/$collectionId/$id/$video';
  }

  /// Check if unit has video
  bool get hasVideo {
    return video != null && video!.isNotEmpty;
  }

  /// Get unit number (order as integer)
  int get unitNumber {
    return order.toInt();
  }

  /// Create Unit from JSON
  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      video: json['video'],
      course: json['course'] ?? '',
      order: (json['order'] is int) 
          ? (json['order'] as int).toDouble()
          : (json['order'] is double)
              ? json['order'] as double
              : 1.0,
      created: json['created'] != null 
          ? DateTime.parse(json['created']) 
          : DateTime.now(),
      updated: json['updated'] != null 
          ? DateTime.parse(json['updated']) 
          : DateTime.now(),
    );
  }

  /// Convert Unit to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'video': video,
      'course': course,
      'order': order,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Unit copyWith({
    String? id,
    String? title,
    String? content,
    String? video,
    String? course,
    double? order,
    DateTime? created,
    DateTime? updated,
  }) {
    return Unit(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      video: video ?? this.video,
      course: course ?? this.course,
      order: order ?? this.order,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  String toString() {
    return 'Unit(id: $id, title: $title, order: $order, hasVideo: $hasVideo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Unit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}