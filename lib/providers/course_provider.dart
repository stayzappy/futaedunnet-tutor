import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/department.dart';
import '../models/course_material.dart'; // Add import
import '../models/course_announcement.dart'; // Add import
// import '../models/unit.dart'; // Remove import as units are managed elsewhere
import '../services/pocketbase_service.dart';
import '../services/course_service.dart';

class CourseProvider extends ChangeNotifier {
  final PocketBaseService _pbService;
  late final CourseService _courseService;
  
  List<Course> _courses = [];
  Course? _selectedCourse;
  List<Department> _departments = [];
  // List<Unit> _units = []; // Remove units state
  List<CourseMaterial> _materials = []; // State for course materials
  List<CourseAnnouncement> _announcements = []; // State for course announcements
  bool _isLoading = false;
  String? _errorMessage;

  CourseProvider(this._pbService) {
    _courseService = CourseService(_pbService);
  }

  // Getters
  List<Course> get courses => _courses;
  Course? get selectedCourse => _selectedCourse;
  List<Department> get departments => _departments;
  // List<Unit> get units => _units; // Remove units getter
  List<CourseMaterial> get materials => _materials; // Getter for materials
  List<CourseAnnouncement> get announcements => _announcements; // Getter for announcements
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCourses => _courses.isNotEmpty;

