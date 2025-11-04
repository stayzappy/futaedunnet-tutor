import 'dart:convert'; // Add this import for jsonEncode/jsonDecode
import 'package:pocketbase/pocketbase.dart'; // Add this import for RecordModel
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tutor.dart';
import 'pocketbase_service.dart'; // Ensure PocketBaseService is correctly imported
import '../utils/text_helper.dart';

class AuthService {
  final PocketBaseService _pbService;
  static const String _tutorIdKey = 'tutor_id';
  // --- Add these constants for storing token and model ---
  static const String _authTokenKey = 'auth_token';
  static const String _authModelKey = 'auth_model';
  // ---
  // Add a flag to track if loading from storage has completed
  bool _storageLoaded = false;

  AuthService(this._pbService) {
    // --- Don't call _loadAuthFromStorage directly in constructor anymore ---
    // _loadAuthFromStorage(); // Remove this line
  }

  // --- Add an explicit initialization method ---
  Future<void> initialize() async {
    await _loadAuthFromStorage();
    _storageLoaded = true; // Mark loading as complete
  }

  // --- Add a method to check if initialization is complete ---
  bool get isInitialized => _storageLoaded;
  // ---

  // ... rest of your existing methods remain the same ...

  /// Sign up a new tutor
  Future<Tutor> signup({
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
    // Validate passwords match
    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }
    // Sanitize input data
    final sanitizedEmail = TextHelper.sanitizeEmail(email);
    final sanitizedFirstName = TextHelper.sanitizeName(firstName);
    final sanitizedLastName = TextHelper.sanitizeName(lastName);
    final sanitizedMiddleName = middleName != null && middleName.isNotEmpty
        ? TextHelper.sanitizeName(middleName)
        : null;
    final sanitizedDepartmentManual = departmentManual != null && departmentManual.isNotEmpty
        ? TextHelper.sanitizeInstitutionName(departmentManual)
        : null;
    try {
      final tutor = await _pbService.createTutor(
        email: sanitizedEmail,
        password: password,
        firstName: sanitizedFirstName,
        lastName: sanitizedLastName,
        middleName: sanitizedMiddleName,
        academicRank: academicRank,
        schoolId: schoolId,
        facultyId: facultyId,
        departmentId: departmentId,
        departmentManual: sanitizedDepartmentManual,
      );
      // Save tutor ID to local storage
      await _saveTutorId(tutor.id);
      // --- Save the new auth token and model after signup ---
      await _saveAuthToStorage();
      // ---
      return tutor;
    } catch (e) {
      throw Exception('Signup failed: ${e.toString()}');
    }
  }

  /// Login tutor
  Future<Tutor> login({
    required String email,
    required String password,
  }) async {
    // Sanitize email
    final sanitizedEmail = TextHelper.sanitizeEmail(email);
    try {
      final tutor = await _pbService.loginTutor(sanitizedEmail, password);
      // Save tutor ID to local storage
      await _saveTutorId(tutor.id);
      // --- Save the new auth token and model after login ---
      await _saveAuthToStorage();
      // ---
      return tutor;
    } catch (e) {
      print('$e');
      throw Exception('Login failed: Invalid email or password');
    }
  }

  /// Logout tutor
  Future<void> logout() async {
    try {
      _pbService.logoutTutor();
      await _clearTutorId();
      // --- Clear the stored token and model during logout ---
      await _clearAuthStorage();
      // ---
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  /// Get current logged-in tutor
  Future<Tutor?> getCurrentTutor() async {
    // Check if AuthService is initialized (storage loaded)
    if (!_storageLoaded) {
      print('AuthService: Warning - getCurrentTutor called before initialization.');
      return null; // Or potentially await initialize() here if needed, but better to ensure init happens first.
    }

    try {
      // This call relies on the PocketBase client's authStore being valid
      // which should have been restored from storage by the AuthService.initialize() method.
      print('AuthService: Attempting to get current tutor. pb.authStore.isValid: ${_pbService.pb.authStore.isValid}');
      if (_pbService.pb.authStore.isValid) {
         final record = await _pbService.pb.collection('tutors').getOne(
           _pbService.pb.authStore.model!.id,
           expand: 'school,faculty,department', // Adjust expand if needed
         );
         print('AuthService: Retrieved current tutor from server: ${record.id}');
         return Tutor.fromJson(record.toJson());
      } else {
         print('AuthService: pb.authStore is not valid, returning null.');
         return null;
      }
    } catch (e) {
      print('AuthService: Error getting current tutor: $e');
      // If fetching the record fails (e.g., token expired), clear local storage
      await _clearAuthStorage();
      return null;
    }
  }

  /// Check if tutor is authenticated
  Future<bool> isAuthenticated() async {
    // This now relies on the PocketBase client's authStore being correctly initialized
    // either from a previous session (via _loadAuthFromStorage) or a fresh login.
    // It checks if the stored token/model is valid AND fetches the user data.
    // Ensure initialization is done first
    if (!_storageLoaded) {
        print('AuthService: Warning - isAuthenticated called before initialization.');
        return false;
    }

    try {
      final tutor = await getCurrentTutor();
      final isAuthenticated = tutor != null;
      print('AuthService: isAuthenticated check result: $isAuthenticated');
      return isAuthenticated;
    } catch (e) {
      print('AuthService: Error checking auth status: $e');
      return false;
    }
  }

  /// Save tutor ID to local storage (might still be useful for other purposes)
  Future<void> _saveTutorId(String tutorId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tutorIdKey, tutorId);
    } catch (e) {
      // Silently fail - not critical if only used for persistence alongside token
    }
  }

