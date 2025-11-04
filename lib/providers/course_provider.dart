import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/department.dart';
import '../services/pocketbase_service.dart';
import '../services/course_service.dart';

class CourseProvider extends ChangeNotifier {
  final PocketBaseService _pbService;
  late final CourseService _courseService;
  
  List<Course> _courses = [];
  Course? _selectedCourse;
  List<Department> _departments = [];
  bool _isLoading = false;
  String? _errorMessage;

  CourseProvider(this._pbService) {
    _courseService = CourseService(_pbService);
  }

  // Getters
  List<Course> get courses => _courses;
  Course? get selectedCourse => _selectedCourse;
  List<Department> get departments => _departments;
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
    _setLoading(true);
    _clearError();

    try {
      _selectedCourse = await _courseService.getCourse(courseId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load course: ${e.toString()}');
      _setLoading(false);
    }
  }

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