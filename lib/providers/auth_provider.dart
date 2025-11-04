import 'package:flutter/material.dart';
import '../models/tutor.dart';
import '../services/pocketbase_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final PocketBaseService _pbService;
  late final AuthService _authService;

  Tutor? _currentTutor;
  bool _isLoading = false;
  // NEW: Loading state specifically for the initial auth check upon provider creation/loading
  bool _isLoadingAuthStatus = true;
  String? _errorMessage;

  AuthProvider(this._pbService) {
    // Initialize AuthService first
    _authService = AuthService(_pbService);
    // Immediately start the initialization process for AuthService
    _initializeAuthServiceAndAuth(); // Call the new combined method
  }

  // Getters
  Tutor? get currentTutor => _currentTutor;
  bool get isLoading => _isLoading;
  // NEW: Getter for the initial auth loading state
  bool get isLoadingAuthStatus => _isLoadingAuthStatus;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentTutor != null;

  /// Initialize AuthService (loading from storage) and then check auth status
  Future<void> _initializeAuthServiceAndAuth() async {
    // Ensure AuthService is initialized (loads from storage)
    await _authService.initialize();

    // Now proceed with checking the current auth status using the initialized AuthService
    await _initializeAuth();
  }

  /// Initialize authentication status check after AuthService is ready
  Future<void> _initializeAuth() async {
    try {
      // NEW: Set the specific loading state for initial auth check
      _isLoadingAuthStatus = true;
      notifyListeners(); // Notify listeners that initial auth check is starting

      // This call will now correctly use the AuthService which has loaded from storage
      _currentTutor = await _authService.getCurrentTutor();
      print('AuthProvider: Initial auth check complete. Current tutor: ${_currentTutor?.id}');
    } catch (e) {
      print('AuthProvider: Error during initial auth check: $e');
      _currentTutor = null; // Ensure it's null on error
    } finally {
      // NEW: Always clear the specific loading state for initial auth check
      _isLoadingAuthStatus = false;
      notifyListeners(); // Notify listeners that initial auth check is done
    }
  }

  /// Sign up a new tutor
  Future<bool> signup({
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    String? middleName,
    required String academicRank,
    required String schoolId,
    required String facultyId,
    String? departmentId,
    String? departmentManual,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final tutor = await _authService.signup(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
        academicRank: academicRank,
        schoolId: schoolId,
        facultyId: facultyId,
        departmentId: departmentId,
        departmentManual: departmentManual,
      );
      _currentTutor = tutor;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Login tutor
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final tutor = await _authService.login(
        email: email,
        password: password,
      );
      _currentTutor = tutor;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Invalid email or password. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Logout tutor
  Future<void> logout() async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.logout();
      _currentTutor = null;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Refresh current tutor data
  Future<void> refreshCurrentTutor() async {
    try {
      _currentTutor = await _authService.getCurrentTutor();
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh user data');
    }
  }

  /// Check authentication status
  Future<bool> checkAuthStatus() async {
    try {
      return await _authService.isAuthenticated();
    } catch (e) {
      return false;
    }
  }

  /// Set loading state for actions like login/signup/logout
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
    notifyListeners();
  }

  /// Clear error manually (for UI)
  void clearError() {
    _clearError();
    notifyListeners();
  }
}