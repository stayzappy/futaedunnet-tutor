import 'constants.dart';

class Validators {
  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(AppConstants.emailPattern);
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    
    return null;
  }
  
  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  /// Validate name (first name, last name, middle name)
  static String? validateName(String? value, {required String fieldName, bool isRequired = true}) {
    if (value == null || value.isEmpty) {
      if (isRequired) {
        return '$fieldName is required';
      }
      return null;
    }
    
    if (value.trim().length < AppConstants.minNameLength) {
      return '$fieldName must be at least ${AppConstants.minNameLength} characters';
    }
    
    if (value.trim().length > AppConstants.maxNameLength) {
      return '$fieldName must not exceed ${AppConstants.maxNameLength} characters';
    }
    
    return null;
  }
  
  /// Validate first name
  static String? validateFirstName(String? value) {
    return validateName(value, fieldName: 'First name');
  }
  
  /// Validate last name
  static String? validateLastName(String? value) {
    return validateName(value, fieldName: 'Last name');
  }
  
  /// Validate middle name (optional)
  static String? validateMiddleName(String? value) {
    return validateName(value, fieldName: 'Middle name', isRequired: false);
  }
  
  /// Validate dropdown selection
  static String? validateDropdown(dynamic value, {required String fieldName}) {
    if (value == null || (value is String && value.isEmpty)) {
      return 'Please select a $fieldName';
    }
    return null;
  }
  
  /// Validate course title
  static String? validateCourseTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Course title is required';
    }
    
    if (value.trim().length < AppConstants.minCourseTitle) {
      return 'Course title must be at least ${AppConstants.minCourseTitle} characters';
    }
    
    if (value.trim().length > AppConstants.maxCourseTitle) {
      return 'Course title must not exceed ${AppConstants.maxCourseTitle} characters';
    }
    
    return null;
  }
  
  /// Validate course code (e.g., SEN206)
  static String? validateCourseCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Course code is required';
    }
    
    final courseCodeRegex = RegExp(AppConstants.courseCodePattern);
    if (!courseCodeRegex.hasMatch(value.trim().toUpperCase())) {
      return 'Course code must be in format: ABC123 (e.g., SEN206)';
    }
    
    return null;
  }
  
  /// Validate course description
  static String? validateCourseDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Course description is required';
    }
    
    if (value.trim().length < AppConstants.minCourseDescription) {
      return 'Description must be at least ${AppConstants.minCourseDescription} characters';
    }
    
    if (value.trim().length > AppConstants.maxCourseDescription) {
      return 'Description must not exceed ${AppConstants.maxCourseDescription} characters';
    }
    
    return null;
  }
  
  /// Validate unit title
  static String? validateUnitTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Unit title is required';
    }
    
    if (value.trim().length < AppConstants.minUnitTitle) {
      return 'Unit title must be at least ${AppConstants.minUnitTitle} characters';
    }
    
    if (value.trim().length > AppConstants.maxUnitTitle) {
      return 'Unit title must not exceed ${AppConstants.maxUnitTitle} characters';
    }
    
    return null;
  }
  
  /// Validate unit order
  static String? validateUnitOrder(String? value) {
    if (value == null || value.isEmpty) {
      return 'Unit order is required';
    }
    
    final order = int.tryParse(value);
    if (order == null || order < 1) {
      return 'Please enter a valid order number (1 or greater)';
    }
    
    return null;
  }
  
  /// Validate file size
  static String? validateFileSize(int fileSizeInBytes, int maxSizeInBytes, String fileType) {
    if (fileSizeInBytes > maxSizeInBytes) {
      final maxSizeMB = maxSizeInBytes / (1024 * 1024);
      return '$fileType size must not exceed ${maxSizeMB.toStringAsFixed(0)}MB';
    }
    return null;
  }
  
  /// Validate image file
  static String? validateImageFile(String fileName, int fileSizeInBytes) {
    final extension = fileName.split('.').last.toLowerCase();
    
    if (!AppConstants.allowedImageTypes.contains(extension)) {
      return 'Invalid image format. Allowed: ${AppConstants.allowedImageTypes.join(", ")}';
    }
    
    return validateFileSize(
      fileSizeInBytes,
      AppConstants.maxImageSizeBytes,
      'Image',
    );
  }
  
  /// Validate video file
  static String? validateVideoFile(String fileName, int fileSizeInBytes) {
    final extension = fileName.split('.').last.toLowerCase();
    
    if (!AppConstants.allowedVideoTypes.contains(extension)) {
      return 'Invalid video format. Allowed: ${AppConstants.allowedVideoTypes.join(", ")}';
    }
    
    return validateFileSize(
      fileSizeInBytes,
      AppConstants.maxVideoSizeBytes,
      'Video',
    );
  }
}