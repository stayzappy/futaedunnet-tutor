import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/course_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/responsive_builder.dart';
import 'widgets/enrollment_card.dart';
import 'widgets/enrollment_stats_widget.dart';

class EnrollmentsScreen extends StatefulWidget {
  const EnrollmentsScreen({super.key});

  @override
  State<EnrollmentsScreen> createState() => _EnrollmentsScreenState();
}

class _EnrollmentsScreenState extends State<EnrollmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String? _selectedCourseFilter;
  String _selectedSort = '-enrolledAt';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    if (authProvider.currentTutor != null) {
      await courseProvider.loadCourses(authProvider.currentTutor!.id);
      await enrollmentProvider.loadEnrollments(authProvider.currentTutor!.id);
      await enrollmentProvider.loadStats(authProvider.currentTutor!.id);
    }
  }

  Future<void> _handleRefresh() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentTutor != null) {
      await _loadData();
    }
  }

  void _handleSearch(String query) {
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
    enrollmentProvider.setSearchQuery(query);
  }

  void _handleCourseFilter(String? courseId) {
    setState(() {
      _selectedCourseFilter = courseId;
    });
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
    enrollmentProvider.setCourseFilter(courseId);
  }

  void _handleSortChange(String? sortBy) {
    if (sortBy == null) return;
    setState(() {
      _selectedSort = sortBy;
    });
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
    enrollmentProvider.setSortBy(sortBy);
  }

  void _clearFilters() {
    setState(() {
      _selectedCourseFilter = null;
      _selectedSort = '-enrolledAt';
      _searchController.clear();
    });
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
    enrollmentProvider.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrollments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Enrollments', icon: Icon(Icons.list)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textSecondary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEnrollmentsTab(enrollmentProvider, courseProvider),
          _buildAnalyticsTab(enrollmentProvider),
        ],
      ),
    );
  }

  Widget _buildEnrollmentsTab(EnrollmentProvider enrollmentProvider, CourseProvider courseProvider) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ResponsivePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildFilterSection(enrollmentProvider, courseProvider),
            const SizedBox(height: 16),
            _buildEnrollmentsList(enrollmentProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(EnrollmentProvider enrollmentProvider, CourseProvider courseProvider) {
    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          onChanged: _handleSearch,
          decoration: InputDecoration(
            hintText: 'Search by name, matric number, or email...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _handleSearch('');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppTheme.cardDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.2, end: 0),
        const SizedBox(height: 12),
        // Filters row
        ResponsiveBuilder(
          builder: (context, deviceType) {
            if (deviceType == DeviceType.mobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCourseFilterDropdown(courseProvider),
                  const SizedBox(height: 8),
                  _buildSortDropdown(),
                  const SizedBox(height: 8),
                  _buildClearFiltersButton(),
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(child: _buildCourseFilterDropdown(courseProvider)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSortDropdown()),
                  const SizedBox(width: 12),
                  _buildClearFiltersButton(),
                ],
              );
            }
          },
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: -0.2, end: 0),
      ],
    );
  }

  Widget _buildCourseFilterDropdown(CourseProvider courseProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String?>(
        value: _selectedCourseFilter,
        isExpanded: true,
        underline: const SizedBox(),
        hint: const Text('Filter by Course'),
        icon: const Icon(Icons.arrow_drop_down),
        dropdownColor: AppTheme.surfaceDark,
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('All Courses'),
          ),
          ...courseProvider.courses.map((course) {
            return DropdownMenuItem<String?>(
              value: course.id,
              child: Text('${course.code} - ${course.title}'),
            );
          }).toList(),
        ],
        onChanged: _handleCourseFilter,
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedSort,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down),
        dropdownColor: AppTheme.surfaceDark,
        items: const [
          DropdownMenuItem(
            value: '-enrolledAt',
            child: Text('Newest First'),
          ),
          DropdownMenuItem(
            value: 'enrolledAt',
            child: Text('Oldest First'),
          ),
          DropdownMenuItem(
            value: 'name',
            child: Text('Name (A-Z)'),
          ),
          DropdownMenuItem(
            value: '-name',
            child: Text('Name (Z-A)'),
          ),
          DropdownMenuItem(
            value: 'matricNumber',
            child: Text('Matric Number'),
          ),
        ],
        onChanged: _handleSortChange,
      ),
    );
  }

  Widget _buildClearFiltersButton() {
    return CustomButton(
      label: 'Clear',
      onPressed: _clearFilters,
      type: ButtonType.outlined,
      icon: const Icon(Icons.clear_all, size: 20),
    );
  }

  Widget _buildEnrollmentsList(EnrollmentProvider enrollmentProvider) {
    if (enrollmentProvider.isLoading) {
      return const Expanded(
        child: LoadingWidget(message: 'Loading enrollments...'),
      );
    }

    if (!enrollmentProvider.hasEnrollments) {
      return Expanded(
        child: _buildEmptyState(),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: enrollmentProvider.enrollments.length,
        itemBuilder: (context, index) {
          final enrollment = enrollmentProvider.enrollments[index];
          return EnrollmentCard(
            enrollment: enrollment,
            onDisenroll: () => _handleDisenroll(enrollment.id),
          )
              .animate()
              .fadeIn(delay: (100 * index).ms, duration: 600.ms)
              .slideX(begin: -0.2, end: 0);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(duration: 2.seconds),
          const SizedBox(height: 24),
          Text(
            'No Enrollments Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'No students have enrolled in your courses yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(EnrollmentProvider enrollmentProvider) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: EnrollmentStatsWidget(stats: enrollmentProvider.stats),
      ),
    );
  }

  Future<void> _handleDisenroll(String enrollmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disenroll Student'),
        content: const Text(
          'Are you sure you want to remove this student from the course? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Disenroll'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);

      if (authProvider.currentTutor != null) {
        final success = await enrollmentProvider.disenrollStudent(
          enrollmentId,
          authProvider.currentTutor!.id,
        );

        if (mounted) {
          if (success) {
            SuccessSnackBar.show(context, 'Student disenrolled successfully');
          } else {
            ErrorSnackBar.show(
              context,
              enrollmentProvider.errorMessage ?? 'Failed to disenroll student',
            );
          }
        }
      }
    }
  }
}