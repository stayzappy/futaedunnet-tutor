import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher dependency
import '../../config/app_theme.dart';
import '../../config/pocketbase_config.dart';
import '../../utils/constants.dart';
import '../../utils/text_helper.dart';
import '../../providers/course_provider.dart';
import '../../providers/unit_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../models/course.dart';
import '../../models/unit.dart';
import '../../models/course_material.dart'; // Add import
import '../../models/course_announcement.dart'; // Add import
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/responsive_builder.dart';
import '../../widgets/custom_text_field.dart'; // Add import for your custom text field
import '../../utils/validators.dart'; // Add import for your validators if used
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

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with TickerProviderStateMixin { // Add TickerProviderStateMixin for TabController
  late TabController _tabController; // Controller for tabs
  int _enrollmentCount = 0;
  bool _isLoadingEnrollments = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Initialize tab controller for 3 tabs
    // Listen for tab changes to update the FAB
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourseAndContent(); // Load course, units, materials, and announcements
      _loadEnrollmentCount();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged); // Remove listener
    _tabController.dispose(); // Dispose the tab controller
    super.dispose();
  }

  // Callback for tab changes
  void _onTabChanged() {
    if (mounted) {
      setState(() {
        // Rebuild the widget to update the FAB when the tab changes
      });
    }
  }

  Future<void> _loadCourseAndContent() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final unitProvider = Provider.of<UnitProvider>(context, listen: false);

    await courseProvider.loadCourse(widget.courseId);
    await unitProvider.loadUnits(widget.courseId);
    // Load materials and announcements for the selected course using the new methods with manual timestamps
    await courseProvider.loadCourseMaterials(widget.courseId);
    await courseProvider.loadCourseAnnouncements(widget.courseId);
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
    ).then((_) => _loadCourseAndContent());
  }

  void _navigateToCreateUnit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateUnitScreen(courseId: widget.courseId),
      ),
    ).then((_) => _loadCourseAndContent());
  }

  void _navigateToEditUnit(String unitId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUnitScreen(unitId: unitId),
      ),
    ).then((_) => _loadCourseAndContent());
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

  // --- Methods for Course Materials ---
  Future<void> _addCourseMaterial() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    Uint8List? selectedFileBytes;
    String? selectedFileName;
    String? fileValidationError; // Store validation error for the file

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Course Material'),
            content: Column(
              mainAxisSize: MainAxisSize.min, // Shrink wrap content
              children: [
                CustomTextField( // Use your custom text field widget
                  controller: titleController,
                  label: 'Title *',
                  hint: 'e.g., Lecture Notes Chapter 1',
                  prefixIcon: const Icon(Icons.text_snippet_outlined),
                  validator: (value) => value?.trim().isEmpty ?? true ? 'Title is required' : null, // Basic validation
                ),
                const SizedBox(height: 12),
                CustomTextField( // Use your custom text field widget
                  controller: descriptionController,
                  label: 'Description (Optional)',
                  hint: 'Brief description of the material',
                  prefixIcon: const Icon(Icons.description_outlined),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  label: 'Select File *',
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt', 'zip'],
                    );
                    if (result != null && result.files.single.bytes != null) {
                      final file = result.files.single;
                      // --- Updated: Call validateFileSize with 3 arguments ---
                      final validation = Validators.validateFileSize(
                          file.size,
                          50 * 1024 * 1024, // Example: 50MB max
                          file.extension ?? '' // Pass the file extension as the type
                      );
                      if (validation != null) {
                        setState(() {
                          fileValidationError = validation;
                          selectedFileBytes = null; // Clear bytes if validation fails
                          selectedFileName = null; // Clear name if validation fails
                        });
                        return;
                      }
                      setState(() {
                        selectedFileBytes = file.bytes;
                        selectedFileName = file.name;
                        fileValidationError = null; // Clear any previous error
                      });
                    }
                  },
                  type: ButtonType.outlined,
                  icon: const Icon(Icons.attach_file_outlined, size: 20),
                ),
                if (selectedFileName != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          color: AppTheme.accentBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedFileName!,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (fileValidationError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    fileValidationError!,
                    style: TextStyle(color: AppTheme.error, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // --- Frontend Validation ---
                  bool hasError = false;
                  if (titleController.text.trim().isEmpty) {
                    ErrorSnackBar.show(context, 'Please enter a title for the material.');
                    hasError = true;
                  }
                  if (selectedFileBytes == null || selectedFileName == null) {
                    ErrorSnackBar.show(context, 'Please select a file to upload.');
                    hasError = true;
                  }
                  if (hasError) return; // Exit if validation fails

                  if (titleController.text.isNotEmpty &&
                      selectedFileBytes != null &&
                      selectedFileName != null) {
                    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
                    final success = await courseProvider.addMaterialToCourse(
                      courseId: widget.courseId, // Pass the courseId from the widget
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      fileBytes: selectedFileBytes!,
                      fileName: selectedFileName!,
                    );
                    if (success) {
                      SuccessSnackBar.show(context, 'Material added successfully');
                      // Reload materials to reflect the new one
                      await courseProvider.loadCourseMaterials(widget.courseId); // Reload with specific ID
                    } else {
                      ErrorSnackBar.show(context, 'Failed to add material: ${courseProvider.errorMessage}');
                    }
                    Navigator.pop(context); // Close dialog after attempt
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _removeCourseMaterial(String materialId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: const Text('Are you sure you want to delete this material?'),
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
      // Use the method that accepts the courseId directly
      final success = await courseProvider.removeMaterialFromCourse(
        courseId: widget.courseId, // Pass the courseId from the widget
        materialId: materialId,
      );

      if (mounted) {
        if (success) {
          SuccessSnackBar.show(context, 'Material deleted successfully');
          // Reload materials to reflect the deletion
          await courseProvider.loadCourseMaterials(widget.courseId); // Reload with specific ID
        } else {
          ErrorSnackBar.show(
            context,
            courseProvider.errorMessage ?? 'Failed to delete material',
          );
        }
      }
    }
  }

  // --- Method to download a material ---
  Future<void> _downloadMaterial(CourseMaterial material) async {
    // Construct the download URL using PocketBase config
    final downloadUrl = PocketBaseConfig.getFileUrl(
      'course_materials', // Collection name
      material.id,        // Record ID
      material.materialFileName, // Filename
    );

    try {
      // Use url_launcher to open the download URL in the browser
      // This relies on the browser handling the file download.
      // PocketBase file rules should allow the tutor to access this URL.
      await launchUrl(
        Uri.parse(downloadUrl),
        mode: LaunchMode.externalApplication, // Opens in browser
      );
      SuccessSnackBar.show(context, 'Download started for: ${material.materialFileName}');
    } catch (e) {
      ErrorSnackBar.show(context, 'Failed to initiate download: $e');
    }
  }


  // --- Methods for Course Announcements ---
  Future<void> _addCourseAnnouncement() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Course Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField( // Use your custom text field widget
              controller: titleController,
              label: 'Title *',
              hint: 'e.g., Welcome to the Course!',
              prefixIcon: const Icon(Icons.announcement_outlined),
              validator: (value) => value?.trim().isEmpty ?? true ? 'Title is required' : null, // Basic validation
            ),
            const SizedBox(height: 12),
            CustomTextField( // Use your custom text field widget
              controller: contentController,
              label: 'Content *',
              hint: 'Enter the announcement details here...',
              prefixIcon: const Icon(Icons.edit_outlined),
              maxLines: 5,
              validator: (value) => value?.trim().isEmpty ?? true ? 'Content is required' : null, // Basic validation
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // --- Frontend Validation ---
              bool hasError = false;
              if (titleController.text.trim().isEmpty) {
                ErrorSnackBar.show(context, 'Please enter a title for the announcement.');
                hasError = true;
              }
              if (contentController.text.trim().isEmpty) {
                ErrorSnackBar.show(context, 'Please enter content for the announcement.');
                hasError = true;
              }
              if (hasError) return; // Exit if validation fails

              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                final courseProvider = Provider.of<CourseProvider>(context, listen: false);
                final success = await courseProvider.addAnnouncementToCourse(
                  courseId: widget.courseId, // Pass the courseId from the widget
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                );
                if (success) {
                  SuccessSnackBar.show(context, 'Announcement added successfully');
                  // Reload announcements to reflect the new one
                  await courseProvider.loadCourseAnnouncements(widget.courseId); // Reload with specific ID
                } else {
                  ErrorSnackBar.show(context, 'Failed to add announcement: ${courseProvider.errorMessage}');
                }
                Navigator.pop(context); // Close dialog after attempt
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeCourseAnnouncement(String announcementId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement?'),
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
      // Use the method that accepts the courseId directly
      final success = await courseProvider.removeAnnouncementFromCourse(
        courseId: widget.courseId, // Pass the courseId from the widget
        announcementId: announcementId,
      );

      if (mounted) {
        if (success) {
          SuccessSnackBar.show(context, 'Announcement deleted successfully');
          // Reload announcements to reflect the deletion
          await courseProvider.loadCourseAnnouncements(widget.courseId); // Reload with specific ID
        } else {
          ErrorSnackBar.show(
            context,
            courseProvider.errorMessage ?? 'Failed to delete announcement',
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
          onRetry: _loadCourseAndContent,
        ),
      );
    }

    // --- Determine FAB based on active tab ---
    Widget? currentFAB;
    String? fabTooltip;
    if (_tabController.index == 0) { // Units Tab
      currentFAB = FloatingActionButton(
        heroTag: "addUnitFAB",
        onPressed: _navigateToCreateUnit,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add),
      );
      fabTooltip = 'Add Unit';
    } else if (_tabController.index == 1) { // Materials Tab
      currentFAB = FloatingActionButton(
        heroTag: "addMaterialFAB",
        onPressed: _addCourseMaterial,
        backgroundColor: AppTheme.accentBlue,
        child: const Icon(Icons.attach_file),
      );
      fabTooltip = 'Add Material';
    } else if (_tabController.index == 2) { // Announcements Tab
      currentFAB = FloatingActionButton(
        heroTag: "addAnnouncementFAB",
        onPressed: _addCourseAnnouncement,
        backgroundColor: AppTheme.warning,
        child: const Icon(Icons.announcement),
      );
      fabTooltip = 'Add Announcement';
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
      // --- Dynamic FAB with Tooltip based on active tab ---
      floatingActionButton: currentFAB != null
          ? Tooltip(
              message: fabTooltip ?? 'Action',
              child: currentFAB.animate().fadeIn(delay: 800.ms, duration: 400.ms).scale(begin: const Offset(0, 0), end: const Offset(1, 1)),
            )
          : null, // Only show FAB if one is defined for the current tab
      body: Column(
        children: [
          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Units'),
              Tab(text: 'Materials'),
              Tab(text: 'Announcements'),
            ],
          ),
          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Units Tab
                RefreshIndicator(
                  onRefresh: _loadCourseAndContent,
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
                // Materials Tab
                RefreshIndicator(
                  onRefresh: () async {
                    await _loadCourseAndContent(); // Reloads materials too
                  },
                  child: ResponsivePadding(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          _buildMaterialsSection(courseProvider),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
                // Announcements Tab
                RefreshIndicator(
                  onRefresh: () async {
                    await _loadCourseAndContent(); // Reloads announcements too
                  },
                  child: ResponsivePadding(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          _buildAnnouncementsSection(courseProvider),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  // --- Widget for Materials Section (Tab) ---
  Widget _buildMaterialsSection(CourseProvider courseProvider) {
    final materials = courseProvider.materials;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Course Materials',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (materials.isNotEmpty)
              Text(
                '${materials.length} ${materials.length == 1 ? "material" : "materials"}',
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
        if (courseProvider.isLoading)
          const Center(child: LoadingWidget(message: 'Loading materials...'))
        else if (materials.isEmpty)
          _buildEmptyMaterials()
        else
          _buildMaterialsList(materials),
      ],
    );
  }

  Widget _buildEmptyMaterials() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentBlue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.attach_file_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(duration: 2.seconds),
          const SizedBox(height: 16),
          Text(
            'No Materials Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add course materials like PDFs or documents here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Add First Material',
            onPressed: _addCourseMaterial,
            icon: const Icon(Icons.add, size: 20),
            type: ButtonType.secondary, // Use secondary color
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 600.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildMaterialsList(List<CourseMaterial> materials) {
    return Column(
      children: materials.asMap().entries.map((entry) {
        final index = entry.key;
        final material = entry.value;
        return _buildMaterialCard(material)
            .animate()
            .fadeIn(delay: (700 + (index * 100)).ms, duration: 600.ms)
            .slideX(begin: -0.2, end: 0);
      }).toList(),
    );
  }

  Widget _buildMaterialCard(CourseMaterial material) {
    // --- Make the material card clickable for download ---
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell( // Wrap with InkWell for click effect
        onTap: () => _downloadMaterial(material), // Add download handler
        borderRadius: BorderRadius.circular(16), // Match card radius
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.insert_drive_file,
                    color: AppTheme.accentBlue,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (material.description != null && material.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        material.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'File: ${material.materialFileName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              // Add download icon
              Icon(
                Icons.download,
                color: AppTheme.accentBlue,
              ),
              const SizedBox(width: 8), // Space before menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'delete') {
                    _removeCourseMaterial(material.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppTheme.error),
                        SizedBox(width: 12),
                        Text('Delete Material'),
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

  // --- Widget for Announcements Section (Tab) ---
  Widget _buildAnnouncementsSection(CourseProvider courseProvider) {
    final announcements = courseProvider.announcements;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Course Announcements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (announcements.isNotEmpty)
              Text(
                '${announcements.length} ${announcements.length == 1 ? "announcement" : "announcements"}',
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
        if (courseProvider.isLoading)
          const Center(child: LoadingWidget(message: 'Loading announcements...'))
        else if (announcements.isEmpty)
          _buildEmptyAnnouncements()
        else
          _buildAnnouncementsList(announcements),
      ],
    );
  }

  Widget _buildEmptyAnnouncements() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.announcement_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(duration: 2.seconds),
          const SizedBox(height: 16),
          Text(
            'No Announcements Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Post important updates or information here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Add First Announcement',
            onPressed: _addCourseAnnouncement,
            icon: const Icon(Icons.add, size: 20),
            type: ButtonType.secondary, // Use secondary color
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 600.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildAnnouncementsList(List<CourseAnnouncement> announcements) {
    return Column(
      children: announcements.asMap().entries.map((entry) {
        final index = entry.key;
        final announcement = entry.value;
        return _buildAnnouncementCard(announcement)
            .animate()
            .fadeIn(delay: (700 + (index * 100)).ms, duration: 600.ms)
            .slideX(begin: -0.2, end: 0);
      }).toList(),
    );
  }

  Widget _buildAnnouncementCard(CourseAnnouncement announcement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.announcement,
                      color: AppTheme.warning,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _removeCourseAnnouncement(announcement.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppTheme.error),
                          SizedBox(width: 12),
                          Text('Delete Announcement'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              announcement.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Posted: ${announcement.createdAt.toString().split('.').first}', // Format date as needed
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}