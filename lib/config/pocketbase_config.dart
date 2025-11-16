import 'package:pocketbase/pocketbase.dart';

class PocketBaseConfig {
  // TODO: Replace with your actual PocketBase URL
  // Example: 'http://127.0.0.1:8090' for local development
  // or 'https://your-domain.pocketbase.io' for production
  static const String baseUrl = 'https://futaedunnet.pockethost.io/';
  
  static late PocketBase pb;
  
  // Collection names from schema
  static const String schoolsCollection = 'schools';
  static const String facultiesCollection = 'faculties';
  static const String departmentsCollection = 'departments';
  static const String tutorsCollection = 'tutors';
  static const String studentsCollection = 'students';
  static const String coursesCollection = 'courses';
  static const String unitsCollection = 'units';
  static const String enrollmentsCollection = 'enrollments';
  static const String progressCollection = 'progress';
  
  /// Initialize PocketBase instance
  static Future<void> initialize() async {
    pb = PocketBase(baseUrl);
    
    // Enable auto cancellation for requests
    //pb.autoCancellation(true);
    
    // Try to restore authentication from local storage
    try {
      if (pb.authStore.isValid) {
        // Refresh authentication if token is still valid
        await pb.collection(tutorsCollection).authRefresh();
      }
    } catch (e) {
      // Clear invalid auth
      pb.authStore.clear();
    }
  }
  
  /// Get the current authenticated tutor
  static String? get currentTutorId {
    if (pb.authStore.isValid && pb.authStore.record != null) {
      return pb.authStore.record?.id;
    }
    return null;
  }
  
  /// Check if user is authenticated
  static bool get isAuthenticated {
    return pb.authStore.isValid;
  }
  
  /// Get the current tutor model
  static dynamic get currentTutor {
    return pb.authStore.model;
  }
  
  /// Clear authentication
  static void clearAuth() {
    pb.authStore.clear();
  }
  
  /// Get file URL for uploaded files
  static String getFileUrl(String collectionId, String recordId, String filename) {
    return '$baseUrl/api/files/$collectionId/$recordId/$filename';
  }
  
  /// Get thumbnail URL for images
  static String getThumbnailUrl(
    String collectionId, 
    String recordId, 
    String filename, {
    String size = '100x100',
  }) {
    return '$baseUrl/api/files/$collectionId/$recordId/$filename?thumb=$size';
  }
}