import 'dart:typed_data';
import '../models/course.dart';
import '../models/department.dart';
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
}