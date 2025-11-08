// services/course_service.dart

import 'dart:typed_data';
import 'package:http/http.dart';
//import 'package:http_parser/http_parser.dart'; // For MultipartFile
import '../models/course.dart';
import '../models/department.dart';
import '../models/course_material.dart'; // Add this new import
import '../models/course_announcement.dart'; // Add this new import
import 'pocketbase_service.dart';
import '../utils/text_helper.dart';
import '../config/pocketbase_config.dart';

class CourseService {
  final PocketBaseService _pbService;

  CourseService(this._pbService);

  /// Get all courses for a tutor
  Future<List<Course>> getCoursesByTutor(String tutorId) async {
    try {
      return await _pbService.getCoursesByTutor(tutorId);
    } catch (e) {
      throw Exception('Failed to fetch courses: ${e.toString()}');
    }
  }

  /// Get a single course by ID
  Future<Course> getCourse(String courseId) async {
    try {
      return await _pbService.getCourse(courseId);
    } catch (e) {
      throw Exception('Failed to fetch course: ${e.toString()}');
    }
  }

  /// Create a new course
  Future<Course> createCourse({
    required String title,
    required String code,
    required String description,
    required String tutorId,
    required String departmentId,
    required String level,
    required String semester,
    Uint8List? displayPictureBytes,
    String? displayPictureFileName,
    bool isPublic = false,
  }) async {
    try {
      // Sanitize input data
      final sanitizedTitle = TextHelper.capitalizeWords(title);
      final sanitizedCode = TextHelper.sanitizeCourseCode(code);
      final sanitizedDescription = TextHelper.capitalizeFirst(description);

      // Create course without image first
      final course = await _pbService.createCourse(
        title: sanitizedTitle,
        code: sanitizedCode,
        description: sanitizedDescription,
        tutorId: tutorId,
        departmentId: departmentId,
        level: level,
        semester: semester,
        isPublic: isPublic,
      );

      // Upload display picture if provided
      if (displayPictureBytes != null && displayPictureFileName != null) {
        await _pbService.uploadFile(
          PocketBaseConfig.coursesCollection,
          course.id,
          'displayPicture',
          displayPictureBytes,
          displayPictureFileName,
        );
        
        // Fetch updated course with image
        return await _pbService.getCourse(course.id);
      }

      return course;
    } catch (e) {
      throw Exception('Failed to create course: ${e.toString()}');
    }
  }

  /// Update an existing course
  Future<Course> updateCourse({
    required String courseId,
    String? title,
    String? code,
    String? description,
    String? departmentId,
    String? level,
    String? semester,
    Uint8List? displayPictureBytes,
    String? displayPictureFileName,
    bool? isPublic,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      // Sanitize and add fields to update
      if (title != null) {
        updateData['title'] = TextHelper.capitalizeWords(title);
      }
      if (code != null) {
        updateData['code'] = TextHelper.sanitizeCourseCode(code);
      }
      if (description != null) {
        updateData['description'] = TextHelper.capitalizeFirst(description);
      }
      if (departmentId != null) {
        updateData['department'] = departmentId;
      }
      if (level != null) {
        updateData['level'] = level;
      }
      if (semester != null) {
        updateData['semester'] = semester;
      }
      if (isPublic != null) {
        updateData['isPublic'] = isPublic;
      }

      // Update course data
      final course = await _pbService.updateCourse(courseId, updateData);

      // Upload new display picture if provided
      if (displayPictureBytes != null && displayPictureFileName != null) {
        await _pbService.uploadFile(
          PocketBaseConfig.coursesCollection,
          courseId,
          'displayPicture',
          displayPictureBytes,
          displayPictureFileName,
        );
        
        // Fetch updated course with new image
        return await _pbService.getCourse(courseId);
      }

      return course;
    } catch (e) {
      throw Exception('Failed to update course: ${e.toString()}');
    }
  }

  /// Delete a course
  Future<void> deleteCourse(String courseId) async {
    try {
      await _pbService.deleteCourse(courseId);
    } catch (e) {
      throw Exception('Failed to delete course: ${e.toString()}');
    }
  }

  /// Get departments by faculty ID (for course creation/editing)
  Future<List<Department>> getDepartmentsByFaculty(String facultyId) async {
    try {
      return await _pbService.getDepartmentsByFaculty(facultyId);
    } catch (e) {
      throw Exception('Failed to fetch departments: ${e.toString()}');
    }
  }

  /// Get course count for a tutor
  Future<int> getCourseCount(String tutorId) async {
    try {
      final courses = await getCoursesByTutor(tutorId);
      return courses.length;
    } catch (e) {
      return 0;
    }
  }

  /// Check if course code exists for tutor
  Future<bool> courseCodeExists(String tutorId, String code, {String? excludeCourseId}) async {
    try {
      final courses = await getCoursesByTutor(tutorId);
      final sanitizedCode = TextHelper.sanitizeCourseCode(code);
      
      return courses.any((course) => 
        course.code.toUpperCase() == sanitizedCode && 
        course.id != excludeCourseId
      );
    } catch (e) {
      return false;
    }
  }

