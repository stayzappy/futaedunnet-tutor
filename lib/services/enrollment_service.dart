import '../models/enrollment.dart';
import 'pocketbase_service.dart';
import '../config/pocketbase_config.dart';

class EnrollmentService {
  final PocketBaseService _pbService;

  EnrollmentService(this._pbService);

  /// Get all enrollments for courses taught by a specific tutor
  Future<List<Enrollment>> getEnrollmentsByTutor(String tutorId) async {
    try {
      // First, get all courses by the tutor
      final courses = await _pbService.getCoursesByTutor(tutorId);
      final courseIds = courses.map((c) => c.id).toList();

      if (courseIds.isEmpty) {
        return [];
      }

      // Build filter for all courses
      final filters = courseIds.map((id) => 'course = "$id"').join(' || ');

      final records = await _pbService.pb
          .collection(PocketBaseConfig.enrollmentsCollection)
          .getFullList(
            filter: filters,
            sort: '-enrolledAt',
            expand: 'student,course',
          );

      return records.map((record) => Enrollment.fromJson(record.toJson())).toList();
    } catch (e) {
      throw Exception('Failed to fetch enrollments: $e');
    }
  }

  /// Get enrollments for a specific course
  Future<List<Enrollment>> getEnrollmentsByCourse(String courseId) async {
    try {
      final records = await _pbService.pb
          .collection(PocketBaseConfig.enrollmentsCollection)
          .getFullList(
            filter: 'course = "$courseId"',
            sort: '-enrolledAt',
            expand: 'student,course',
          );

      return records.map((record) => Enrollment.fromJson(record.toJson())).toList();
    } catch (e) {
      throw Exception('Failed to fetch course enrollments: $e');
    }
  }

  /// Get enrollment by ID
  Future<Enrollment> getEnrollment(String id) async {
    try {
      final record = await _pbService.pb
          .collection(PocketBaseConfig.enrollmentsCollection)
          .getOne(
            id,
            expand: 'student,course',
          );

      return Enrollment.fromJson(record.toJson());
    } catch (e) {
      throw Exception('Failed to fetch enrollment: $e');
    }
  }

