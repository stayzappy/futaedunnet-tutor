import 'package:flutter/material.dart';
import '../models/enrollment.dart';
import '../services/pocketbase_service.dart';
import '../services/enrollment_service.dart';

class EnrollmentProvider extends ChangeNotifier {
  final PocketBaseService _pbService;
  late final EnrollmentService _enrollmentService;
  
  List<Enrollment> _enrollments = [];
  List<Enrollment> _filteredEnrollments = [];
  Map<String, dynamic> _stats = {};
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Pagination
  int _currentPage = 1;
  int _perPage = 20;
  int _totalItems = 0;
  int _totalPages = 0;
  
  // Filters
  String _searchQuery = '';
  String? _courseFilter;
  String _sortBy = '-enrolledAt';
  String _completionFilter = 'all'; // 'all', 'completed', 'ongoing'

  EnrollmentProvider(this._pbService) {
    _enrollmentService = EnrollmentService(_pbService);
  }

  // Getters
  List<Enrollment> get enrollments => _filteredEnrollments;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalItems => _totalItems;
  int get totalPages => _totalPages;
  bool get hasEnrollments => _filteredEnrollments.isNotEmpty;
  String get searchQuery => _searchQuery;
  String? get courseFilter => _courseFilter;
  String get sortBy => _sortBy;
  String get completionFilter => _completionFilter;

  /// Load all enrollments for a tutor
  Future<void> loadEnrollments(String tutorId) async {
    _setLoading(true);
    _clearError();

    try {
      _enrollments = await _enrollmentService.getEnrollmentsByTutor(tutorId);
      _filteredEnrollments = List.from(_enrollments);
      _applyFilters();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load enrollments: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Load enrollments for a specific course
  Future<void> loadCourseEnrollments(String courseId) async {
    _setLoading(true);
    _clearError();

    try {
      _enrollments = await _enrollmentService.getEnrollmentsByCourse(courseId);
      _filteredEnrollments = List.from(_enrollments);
      _applyFilters();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load course enrollments: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Load enrollments with pagination
  Future<void> loadEnrollmentsPaginated(String tutorId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _enrollmentService.getEnrollmentsPaginated(
        tutorId: tutorId,
        page: _currentPage,
        perPage: _perPage,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        courseFilter: _courseFilter,
        sortBy: _sortBy,
      );

      _filteredEnrollments = result['items'] as List<Enrollment>;
      _currentPage = result['page'] as int;
      _perPage = result['perPage'] as int;
      _totalItems = result['totalItems'] as int;
      _totalPages = result['totalPages'] as int;

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load enrollments: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Load enrollment statistics
  Future<void> loadStats(String tutorId) async {
    _clearError();

    try {
      _stats = await _enrollmentService.getEnrollmentStats(tutorId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load statistics: ${e.toString()}');
    }
  }

  /// Disenroll a student
  Future<bool> disenrollStudent(String enrollmentId, String tutorId) async {
    _setLoading(true);
    _clearError();

    try {
      await _enrollmentService.disenrollStudent(enrollmentId);
      
      // Remove from local list
      _enrollments.removeWhere((e) => e.id == enrollmentId);
      _filteredEnrollments.removeWhere((e) => e.id == enrollmentId);
      
      // Reload stats
      await loadStats(tutorId);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to disenroll student: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Set search query and filter
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Set course filter
  void setCourseFilter(String? courseId) {
    _courseFilter = courseId;
    _applyFilters();
    notifyListeners();
  }

  /// Set sort order
  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _applySort();
    notifyListeners();
  }

  /// Set completion filter
  void setCompletionFilter(String filter) {
    _completionFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _courseFilter = null;
    _sortBy = '-enrolledAt';
    _completionFilter = 'all';
    _filteredEnrollments = List.from(_enrollments);
    notifyListeners();
  }

  /// Apply filters to enrollment list
  void _applyFilters() {
    _filteredEnrollments = List.from(_enrollments);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      _filteredEnrollments = _filteredEnrollments.where((enrollment) {
        final student = enrollment.studentInfo;
        if (student == null) return false;
        
        return student.fullName.toLowerCase().contains(query) ||
            student.matricNumber.toLowerCase().contains(query) ||
            student.email.toLowerCase().contains(query);
      }).toList();
    }

    // Apply course filter
    if (_courseFilter != null) {
      _filteredEnrollments = _filteredEnrollments
          .where((e) => e.course == _courseFilter)
          .toList();
    }

    // Apply completion filter (this is simplified - in real app, check progress)
    // For now, we'll just keep all since we need to query progress separately
    
    _applySort();
  }

  /// Apply sorting
  void _applySort() {
    switch (_sortBy) {
      case 'enrolledAt':
        _filteredEnrollments.sort((a, b) => a.enrolledAt.compareTo(b.enrolledAt));
        break;
      case '-enrolledAt':
        _filteredEnrollments.sort((a, b) => b.enrolledAt.compareTo(a.enrolledAt));
        break;
      case 'name':
        _filteredEnrollments.sort((a, b) {
          final nameA = a.studentInfo?.fullName ?? '';
          final nameB = b.studentInfo?.fullName ?? '';
          return nameA.compareTo(nameB);
        });
        break;
      case '-name':
        _filteredEnrollments.sort((a, b) {
          final nameA = a.studentInfo?.fullName ?? '';
          final nameB = b.studentInfo?.fullName ?? '';
          return nameB.compareTo(nameA);
        });
        break;
      case 'matricNumber':
        _filteredEnrollments.sort((a, b) {
          final matricA = a.studentInfo?.matricNumber ?? '';
          final matricB = b.studentInfo?.matricNumber ?? '';
          return matricA.compareTo(matricB);
        });
        break;
      default:
        break;
    }
  }

  /// Get enrollment count for a course
  Future<int> getEnrollmentCount(String courseId) async {
    try {
      return await _enrollmentService.getEnrollmentCount(courseId);
    } catch (e) {
      return 0;
    }
  }

  /// Get completed enrollments for a course
  Future<List<Enrollment>> getCompletedEnrollments(String courseId) async {
    try {
      return await _enrollmentService.getCompletedEnrollments(courseId);
    } catch (e) {
      return [];
    }
  }

  /// Get ongoing enrollments for a course
  Future<List<Enrollment>> getOngoingEnrollments(String courseId) async {
    try {
      return await _enrollmentService.getOngoingEnrollments(courseId);
    } catch (e) {
      return [];
    }
  }

  /// Get student progress percentage
  Future<double> getStudentProgress(String studentId, String courseId) async {
    try {
      return await _enrollmentService.getStudentProgress(studentId, courseId);
    } catch (e) {
      return 0.0;
    }
  }

  /// Go to next page
  void nextPage(String tutorId) {
    if (_currentPage < _totalPages) {
      _currentPage++;
      loadEnrollmentsPaginated(tutorId);
    }
  }

  /// Go to previous page
  void previousPage(String tutorId) {
    if (_currentPage > 1) {
      _currentPage--;
      loadEnrollmentsPaginated(tutorId);
    }
  }

  /// Refresh enrollments
  Future<void> refreshEnrollments(String tutorId) async {
    _currentPage = 1;
    await loadEnrollmentsPaginated(tutorId);
    await loadStats(tutorId);
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