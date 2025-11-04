class TextHelper {
  /// Capitalize first letter of each word
  /// Example: "akintola samuel" -> "Akintola Samuel"
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    
    return text
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
  
  /// Capitalize first letter of string
  /// Example: "hello world" -> "Hello world"
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    
    final trimmed = text.trim();
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
  
  /// Convert to uppercase
  static String toUpperCase(String text) {
    return text.trim().toUpperCase();
  }
  
  /// Convert to lowercase
  static String toLowerCase(String text) {
    return text.trim().toLowerCase();
  }
  
  /// Sanitize name input (capitalize each word)
  static String sanitizeName(String name) {
    return capitalizeWords(name);
  }
  
  /// Sanitize course code (convert to uppercase)
  static String sanitizeCourseCode(String code) {
    return toUpperCase(code);
  }
  
  /// Sanitize school/faculty/department name
  static String sanitizeInstitutionName(String name) {
    return capitalizeWords(name);
  }
  
  /// Get initials from name
  /// Example: "John Doe" -> "JD"
  static String getInitials(String name, {int maxInitials = 2}) {
    if (name.isEmpty) return '';
    
    final words = name.trim().split(' ').where((word) => word.isNotEmpty).toList();
    final initials = words
        .take(maxInitials)
        .map((word) => word[0].toUpperCase())
        .join();
    
    return initials;
  }
  
  /// Get full name from first, last, and middle names
  static String getFullName({
    required String firstName,
    required String lastName,
    String? middleName,
  }) {
    final names = <String>[
      firstName.trim(),
      if (middleName != null && middleName.isNotEmpty) middleName.trim(),
      lastName.trim(),
    ];
    
    return names.where((name) => name.isNotEmpty).join(' ');
  }
  
  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    
    return '${text.substring(0, maxLength - ellipsis.length)}$ellipsis';
  }
  
  /// Format file size in human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
  
  /// Format duration for video player
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
  
  /// Remove HTML tags from text
  static String stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
  
  /// Get academic rank with title
  /// Example: "Dr" + "John Doe" -> "Dr. John Doe"
  static String getAcademicTitle(String rank, String name) {
    final rankMap = {
      'Mr': 'Mr.',
      'Mrs': 'Mrs.',
      'Ms': 'Ms.',
      'Dr': 'Dr.',
      'Prof': 'Prof.',
    };
    
    final title = rankMap[rank] ?? rank;
    return '$title $name';
  }
  
  /// Validate and sanitize email
  static String sanitizeEmail(String email) {
    return email.trim().toLowerCase();
  }
  
  /// Get course level display name
  static String getCourseLevelDisplay(String level) {
    return '$level Level';
  }
  
  /// Check if string contains only whitespace
  static bool isBlank(String? text) {
    return text == null || text.trim().isEmpty;
  }
  
  /// Check if string is not blank
  static bool isNotBlank(String? text) {
    return !isBlank(text);
  }
}