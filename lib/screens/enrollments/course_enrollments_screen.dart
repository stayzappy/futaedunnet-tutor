import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/enrollment_provider.dart';
import '../../models/course.dart';
import '../../models/enrollment.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/responsive_builder.dart';
import 'widgets/enrollment_card.dart';

class CourseEnrollmentsScreen extends StatefulWidget {
  final Course course;

  const CourseEnrollmentsScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseEnrollmentsScreen> createState() => _CourseEnrollmentsScreenState();
}

class _CourseEnrollmentsScreenState extends State<CourseEnrollmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _selectedSort = '-enrolledAt';
  
  List<Enrollment> _completedEnrollments = [];
  List<Enrollment> _ongoingEnrollments = [];
  bool _isLoadingCompleted = false;
  bool _isLoadingOngoing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index == 1 && _completedEnrollments.isEmpty && !_isLoadingCompleted) {
      _loadCompletedEnrollments();
    } else if (_tabController.index == 2 && _ongoingEnrollments.isEmpty && !_isLoadingOngoing) {
      _loadOngoingEnrollments();
    }
  }

  Future<void> _loadData() async {
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
    await enrollmentProvider.loadCourseEnrollments(widget.course.id);
  }

  Future<void> _loadCompletedEnrollments() async {
    setState(() => _isLoadingCompleted = true);
    
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
    final completed = await enrollmentProvider.getCompletedEnrollments(widget.course.id);
    
    if (mounted) {
      setState(() {
        _completedEnrollments = completed;
        _isLoadingCompleted = false;
      });
    }
  }

  Future<void> _loadOngoingEnrollments() async {
    setState(() => _isLoadingOngoing = true);
    
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
    final ongoing = await enrollmentProvider.getOngoingEnrollments(widget.course.id);
    
    if (mounted) {
      setState(() {
        _ongoingEnrollments = ongoing;
        _isLoadingOngoing = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
    if (_tabController.index == 1) {
      await _loadCompletedEnrollments();
    } else if (_tabController.index == 2) {
      await _loadOngoingEnrollments();
    }
  }

  void _handleSearch(String query) {
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
    enrollmentProvider.setSearchQuery(query);
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
      _selectedSort = '-enrolledAt';
      _searchController.clear();
    });
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
    enrollmentProvider.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Course Enrollments'),
            Text(
              widget.course.code,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
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
          tabs: [
            Tab(
              text: 'All',
              icon: Badge(
                label: Text('${enrollmentProvider.enrollments.length}'),
                child: const Icon(Icons.people),
              ),
            ),
            Tab(
              text: 'Completed',
              icon: Badge(
                label: Text('${_completedEnrollments.length}'),
                child: const Icon(Icons.check_circle),
              ),
            ),
            Tab(
              text: 'Ongoing',
              icon: Badge(
                label: Text('${_ongoingEnrollments.length}'),
                child: const Icon(Icons.pending),
              ),
            ),
          ],
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textSecondary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTab(enrollmentProvider),
          _buildCompletedTab(),
          _buildOngoingTab(),
        ],
      ),
    );
  }

  Widget _buildAllTab(EnrollmentProvider enrollmentProvider) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ResponsivePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildCourseHeader(),
            const SizedBox(height: 16),
            _buildFilterSection(enrollmentProvider),
            const SizedBox(height: 16),
            _buildEnrollmentsList(enrollmentProvider.enrollments, enrollmentProvider.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedTab() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ResponsivePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildInfoBanner(
              'Students who have completed all units in this course',
              Icons.check_circle,
              AppTheme.success,
            ),
            const SizedBox(height: 16),
            _buildEnrollmentsList(_completedEnrollments, _isLoadingCompleted),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingTab() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ResponsivePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildInfoBanner(
              'Students who are still studying this course',
              Icons.pending,
              AppTheme.warning,
            ),
            const SizedBox(height: 16),
            _buildEnrollmentsList(_ongoingEnrollments, _isLoadingOngoing),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.2),
            AppTheme.primaryDark.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.course.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.school, '${widget.course.level} Level'),
              _buildInfoChip(Icons.calendar_today, widget.course.semester),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildFilterSection(EnrollmentProvider enrollmentProvider) {
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
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: -0.2, end: 0),
        const SizedBox(height: 12),
        // Sort and clear filters
        ResponsiveBuilder(
          builder: (context, deviceType) {
            if (deviceType == DeviceType.mobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSortDropdown(),
                  const SizedBox(height: 8),
                  _buildClearFiltersButton(),
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(child: _buildSortDropdown()),
                  const SizedBox(width: 12),
                  _buildClearFiltersButton(),
                ],
              );
            }
          },
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .slideY(begin: -0.2, end: 0),
      ],
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

  Widget _buildEnrollmentsList(List<Enrollment> enrollments, bool isLoading) {
    if (isLoading) {
      return const Expanded(
        child: LoadingWidget(message: 'Loading enrollments...'),
      );
    }

    if (enrollments.isEmpty) {
      return Expanded(
        child: _buildEmptyState(),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: enrollments.length,
        itemBuilder: (context, index) {
          final enrollment = enrollments[index];
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
            'No Students Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'No students match your current filters.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
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
      final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);

      // We need the tutorId, so we'll just reload after disenroll
      final success = await enrollmentProvider.disenrollStudent(
        enrollmentId,
        widget.course.tutor, // Use course's tutor ID
      );

      if (mounted) {
        if (success) {
          SuccessSnackBar.show(context, 'Student disenrolled successfully');
          await _handleRefresh();
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