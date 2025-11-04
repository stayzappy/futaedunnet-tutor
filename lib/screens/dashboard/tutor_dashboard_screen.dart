// lib/screens/tutor/dashboard/tutor_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../utils/constants.dart'; // Assuming this file exists and is needed
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart'; // Assuming this file exists and is needed
import '../../widgets/responsive_builder.dart';
import '../course/create_course_screen.dart';
import '../course/course_detail_screen.dart';
import '../enrollments/enrollments_screen.dart';
import 'widgets/course_card.dart';
import 'widgets/empty_courses_widget.dart';

class TutorDashboardScreen extends StatefulWidget {
  const TutorDashboardScreen({super.key});

  @override
  State<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends State<TutorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourses();
    });
  }

  Future<void> _loadCourses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    if (authProvider.currentTutor != null) { // Check if tutor is loaded
      await courseProvider.loadCourses(authProvider.currentTutor!.id);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _navigateToCreateCourse() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateCourseScreen()),
    ).then((_) => _loadCourses());
  }

  void _navigateToCourseDetail(String courseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailScreen(courseId: courseId),
      ),
    ).then((_) => _loadCourses());
  }

  void _navigateToEnrollments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EnrollmentsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);

    // NEW: Check the specific loading state for initial auth status from AuthProvider
    if (authProvider.isLoadingAuthStatus) { // Assuming you added this getter in AuthProvider
      return const Scaffold(
        body: Center(child: LoadingWidget(message: 'Checking authentication...')),
      );
    }

    // Now, check if the tutor is available (loaded from storage or current session)
    final tutor = authProvider.currentTutor;
    if (tutor == null) {
      // If auth is loaded but no tutor, user is not logged in or token is invalid/expired
      return const Scaffold(
        body: Center(child: LoadingWidget(message: 'Please log in.')), // Or redirect logic
      );
    }

    // Build the main dashboard UI for the authenticated tutor
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${tutor.fullNameWithRank}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: _navigateToEnrollments,
            tooltip: 'Enrollments',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourses,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateCourse,
        icon: const Icon(Icons.add),
        label: const Text('New Course'),
        backgroundColor: AppTheme.primaryBlue,
      )
          .animate()
          .fadeIn(delay: 800.ms, duration: 400.ms)
          .scale(begin: const Offset(0, 0), end: const Offset(1, 1)),
      body: RefreshIndicator(
        onRefresh: _loadCourses,
        child: ResponsivePadding(
          child: courseProvider.isLoading
              ? const LoadingWidget(message: 'Loading your courses...')
              : courseProvider.hasCourses
                  ? _buildCoursesList(courseProvider)
                  : EmptyCoursesWidget(
                      onCreateCourse: _navigateToCreateCourse,
                    ),
        ),
      ),
    );
  }

  Widget _buildCoursesList(CourseProvider courseProvider) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Courses',
                      style: Theme.of(context).textTheme.headlineMedium,
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideX(begin: -0.2, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      '${courseProvider.courseCount} ${courseProvider.courseCount == 1 ? "course" : "courses"} available',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideX(begin: -0.2, end: 0),
                  ],
                ),
              ),
            ),
            _buildCoursesGrid(courseProvider, deviceType),
          ],
        );
      },
    );
  }

  Widget _buildCoursesGrid(CourseProvider courseProvider, DeviceType deviceType) {
    int crossAxisCount;
    switch (deviceType) {
      case DeviceType.mobile:
        crossAxisCount = 1;
        break;
      case DeviceType.tablet:
        crossAxisCount = 2;
        break;
      case DeviceType.desktop:
        crossAxisCount = 3;
        break;
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 80),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: deviceType == DeviceType.mobile ? 1.3 : 1.1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final course = courseProvider.courses[index];
            return CourseCard(
              course: course,
              onTap: () => _navigateToCourseDetail(course.id),
            )
                .animate()
                .fadeIn(delay: (100 * index).ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0);
          },
          childCount: courseProvider.courses.length,
        ),
      ),
    );
  }
}