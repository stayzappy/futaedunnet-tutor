import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';
import '../models/school.dart';
import '../models/faculty.dart';
import '../models/department.dart';
import '../models/tutor.dart';
import '../models/course.dart';
import '../models/unit.dart';

class PocketBaseService {
  final PocketBase pb = PocketBaseConfig.pb;

  // ==================== Schools ====================
  
  /// Get all schools
  Future<List<School>> getSchools() async {
    try {
      final records = await pb.collection(PocketBaseConfig.schoolsCollection).getFullList(
        //sort: 'name',
      );
      return records.map((record) => School.fromJson(record.toJson())).toList();
    } catch (e) {
      throw Exception('Failed to fetch schools: $e');
    }
  }

  /// Get school by ID
  Future<School> getSchool(String id) async {
    try {
      final record = await pb.collection(PocketBaseConfig.schoolsCollection).getOne(id);
      return School.fromJson(record.toJson());
    } catch (e) {
      throw Exception('Failed to fetch school: $e');
    }
  }

  // ==================== Faculties ====================
  
  /// Get faculties by school ID
  Future<List<Faculty>> getFacultiesBySchool(String schoolId) async {
    try {
      final records = await pb.collection(PocketBaseConfig.facultiesCollection).getFullList(
        filter: 'school = "$schoolId"',
        // sort: 'name',
        // expand: 'school',
      );
      return records.map((record) => Faculty.fromJson(record.toJson())).toList();
    } catch (e) {
      throw Exception('Failed to fetch faculties: $e');
    }
  }

  /// Get faculty by ID
  Future<Faculty> getFaculty(String id) async {
    try {
      final record = await pb.collection(PocketBaseConfig.facultiesCollection).getOne(
        id,
        expand: 'school',
      );
      return Faculty.fromJson(record.toJson());
    } catch (e) {
      throw Exception('Failed to fetch faculty: $e');
    }
  }

  // ==================== Departments ====================
  
  /// Get departments by faculty ID
  Future<List<Department>> getDepartmentsByFaculty(String facultyId) async {
    try {
      final records = await pb.collection(PocketBaseConfig.departmentsCollection).getFullList(
        filter: 'faculty = "$facultyId"',
        // sort: 'name',
        // expand: 'faculty',
      );
      return records.map((record) => Department.fromJson(record.toJson())).toList();
    } catch (e) {
      throw Exception('Failed to fetch departments: $e');
    }
  }

  /// Get department by ID
  Future<Department> getDepartment(String id) async {
    try {
      final record = await pb.collection(PocketBaseConfig.departmentsCollection).getOne(
        id,
        expand: 'faculty',
      );
      return Department.fromJson(record.toJson());
    } catch (e) {
      throw Exception('Failed to fetch department: $e');
    }
  }

  // ==================== Tutors ====================
  