  // --- New Methods for Course Materials ---

  /// Get materials for a specific course
  Future<List<CourseMaterial>> getCourseMaterials(String courseId) async {
    try {
      return await _pbService.getCourseMaterials(courseId);
    } catch (e) {
      throw Exception('Failed to fetch course materials: ${e.toString()}');
    }
  }

  /// Create a new course material
  Future<CourseMaterial> createCourseMaterial({
    required String courseId,
    required String title,
    String? description,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      // Sanitize input data
      final sanitizedTitle = TextHelper.capitalizeWords(title);
      final sanitizedDescription = description != null ? TextHelper.capitalizeFirst(description) : null;
      final now = DateTime.now(); // Get current time

      // Step 1: Prepare data map for the initial record creation (without file)
      final Map<String, dynamic> data = {
        'course': courseId,
        'title': sanitizedTitle,
        'createdAt': now.toIso8601String(), // Add manual timestamp
        'updatedAt': now.toIso8601String(), // Add manual timestamp
      };
      if (sanitizedDescription != null) {
        data['description'] = sanitizedDescription;
      }

      // Step 2: Create the record in PocketBase (without the file initially)
      // Use the standard createRecord method which handles non-file data
      final result = await _pbService.createRecord(
        'course_materials', // Use the new collection name
        data,
      );

      // Extract the ID of the newly created record
      final newMaterialId = result['id'] as String;
      print('DEBUG: CourseService.createCourseMaterial - Created record with ID: $newMaterialId');

      // Step 3: Upload the file to the specific field of the newly created record
      // Use the existing uploadFile method which updates an existing record
      await _pbService.uploadFile(
        'course_materials', // Collection name
        newMaterialId,      // ID of the record to update
        'material_file',    // Field name in the collection schema
        fileBytes,          // The file bytes
        fileName,           // The original filename
      );

      print('DEBUG: CourseService.createCourseMaterial - Uploaded file for record ID: $newMaterialId');

      // Step 4: Fetch the updated record to get the final state including the filename
      // You might need to add a getCourseMaterialById method to PocketBaseService and CourseService
      // For now, assume the PocketBaseService can fetch the updated record
      final finalRecord = await _pbService.getRecordById('course_materials', newMaterialId);
      return CourseMaterial.fromMap(finalRecord);

    } catch (e) {
      throw Exception('Failed to create course material: ${e.toString()}');
    }
  }

  /// Delete a course material
  Future<void> deleteCourseMaterial(String materialId) async {
    try {
      await _pbService.deleteRecord('course_materials', materialId);
    } catch (e) {
      throw Exception('Failed to delete course material: ${e.toString()}');
    }
  }

  // --- New Methods for Course Announcements ---

  /// Get announcements for a specific course
  Future<List<CourseAnnouncement>> getCourseAnnouncements(String courseId) async {
    try {
      return await _pbService.getCourseAnnouncements(courseId);
    } catch (e) {
      throw Exception('Failed to fetch course announcements: ${e.toString()}');
    }
  }

  /// Create a new course announcement
  Future<CourseAnnouncement> createCourseAnnouncement({
    required String courseId,
    required String title,
    required String content,
  }) async {
    try {
      // Sanitize input data
      final sanitizedTitle = TextHelper.capitalizeWords(title);
      final sanitizedContent = TextHelper.capitalizeFirst(content);
      final now = DateTime.now(); // Get current time

      // Prepare data map - Include manual timestamps
      final Map<String, dynamic> data = {
        'course': courseId,
        'title': sanitizedTitle,
        'content': sanitizedContent,
        'createdAt': now.toIso8601String(), // Add manual timestamp
        'updatedAt': now.toIso8601String(), // Add manual timestamp
      };

      // Create record
      final result = await _pbService.createRecord(
        'course_announcements', // Use the new collection name
        data,
      );

      return CourseAnnouncement.fromMap(result);
    } catch (e) {
      throw Exception('Failed to create course announcement: ${e.toString()}');
    }
  }

  /// Update an existing course announcement
  Future<CourseAnnouncement> updateCourseAnnouncement({
    required String announcementId,
    String? title,
    String? content,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      final now = DateTime.now(); // Get current time

      if (title != null) {
        updateData['title'] = TextHelper.capitalizeWords(title);
      }
      if (content != null) {
        updateData['content'] = TextHelper.capitalizeFirst(content);
      }
      // Always update the updatedAt field when updating
      updateData['updatedAt'] = now.toIso8601String();

      // Update record
      final result = await _pbService.updateRecord(
        'course_announcements', // Use the new collection name
        announcementId,
        updateData,
      );

      return CourseAnnouncement.fromMap(result);
    } catch (e) {
      throw Exception('Failed to update course announcement: ${e.toString()}');
    }
  }

  /// Delete a course announcement
  Future<void> deleteCourseAnnouncement(String announcementId) async {
    try {
      await _pbService.deleteRecord('course_announcements', announcementId);
    } catch (e) {
      throw Exception('Failed to delete course announcement: ${e.toString()}');
    }
  }

  // --- Helper Method ---
  String _getMimeType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream'; // Default fallback
    }
  }
}