  /// Clear tutor ID from local storage (might still be useful for other purposes)
  Future<void> _clearTutorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tutorIdKey);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Get saved tutor ID from local storage (might still be useful for other purposes)
  Future<String?> _getSavedTutorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tutorIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Refresh authentication token (useful for extending session)
  Future<void> refreshAuth() async {
    try {
      await _pbService.pb.collection('tutors').authRefresh();
      // After refresh, the token/model in the PocketBase service might change, save it again
      await _saveAuthToStorage();
    } catch (e) {
      throw Exception('Failed to refresh authentication');
    }
  }

  // --- Add helper methods for saving/loading/clearing auth token/model ---
  Future<void> _saveAuthToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authStore = _pbService.pb.authStore; // Access the auth store directly

      print('AuthService: Attempting to save auth to storage. pb.authStore.isValid: ${authStore.isValid}');

      if (authStore.isValid) {
        await prefs.setString(_authTokenKey, authStore.token);
        // Assuming the model is a RecordModel, convert it to JSON string
        if (authStore.model != null) {
          final modelData = jsonEncode(authStore.model!.toJson());
          await prefs.setString(_authModelKey, modelData);
          print('AuthService: Authentication token and model SAVED to storage.');
          print('AuthService: Token saved for tutor ID: ${authStore.model!.id}');
        } else {
           // If model is null, remove it to avoid loading inconsistencies
          await prefs.remove(_authModelKey);
          print('AuthService: Auth model was null, removed from storage.');
        }
      } else {
        // If not valid, clear stored data
        await _clearAuthStorage();
        print('AuthService: AuthStore not valid, cleared storage.');
      }
    } catch (e) {
      print('AuthService: Error saving tutor auth to storage: $e');
    }
  }

  Future<void> _clearAuthStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authTokenKey);
      await prefs.remove(_authModelKey);
      print('AuthService: Authentication token and model CLEARED from storage.');
    } catch (e) {
      print('AuthService: Error clearing tutor auth from storage: $e');
    }
  }

  Future<void> _loadAuthFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      final modelData = prefs.getString(_authModelKey);

      print('AuthService: Attempting to load auth from storage...');
      print('AuthService: Token found: ${token != null}');
      print('AuthService: Model data found: ${modelData != null}');

      if (token != null && modelData != null) {
        // Attempt to load the stored token and model into the PocketBase service's auth store
        final modelMap = Map<String, dynamic>.from(
          (jsonDecode(modelData) as Map).cast<String, dynamic>()
        );
        // Create a RecordModel from the parsed data
        final recordModel = RecordModel(modelMap);
        _pbService.pb.authStore.save(token, recordModel); // Directly use the pb instance from _pbService
        print('AuthService: Authentication loaded from storage for tutor ID: ${recordModel.id}');
        print('AuthService: pb.authStore.isValid after load: ${_pbService.pb.authStore.isValid}');
      } else {
        print('AuthService: No stored tutor authentication found in SharedPreferences.');
      }
    } catch (e) {
      print('AuthService: Error loading tutor auth from storage: $e');
      // If loading fails, the PocketBase service will remain unauthenticated,
      // and getCurrentTutor/isAuthenticated will return null/false as expected.
    }
  }
  // ---
}