  /// Get enrollment count for a course
  Future<int> getEnrollmentCount(String courseId) async {
    try {
      final enrollments = await getEnrollmentsByCourse(courseId);
      return enrollments.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get total enrollment count for all tutor's courses
  Future<int> getTotalEnrollmentCount(String tutorId) async {
    try {
      final enrollments = await getEnrollmentsByTutor(tutorId);
      return enrollments.length;
    } catch (e) {
      return 0;
    }
  }

  /// Disenroll a student from a course
  Future<void> disenrollStudent(String enrollmentId) async {
    try {
      await _pbService.pb
          .collection(PocketBaseConfig.enrollmentsCollection)
          .delete(enrollmentId);
    } catch (e) {
      throw Exception('Failed to disenroll student: $e');
    }
  }

  /// Check if a student is enrolled in a course
  Future<bool> isStudentEnrolled(String studentId, String courseId) async {
    try {
      final records = await _pbService.pb
          .collection(PocketBaseConfig.enrollmentsCollection)
          .getFullList(
            filter: 'student = "$studentId" && course = "$courseId"',
          );

      return records.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get enrollments with pagination
  Future<Map<String, dynamic>> getEnrollmentsPaginated({
    required String tutorId,
    int page = 1,
    int perPage = 20,
    String? searchQuery,
    String? courseFilter,
    String sortBy = '-enrolledAt',
  }) async {
    try {
      // Get all courses by the tutor
      final courses = await _pbService.getCoursesByTutor(tutorId);
      final courseIds = courses.map((c) => c.id).toList();

      if (courseIds.isEmpty) {
        return {
          'items': <Enrollment>[],
          'page': page,
          'perPage': perPage,
          'totalItems': 0,
          'totalPages': 0,
        };
      }

      // Build filter
      final courseFilters = courseIds.map((id) => 'course = "$id"').join(' || ');
      String filter = '($courseFilters)';

      // Add course-specific filter
      if (courseFilter != null && courseFilter.isNotEmpty) {
        filter += ' && course = "$courseFilter"';
      }

      // Add search filter for student names or matric number
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final search = searchQuery.toLowerCase();
        filter += ' && (student.firstName ~ "$search" || student.lastName ~ "$search" || student.matricNumber ~ "$search")';
      }

      final result = await _pbService.pb
          .collection(PocketBaseConfig.enrollmentsCollection)
          .getList(
            page: page,
            perPage: perPage,
            filter: filter,
            sort: sortBy,
            expand: 'student,course',
          );

      return {
        'items': result.items.map((record) => Enrollment.fromJson(record.toJson())).toList(),
        'page': result.page,
        'perPage': result.perPage,
        'totalItems': result.totalItems,
        'totalPages': result.totalPages,
      };
    } catch (e) {
      throw Exception('Failed to fetch paginated enrollments: $e');
    }
  }

  /// Get enrollment statistics for a tutor
  Future<Map<String, dynamic>> getEnrollmentStats(String tutorId) async {
    try {
      final enrollments = await getEnrollmentsByTutor(tutorId);
      final courses = await _pbService.getCoursesByTutor(tutorId);

      // Count enrollments per course
      final Map<String, int> enrollmentsPerCourse = {};
      final Map<String, String> courseTitles = {};

      for (var course in courses) {
        enrollmentsPerCourse[course.id] = 0;
        courseTitles[course.id] = course.title;
      }

      for (var enrollment in enrollments) {
        if (enrollmentsPerCourse.containsKey(enrollment.course)) {
          enrollmentsPerCourse[enrollment.course] = 
              (enrollmentsPerCourse[enrollment.course] ?? 0) + 1;
        }
      }

      // Find most enrolled course
      String? mostEnrolledCourseId;
      int maxEnrollments = 0;

      enrollmentsPerCourse.forEach((courseId, count) {
        if (count > maxEnrollments) {
          maxEnrollments = count;
          mostEnrolledCourseId = courseId;
        }
      });

      // Get recent enrollments (last 7 days)
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final recentEnrollments = enrollments
          .where((e) => e.enrolledAt.isAfter(sevenDaysAgo))
          .length;

      return {
        'totalEnrollments': enrollments.length,
        'totalCourses': courses.length,
        'averageEnrollmentsPerCourse': courses.isEmpty 
            ? 0.0 
            : enrollments.length / courses.length,
        'mostEnrolledCourseId': mostEnrolledCourseId,
        'mostEnrolledCourseTitle': mostEnrolledCourseId != null 
            ? courseTitles[mostEnrolledCourseId] 
            : null,
        'maxEnrollments': maxEnrollments,
        'recentEnrollments': recentEnrollments,
        'enrollmentsPerCourse': enrollmentsPerCourse,
        'courseTitles': courseTitles,
      };
    } catch (e) {
      throw Exception('Failed to get enrollment stats: $e');
    }
  }

  /// Get students who completed a course (all units)
  Future<List<Enrollment>> getCompletedEnrollments(String courseId) async {
    try {
      // Get all units for the course
      final units = await _pbService.getUnitsByCourse(courseId);
      final totalUnits = units.length;

      if (totalUnits == 0) {
        return [];
      }

      // Get all enrollments for the course
      final enrollments = await getEnrollmentsByCourse(courseId);
      final completedEnrollments = <Enrollment>[];

      // Check each student's progress
      for (var enrollment in enrollments) {
        final progress = await _pbService.pb
            .collection(PocketBaseConfig.progressCollection)
            .getFullList(
              filter: 'student = "${enrollment.student}" && unit.course = "$courseId" && completed = true',
            );

        // If student completed all units
        if (progress.length >= totalUnits) {
          completedEnrollments.add(enrollment);
        }
      }

      return completedEnrollments;
    } catch (e) {
      throw Exception('Failed to get completed enrollments: $e');
    }
  }

  /// Get students who are still studying (not completed all units)
  Future<List<Enrollment>> getOngoingEnrollments(String courseId) async {
    try {
      final allEnrollments = await getEnrollmentsByCourse(courseId);
      final completedEnrollments = await getCompletedEnrollments(courseId);
      
      final completedIds = completedEnrollments.map((e) => e.id).toSet();
      
      return allEnrollments
          .where((e) => !completedIds.contains(e.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get ongoing enrollments: $e');
    }
  }

  /// Get student progress percentage for a course
  Future<double> getStudentProgress(String studentId, String courseId) async {
    try {
      final units = await _pbService.getUnitsByCourse(courseId);
      final totalUnits = units.length;

      if (totalUnits == 0) {
        return 0.0;
      }

      final progress = await _pbService.pb
          .collection(PocketBaseConfig.progressCollection)
          .getFullList(
            filter: 'student = "$studentId" && unit.course = "$courseId" && completed = true',
          );

      return (progress.length / totalUnits) * 100;
    } catch (e) {
      return 0.0;
    }
  }
}