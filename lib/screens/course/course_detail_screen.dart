import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import '../../config/pocketbase_config.dart';
import '../../utils/constants.dart';
import '../../utils/text_helper.dart';
import '../../providers/course_provider.dart';
import '../../providers/unit_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../models/course.dart';
import '../../models/unit.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/responsive_builder.dart';
import '../unit/create_unit_screen.dart';
import '../unit/unit_preview_screen.dart';
import '../unit/edit_unit_screen.dart';
import '../enrollments/course_enrollments_screen.dart';
import 'edit_course_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _enrollmentCount = 0;
  bool _isLoadingEnrollments = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourseAndUnits();
      _loadEnrollmentCount();
    });
  }

  Future<void> _loadCourseAndUnits() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final unitProvider = Provider.of<UnitProvider>(context, listen: false);

    await courseProvider.loadCourse(widget.courseId);
    await unitProvider.loadUnits(widget.courseId);
  }

  Future<void> _loadEnrollmentCount() async {
    setState(() => _isLoadingEnrollments = true);

    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
    final count = await enrollmentProvider.getEnrollmentCount(widget.courseId);

    if (mounted) {
      setState(() {
        _enrollmentCount = count;
        _isLoadingEnrollments = false;
      });
    }
  }

  void _navigateToEditCourse() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCourseScreen(courseId: widget.courseId),
      ),
    ).then((_) => _loadCourseAndUnits());
  }

  void _navigateToCreateUnit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateUnitScreen(courseId: widget.courseId),
      ),
    ).then((_) => _loadCourseAndUnits());
  }

  void _navigateToEditUnit(String unitId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUnitScreen(unitId: unitId),
      ),
    ).then((_) => _loadCourseAndUnits());
  }

  void _navigateToUnitPreview(String unitId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnitPreviewScreen(unitId: unitId),
      ),
    );
  }

  void _navigateToEnrollments(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseEnrollmentsScreen(course: course),
      ),
    ).then((_) => _loadEnrollmentCount());
  }

  Future<void> _handleDeleteCourse() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text(
          'Are you sure you want to delete this course? This action cannot be undone and will delete all units.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      final success = await courseProvider.deleteCourse(widget.courseId);

      if (mounted) {
        if (success) {
          SuccessSnackBar.show(context, 'Course deleted successfully');
          Navigator.pop(context);
        } else {
          ErrorSnackBar.show(
            context,
            courseProvider.errorMessage ?? 'Failed to delete course',
          );
        }
      }
    }
  }

  Future<void> _handleDeleteUnit(String unitId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unit'),
        content: const Text('Are you sure you want to delete this unit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final unitProvider = Provider.of<UnitProvider>(context, listen: false);
      final success = await unitProvider.deleteUnit(unitId);

      if (mounted) {
        if (success) {
          SuccessSnackBar.show(context, 'Unit deleted successfully');
        } else {
          ErrorSnackBar.show(
            context,
            unitProvider.errorMessage ?? 'Failed to delete unit',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final unitProvider = Provider.of<UnitProvider>(context);
    final course = courseProvider.selectedCourse;

    if (courseProvider.isLoading && course == null) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading course...'),
      );
    }

    if (course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Details')),
        body: ErrorDisplayWidget(
          message: 'Failed to load course',
          onRetry: _loadCourseAndUnits,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(course.code),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('$_enrollmentCount'),
              child: const Icon(Icons.people),
            ),
            onPressed: () => _navigateToEnrollments(course),
            tooltip: 'View Enrollments',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditCourse,
            tooltip: 'Edit Course',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete') {
                _handleDeleteCourse();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppTheme.error),
                    SizedBox(width: 12),
                    Text('Delete Course'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateUnit,
        icon: const Icon(Icons.add),
        label: const Text('Add Unit'),
        backgroundColor: AppTheme.primaryBlue,
      )
          .animate()
          .fadeIn(delay: 800.ms, duration: 400.ms)
          .scale(begin: const Offset(0, 0), end: const Offset(1, 1)),
      body: RefreshIndicator(
        onRefresh: _loadCourseAndUnits,
        child: ResponsivePadding(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                _buildCourseHeader(course),
                const SizedBox(height: 32),
                _buildUnitsSection(unitProvider),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseHeader(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (course.displayPicture != null && course.displayPicture!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: PocketBaseConfig.getFileUrl(
                PocketBaseConfig.coursesCollection,
                course.id,
                course.displayPicture!,
              ),
              height: 250,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 250,
                color: AppTheme.cardDark,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.7),
                      AppTheme.primaryDark,
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.school, size: 80, color: Colors.white70),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
        const SizedBox(height: 24),
        Text(
          course.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideX(begin: -0.2, end: 0),
        const SizedBox(height: 8),
        Text(
          course.code,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 600.ms)
            .slideX(begin: -0.2, end: 0),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildInfoChip(Icons.school, TextHelper.getCourseLevelDisplay(course.level)),
            _buildInfoChip(Icons.calendar_today, course.semester),
            _buildInfoChip(
              course.isPublic ? Icons.public : Icons.lock,
              course.isPublic ? 'Public' : 'Private',
            ),
            if (!_isLoadingEnrollments)
              _buildInfoChip(
                Icons.people,
                '$_enrollmentCount ${_enrollmentCount == 1 ? "student" : "students"}',
              ),
          ],
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .slideX(begin: -0.2, end: 0),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                course.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 500.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsSection(UnitProvider unitProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Course Units',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (unitProvider.hasUnits)
              Text(
                '${unitProvider.unitCount} ${unitProvider.unitCount == 1 ? "unit" : "units"}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
          ],
        )
            .animate()
            .fadeIn(delay: 600.ms, duration: 600.ms)
            .slideX(begin: -0.2, end: 0),
        const SizedBox(height: 16),
        if (unitProvider.isLoading)
          const Center(child: LoadingWidget(message: 'Loading units...'))
        else if (!unitProvider.hasUnits)
          _buildEmptyUnits()
        else
          _buildUnitsList(unitProvider.units),
      ],
    );
  }

  Widget _buildEmptyUnits() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.library_books_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(duration: 2.seconds),
          const SizedBox(height: 16),
          Text(
            'No Units Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first unit to start building this course',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Add First Unit',
            onPressed: _navigateToCreateUnit,
            icon: const Icon(Icons.add, size: 20),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 600.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildUnitsList(List<Unit> units) {
    return Column(
      children: units.asMap().entries.map((entry) {
        final index = entry.key;
        final unit = entry.value;
        return _buildUnitCard(unit)
            .animate()
            .fadeIn(delay: (700 + (index * 100)).ms, duration: 600.ms)
            .slideX(begin: -0.2, end: 0);
      }).toList(),
    );
  }

  Widget _buildUnitCard(Unit unit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToUnitPreview(unit.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${unit.unitNumber}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          unit.hasVideo ? Icons.video_library : Icons.description,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          unit.hasVideo ? 'Contains video' : 'Text content',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'preview') {
                    _navigateToUnitPreview(unit.id);
                  } else if (value == 'edit') {
                    _navigateToEditUnit(unit.id);
                  } else if (value == 'delete') {
                    _handleDeleteUnit(unit.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'preview',
                    child: Row(
                      children: [
                        Icon(Icons.visibility),
                        SizedBox(width: 12),
                        Text('Preview as Student'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 12),
                        Text('Edit Unit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppTheme.error),
                        SizedBox(width: 12),
                        Text('Delete Unit'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}