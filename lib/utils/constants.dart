class AppConstants {
  // App Information
  static const String appName = 'FutaEdunet';
  static const String appTagline = 'Empowering Education Through Technology';
  
  // Academic Ranks
  static const List<String> academicRanks = [
    'Mr',
    'Mrs',
    'Ms',
    'Dr',
    'Prof',
  ];
  
  // Academic Levels
  static const List<String> levels = [
    '100',
    '200',
    '300',
    '400',
    '500',
  ];
  
  // Semesters
  static const List<String> semesters = [
    '1st Semester',
    '2nd Semester',
  ];
  
  // File Size Limits
  static const int maxImageSizeMB = 5;
  static const int maxVideoSizeMB = 500;
  static const int maxImageSizeBytes = maxImageSizeMB * 1024 * 1024;
  static const int maxVideoSizeBytes = maxVideoSizeMB * 1024 * 1024;
  
  // Allowed File Types
  static const List<String> allowedImageTypes = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  
  static const List<String> allowedVideoTypes = [
    'mp4',
    'webm',
    'ogg',
    'mkv',
    'mov',
    'avi',
  ];
  
  // Validation Patterns
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String courseCodePattern = r'^[A-Z]{3}\d{3}$';
  
  // Text Field Limits
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int minCourseTitle = 5;
  static const int maxCourseTitle = 300;
  static const int minCourseDescription = 10;
  static const int maxCourseDescription = 2000;
  static const int minUnitTitle = 3;
  static const int maxUnitTitle = 300;
  static const int minPasswordLength = 8;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Padding & Spacing
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  
  // Icon Sizes
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  
  // Breakpoints for Responsive Design
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  // Error Messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String authError = 'Authentication failed. Please login again.';
  static const String validationError = 'Please check your input and try again.';
  
  // Success Messages
  static const String signupSuccess = 'Account created successfully!';
  static const String loginSuccess = 'Welcome back!';
  static const String courseCreatedSuccess = 'Course created successfully!';
  static const String courseUpdatedSuccess = 'Course updated successfully!';
  static const String unitCreatedSuccess = 'Unit created successfully!';
  static const String unitUpdatedSuccess = 'Unit updated successfully!';
  
  // Placeholder Colors for Login Screen Slideshow
  // TODO: Replace these with actual education-related images
  static const List<String> loginBackgroundColors = [
    '0xFF1E3A8A', // Deep Blue
    '0xFF7C3AED', // Purple
    '0xFF059669', // Green
  ];
  
  // Video Player Settings
  static const double aspectRatio = 16 / 9;
  static const bool autoPlay = false;
  static const bool looping = false;
  
  // Shimmer Loading Colors
  static const int shimmerBaseColor = 0xFF2D2D2D;
  static const int shimmerHighlightColor = 0xFF3D3D3D;
}