  /// Load courses for a tutor
  Future<void> loadCourses(String tutorId) async {
    _setLoading(true);
    _clearError();

    try {
      _courses = await _courseService.getCoursesByTutor(tutorId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load courses: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Load a single course
Future<void> loadCourse(String courseId) async {
    print('DEBUG: CourseProvider.loadCourse - START - ID: $courseId');
    _setLoading(true);
    _clearError();

    try {
      _selectedCourse = await _courseService.getCourse(courseId);
      print('DEBUG: CourseProvider.loadCourse - Set _selectedCourse to ID: ${_selectedCourse?.id}');
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load course: ${e.toString()}');
      _setLoading(false);
    }
    print('DEBUG: CourseProvider.loadCourse - END - ID: $courseId');
  }


  // /// Load units for a specific course (if managed by this provider) - REMOVED
  // Future<void> loadCourseUnits(String courseId) async {
  //   _setLoading(true);
  //   _clearError();
  //
  //   try {
  //     _units = await _courseService.getUnitsByCourse(courseId); // Assumes this method exists in CourseService
  //     _setLoading(false);
  //     notifyListeners();
  //   } catch (e) {
  //     _setError('Failed to load units: ${e.toString()}');
  //     _setLoading(false);
  //   }
  // }

  /// Create a new course
  Future<bool> createCourse({
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
    _setLoading(true);
    _clearError();

    try {
      final course = await _courseService.createCourse(
        title: title,
        code: code,
        description: description,
        tutorId: tutorId,
        departmentId: departmentId,
        level: level,
        semester: semester,
        displayPictureBytes: displayPictureBytes,
        displayPictureFileName: displayPictureFileName,
        isPublic: isPublic,
      );

      _courses.insert(0, course);
      _selectedCourse = course;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create course: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update an existing course
  Future<bool> updateCourse({
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
    _setLoading(true);
    _clearError();

    try {
      final updatedCourse = await _courseService.updateCourse(
        courseId: courseId,
        title: title,
        code: code,
        description: description,
        departmentId: departmentId,
        level: level,
        semester: semester,
        displayPictureBytes: displayPictureBytes,
        displayPictureFileName: displayPictureFileName,
        isPublic: isPublic,
      );

      // Update in list
      final index = _courses.indexWhere((c) => c.id == courseId);
      if (index != -1) {
        _courses[index] = updatedCourse;
      }
      
      _selectedCourse = updatedCourse;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update course: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Delete a course
  Future<bool> deleteCourse(String courseId) async {
    _setLoading(true);
    _clearError();

    try {
      await _courseService.deleteCourse(courseId);
      
      _courses.removeWhere((c) => c.id == courseId);
      if (_selectedCourse?.id == courseId) {
        _selectedCourse = null;
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete course: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Load departments by faculty
  Future<void> loadDepartmentsByFaculty(String facultyId) async {
    _clearError();

    try {
      _departments = await _courseService.getDepartmentsByFaculty(facultyId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load departments: ${e.toString()}');
    }
  }

  /// Set selected course
  void setSelectedCourse(Course course) {
    _selectedCourse = course;
    notifyListeners();
  }

  /// Clear selected course
  void clearSelectedCourse() {
    _selectedCourse = null;
    notifyListeners();
  }

  /// Get course count
  int get courseCount => _courses.length;

  /// Check if course code exists
  Future<bool> checkCourseCodeExists(String tutorId, String code, {String? excludeCourseId}) async {
    try {
      return await _courseService.courseCodeExists(tutorId, code, excludeCourseId: excludeCourseId);
    } catch (e) {
      return false;
    }
  }

  /// Refresh courses
  Future<void> refreshCourses(String tutorId) async {
    await loadCourses(tutorId);
  }

  // --- New Methods for Course Materials ---

 Future<void> loadCourseMaterials(String courseId) async {
    print('DEBUG: CourseProvider.loadCourseMaterials - START - Course ID: $courseId');
    _setLoading(true);
    _clearError();

    try {
      _materials = await _courseService.getCourseMaterials(courseId);
      print('DEBUG: CourseProvider.loadCourseMaterials - Loaded ${_materials.length} materials for course: $courseId');
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load course materials: ${e.toString()}');
      _setLoading(false);
    }
    print('DEBUG: CourseProvider.loadCourseMaterials - END - Course ID: $courseId');
  }

  /// Add a new material to a specific course
  Future<bool> addMaterialToCourse({
    required String courseId,
    required String title,
    String? description,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final newMaterial = await _courseService.createCourseMaterial(
        courseId: courseId,
        title: title,
        description: description,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      _materials.add(newMaterial);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add material: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Remove a material from a specific course
  Future<bool> removeMaterialFromCourse({
    required String courseId,
    required String materialId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _courseService.deleteCourseMaterial(materialId);
      _materials.removeWhere((m) => m.id == materialId);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to remove material: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // --- Methods for Course Announcements ---
  // Remove loadSelectedCourseAnnouncements (rely on loadCourseAnnouncements with courseId)

  /// Load announcements for a specific course
 Future<void> loadCourseAnnouncements(String courseId) async {
    print('DEBUG: CourseProvider.loadCourseAnnouncements - START - Course ID: $courseId');
    _setLoading(true);
    _clearError();

    try {
      _announcements = await _courseService.getCourseAnnouncements(courseId);
      print('DEBUG: CourseProvider.loadCourseAnnouncements - Loaded ${_announcements.length} announcements for course: $courseId');
      // Sort announcements by creation date (newest first)
      _announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      print('DEBUG: CourseProvider.loadCourseAnnouncements - Sorted announcements for course: $courseId');
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('DEBUG: CourseProvider.loadCourseAnnouncements - ERROR: ${e.toString()}');
      _setError('Failed to load course announcements: ${e.toString()}');
      _setLoading(false);
    }
    print('DEBUG: CourseProvider.loadCourseAnnouncements - END - Course ID: $courseId');
  }

  /// Add a new announcement to a specific course
  Future<bool> addAnnouncementToCourse({
    required String courseId,
    required String title,
    required String content,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final newAnnouncement = await _courseService.createCourseAnnouncement(
        courseId: courseId,
        title: title,
        content: content,
      );
      _announcements.insert(0, newAnnouncement); // Add to the beginning for newest first
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add announcement: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update an existing announcement in a specific course
  Future<bool> updateAnnouncementInCourse({
    required String courseId,
    required String announcementId,
    String? title,
    String? content,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedAnnouncement = await _courseService.updateCourseAnnouncement(
        announcementId: announcementId,
        title: title,
        content: content,
      );
      final index = _announcements.indexWhere((a) => a.id == announcementId);
      if (index != -1) {
        _announcements[index] = updatedAnnouncement;
        // Re-sort to maintain order if needed, or just notify
        _announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update announcement: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Remove an announcement from a specific course
  Future<bool> removeAnnouncementFromCourse({
    required String courseId,
    required String announcementId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _courseService.deleteCourseAnnouncement(announcementId);
      _announcements.removeWhere((a) => a.id == announcementId);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to remove announcement: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }


  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error manually (for UI)
  void clearError() {
    _clearError();
    notifyListeners();
  }
}