  /// Create tutor account (signup)
  Future<Tutor> createTutor({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? middleName,
    required String academicRank,
    required String schoolId,
    required String facultyId,
    String? departmentId,
    String? departmentManual,
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'firstName': firstName,
        'lastName': lastName,
        'middleName': middleName,
        'academicRank': academicRank,
        'school': schoolId,
        'faculty': facultyId,
        'department': departmentId,
        'departmentManual': departmentManual,
        'emailVisibility': 'true',
      };

      final record = await pb.collection(PocketBaseConfig.tutorsCollection).create(
        body: body,
      );
      
      return Tutor.fromJson(record.toJson());
    } catch (e) {
      print('Failed to create tutor account: $e');
      throw Exception('Failed to create tutor account: $e');
    }
  }

  /// Login tutor
  Future<Tutor> loginTutor(String email, String password) async {
    try {
      final authData = await pb.collection(PocketBaseConfig.tutorsCollection).authWithPassword(
        email,
        password,
      );
      
      return Tutor.fromJson(authData.record.toJson());
    } catch (e) {
      print('$e');
      throw Exception('Failed to login: $e');
    }
  }

  /// Get current tutor
  Future<Tutor?> getCurrentTutor() async {
    try {
      if (!pb.authStore.isValid) return null;
      
      final record = await pb.collection(PocketBaseConfig.tutorsCollection).getOne(
        pb.authStore.model.id,
        expand: 'school,faculty,department',
      );
      
      return Tutor.fromJson(record.toJson());
    } catch (e) {
      return null;
    }
  }

  /// Logout tutor
  void logoutTutor() {
    pb.authStore.clear();
  }

  // ==================== Courses ====================
  
  /// Get courses by tutor ID
  Future<List<Course>> getCoursesByTutor(String tutorId) async {
    try {
      final records = await pb.collection(PocketBaseConfig.coursesCollection).getFullList(
        filter: 'tutor = "$tutorId"',
        // sort: '-created',
        // expand: 'tutor,department',
      );
      return records.map((record) => Course.fromJson(record.toJson())).toList();
    } catch (e) {
      print('Failed to fetch courses: $e');
      throw Exception('Failed to fetch courses: $e');     
    }
  }

  /// Get course by ID
  Future<Course> getCourse(String id) async {
    try {
      final record = await pb.collection(PocketBaseConfig.coursesCollection).getOne(
        id,
        expand: 'tutor,department',
      );
      return Course.fromJson(record.toJson());
    } catch (e) {
      throw Exception('Failed to fetch course: $e');
    }
  }

  /// Create course
  Future<Course> createCourse({
  required String title,
  required String code,
  required String description,
  required String tutorId,
  required String departmentId,
  required String level,
  required String semester,
  String? displayPicture,
  bool isPublic = false,
}) async {
  try {
    // --- NEW: Check for duplicate code ---
    final existingRecords = await pb.collection(PocketBaseConfig.coursesCollection).getFullList(
      filter: 'code = "$code"', // Check for this specific code
      // Optionally, make it stricter: filter: 'code = "$code" && tutor = "$tutorId"'
    );
    if (existingRecords.isNotEmpty) {
      // A course with this code already exists
      throw Exception('A course with the code "$code" already exists.');
    }
    // --- END NEW ---

    final body = {
      'title': title,
      'code': code,
      'description': description,
      'tutor': tutorId,
      'department': departmentId,
      'level': level,
      'semester': semester,
      'displayPicture': displayPicture,
      'isPublic': isPublic,
    };
    final record = await pb.collection(PocketBaseConfig.coursesCollection).create(
      body: body,
      expand: 'tutor,department',
    );
    return Course.fromJson(record.toJson());
  } catch (e) {
    if (e is Exception) { // Let the specific duplicate error through
      rethrow;
    }
    // Handle other potential errors from create()
    throw Exception('Failed to create course: $e');
  }
}

  /// Update course
  Future<Course> updateCourse(String id, Map<String, dynamic> data) async {
    try {
      final record = await pb.collection(PocketBaseConfig.coursesCollection).update(
        id,
        body: data,
        expand: 'tutor,department',
      );
      
      return Course.fromJson(record.toJson());
    } catch (e) {
      debugPrint('$e');
      print('$e');
      throw Exception('Failed to update course: $e');
    }
  }

  /// Delete course
  Future<void> deleteCourse(String id) async {
    try {
      await pb.collection(PocketBaseConfig.coursesCollection).delete(id);
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }

  // ==================== Units ====================
  
  /// Get units by course ID
  Future<List<Unit>> getUnitsByCourse(String courseId) async {
    try {
      final records = await pb.collection(PocketBaseConfig.unitsCollection).getFullList(
        filter: 'course = "$courseId"',
        sort: 'order',
        expand: 'course',
      );
      return records.map((record) => Unit.fromJson(record.toJson())).toList();
    } catch (e) {
      throw Exception('Failed to fetch units: $e');
    }
  }

  /// Get unit by ID
  Future<Unit> getUnit(String id) async {
    try {
      final record = await pb.collection(PocketBaseConfig.unitsCollection).getOne(
        id,
        expand: 'course',
      );
      return Unit.fromJson(record.toJson());
    } catch (e) {
      throw Exception('Failed to fetch unit: $e');
    }
  }

  /// Create unit
  Future<Unit> createUnit({
  required String title,
  required String content,
  required String courseId,
  required double order,
  String? video,
}) async {
  try {
    // --- NEW: Check for duplicate title within the same course ---
    final existingRecords = await pb.collection(PocketBaseConfig.unitsCollection).getFullList(
      filter: 'course = "$courseId" && title = "$title"', // Check within this course for this title
    );
    if (existingRecords.isNotEmpty) {
      // A unit with this title already exists in this course
      throw Exception('A unit with the title "$title" already exists in this course.');
    }
    // --- END NEW ---

    final body = {
      'title': title,
      'content': content,
      'course': courseId,
      'order': order,
      'video': video,
    };
    final record = await pb.collection(PocketBaseConfig.unitsCollection).create(
      body: body,
      expand: 'course',
    );
    return Unit.fromJson(record.toJson());
  } catch (e) {
    if (e is Exception) { // Let the specific duplicate error through
      rethrow;
    }
    // Handle other potential errors from create()
    throw Exception('Failed to create unit: $e');
  }
}

  /// Update unit
  Future<Unit> updateUnit(String id, Map<String, dynamic> data) async {
    try {
      final record = await pb.collection(PocketBaseConfig.unitsCollection).update(
        id,
        body: data,
        expand: 'course',
      );
      
      return Unit.fromJson(record.toJson());
    } catch (e) {
      print('$e');
      debugPrint('$e');
      throw Exception('Failed to update unit: $e');
    }
  }

  /// Delete unit
  Future<void> deleteUnit(String id) async {
    try {
      await pb.collection(PocketBaseConfig.unitsCollection).delete(id);
    } catch (e) {
      throw Exception('Failed to delete unit: $e');
    }
  }

  // ==================== File Upload ====================
  
     Future<String> uploadFile(String collection, String recordId, String fieldName, List<int> fileBytes, String fileName) async {
    try {
      print('DEBUG: Starting uploadFile for collection: $collection, record: $recordId, field: $fieldName');
      print('DEBUG: File name: $fileName, File size: ${fileBytes.length} bytes');

      // Create the http.MultipartFile
      final multipartFile = http.MultipartFile.fromBytes(
        fieldName, // The field name in your collection
        fileBytes, // The actual file bytes
        filename: fileName, // The original filename
      );

      // Prepare the body map (usually just contains non-file fields you want to update)
      // For a pure file upload to an existing record, this might often be empty
      // or contain other fields you wish to update simultaneously.
      // If updating only the file, you could potentially pass an empty map {},
      // but often passing the fieldName with a placeholder or omitting it if not updating other fields is fine.
      // Let's pass an empty map for clarity if only updating the file.
      final body = <String, dynamic>{};

      print('DEBUG: Prepared body: $body');
      print('DEBUG: Prepared files: [${multipartFile.field} - ${multipartFile.filename} (${multipartFile.length} bytes)]');

      // Use pb.collection.update with the 'files' parameter
      final record = await pb.collection(collection).update(
        recordId,
        body: body, // Non-file fields to update (can be empty {})
        files: [multipartFile], // The file(s) to upload
      );

      print('DEBUG: Upload successful, raw record response: ${record.toJson()}');

      // Extract the updated filename from the response
      final storedFileName = record.toJson()[fieldName] as String?;
      if (storedFileName == null) {
         print('DEBUG: WARNING - File upload succeeded but field "$fieldName" not found or null in response record.');
         // Depending on your needs, you might want to throw an exception here
         // throw Exception('File upload succeeded but field "$fieldName" not found in response record.');
      } else {
         print('DEBUG: Successfully uploaded file, stored name: $storedFileName');
      }
      return storedFileName ?? ''; // Return empty string or handle null case as needed
    } on ClientException catch (e) {
      // Handle PocketBase specific client errors (like 400)
      print('ERROR in uploadFile - ClientException: ${e.toString()}');
      print('ERROR Response Body: ${e.response}');
      // Try to parse the detailed error message from the response
      final errorData = e.response?['data'] as Map<String, dynamic>?;
      if (errorData != null) {
          final fieldErrors = errorData[fieldName] as Map<String, dynamic>?; // e.g., error for 'video' or 'displayPicture'
          if (fieldErrors != null) {
              final errorMessage = fieldErrors['message'] as String?;
              final errorCode = fieldErrors['code'] as String?;
              print('ERROR Field ($fieldName) - Code: $errorCode, Message: $errorMessage');
              // Throw a more specific error based on the PB response
              throw Exception('File Upload Failed (${errorCode}): $errorMessage');
          }
      }
      // If the specific field error wasn't found, re-throw the general one
      rethrow;
    } catch (e) {
      // Catch any other errors
      print('ERROR in uploadFile - General: $e');
      rethrow; // Re-throw the exception so the calling service layer can catch it
    }
  }
}