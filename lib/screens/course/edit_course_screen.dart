import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import '../../config/pocketbase_config.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../services/pocketbase_service.dart';
import '../../models/course.dart';
import '../../models/department.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_builder.dart';

class EditCourseScreen extends StatefulWidget {
  final String courseId;

  const EditCourseScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _pbService = PocketBaseService();

  List<Department> _departments = [];
  Department? _selectedDepartment;
  String? _selectedLevel;
  String? _selectedSemester;
  bool _isPublic = false;

  bool _isLoadingCourse = true;
  bool _isLoadingDepartments = false;
  Uint8List? _displayPictureBytes;
  String? _displayPictureFileName;
  String? _existingDisplayPicture;

  Course? _course;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourse();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCourse() async {
    setState(() => _isLoadingCourse = true);

    try {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      await courseProvider.loadCourse(widget.courseId);
      
      _course = courseProvider.selectedCourse;
      
      if (_course != null) {
        _titleController.text = _course!.title;
        _codeController.text = _course!.code;
        _descriptionController.text = _course!.description;
        _selectedLevel = _course!.level;
        _selectedSemester = _course!.semester;
        _isPublic = _course!.isPublic;
        _existingDisplayPicture = _course!.displayPicture;

        await _loadDepartments();
      }

      setState(() => _isLoadingCourse = false);
    } catch (e) {
      setState(() => _isLoadingCourse = false);
      if (mounted) {
        ErrorSnackBar.show(context, 'Failed to load course');
      }
    }
  }

  Future<void> _loadDepartments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tutor = authProvider.currentTutor;

    if (tutor == null) return;

    setState(() => _isLoadingDepartments = true);

    try {
      final departments = await _pbService.getDepartmentsByFaculty(tutor.faculty);
      setState(() {
        _departments = departments;
        
        // Set selected department
        if (_course != null) {
          _selectedDepartment = departments.firstWhere(
            (dept) => dept.id == _course!.department,
            orElse: () => departments.first,
          );
        }
        
        _isLoadingDepartments = false;
      });
    } catch (e) {
      setState(() => _isLoadingDepartments = false);
      if (mounted) {
        ErrorSnackBar.show(context, 'Failed to load departments');
      }
    }
  }

  Future<void> _pickDisplayPicture() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate file
        final validation = Validators.validateImageFile(
          file.name,
          file.size,
        );

        if (validation != null) {
          if (mounted) {
            ErrorSnackBar.show(context, validation);
          }
          return;
        }

        setState(() {
          _displayPictureBytes = file.bytes;
          _displayPictureFileName = file.name;
        });

        if (mounted) {
          SuccessSnackBar.show(context, 'New image selected');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, 'Failed to pick image');
      }
    }
  }

  void _removeDisplayPicture() {
    setState(() {
      _displayPictureBytes = null;
      _displayPictureFileName = null;
      _existingDisplayPicture = null;
    });
  }

  Future<void> _handleUpdateCourse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDepartment == null || _selectedLevel == null || _selectedSemester == null) {
      ErrorSnackBar.show(context, 'Please fill all required fields');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final tutor = authProvider.currentTutor;

    if (tutor == null) return;

    // Check if course code already exists (excluding current course)
    final codeExists = await courseProvider.checkCourseCodeExists(
      tutor.id,
      _codeController.text.trim(),
      excludeCourseId: widget.courseId,
    );

    if (codeExists) {
      if (mounted) {
        ErrorSnackBar.show(context, 'Course code already exists');
      }
      return;
    }

    final success = await courseProvider.updateCourse(
      courseId: widget.courseId,
      title: _titleController.text.trim(),
      code: _codeController.text.trim(),
      description: _descriptionController.text.trim(),
      departmentId: _selectedDepartment!.id,
      level: _selectedLevel!,
      semester: _selectedSemester!,
      displayPictureBytes: _displayPictureBytes,
      displayPictureFileName: _displayPictureFileName,
      isPublic: _isPublic,
    );

    if (mounted) {
      if (success) {
        SuccessSnackBar.show(context, AppConstants.courseUpdatedSuccess);
        Navigator.pop(context);
      } else {
        ErrorSnackBar.show(
          context,
          courseProvider.errorMessage ?? 'Failed to update course',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);

    if (_isLoadingCourse) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading course...'),
      );
    }

    if (_course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Course')),
        body: ErrorDisplayWidget(
          message: 'Failed to load course',
          onRetry: _loadCourse,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Course'),
      ),
      body: LoadingOverlay(
        isLoading: courseProvider.isLoading,
        message: 'Updating course...',
        child: ResponsiveConstrainedBox(
          maxWidth: 800,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildAcademicInfoSection(),
                  const SizedBox(height: 24),
                  _buildCourseInfoSection(),
                  const SizedBox(height: 24),
                  _buildDisplayPictureSection(),
                  const SizedBox(height: 24),
                  _buildVisibilitySection(),
                  const SizedBox(height: 32),
                  CustomButton(
                    label: 'Update Course',
                    onPressed: courseProvider.isLoading ? null : _handleUpdateCourse,
                    isLoading: courseProvider.isLoading,
                    width: double.infinity,
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 600.ms)
                      .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit Course Details',
          style: Theme.of(context).textTheme.headlineMedium,
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, end: 0),
        const SizedBox(height: 8),
        Text(
          'Update the information for ${_course!.code}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: -0.3, end: 0),
      ],
    );
  }

  Widget _buildAcademicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Academic Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        ),
        const SizedBox(height: 16),
        _isLoadingDepartments
            ? const Center(child: SmallLoadingIndicator())
            : CustomDropdown<Department>(
                label: 'Department',
                hint: 'Select department',
                value: _selectedDepartment,
                items: _departments
                    .map((dept) => DropdownMenuItem(
                          value: dept,
                          child: Text(dept.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedDepartment = value);
                },
                validator: (value) => Validators.validateDropdown(value, fieldName: 'department'),
                prefixIcon: const Icon(Icons.category_outlined),
              ),
        const SizedBox(height: 20),
        ResponsiveRow(
          children: [
            CustomDropdown<String>(
              label: 'Level',
              hint: 'Select level',
              value: _selectedLevel,
              items: AppConstants.levels
                  .map((level) => DropdownMenuItem(
                        value: level,
                        child: Text('$level Level'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedLevel = value);
              },
              validator: (value) => Validators.validateDropdown(value, fieldName: 'level'),
              prefixIcon: const Icon(Icons.school_outlined),
            ),
            CustomDropdown<String>(
              label: 'Semester',
              hint: 'Select semester',
              value: _selectedSemester,
              items: AppConstants.semesters
                  .map((semester) => DropdownMenuItem(
                        value: semester,
                        child: Text(semester),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedSemester = value);
              },
              validator: (value) => Validators.validateDropdown(value, fieldName: 'semester'),
              prefixIcon: const Icon(Icons.calendar_today_outlined),
            ),
          ],
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildCourseInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _titleController,
          label: 'Course Title',
          hint: 'e.g., Introduction to Software Engineering',
          prefixIcon: const Icon(Icons.title_outlined),
          validator: Validators.validateCourseTitle,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _codeController,
          label: 'Course Code',
          hint: 'e.g., SEN206',
          prefixIcon: const Icon(Icons.code_outlined),
          validator: Validators.validateCourseCode,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _descriptionController,
          label: 'Course Description',
          hint: 'Enter a detailed description of the course',
          prefixIcon: const Icon(Icons.description_outlined),
          validator: Validators.validateCourseDescription,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 600.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildDisplayPictureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Picture',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        ),
        const SizedBox(height: 16),
        if (_displayPictureBytes != null)
          // New image selected
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: MemoryImage(_displayPictureBytes!),
                fit: BoxFit.cover,
              ),
            ),
          )
        else if (_existingDisplayPicture != null && _existingDisplayPicture!.isNotEmpty)
          // Existing image from server
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: PocketBaseConfig.getFileUrl(
                PocketBaseConfig.coursesCollection,
                widget.courseId,
                _existingDisplayPicture!,
              ),
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: AppTheme.cardDark,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                label: _displayPictureBytes != null || _existingDisplayPicture != null
                    ? 'Change Image'
                    : 'Select Image',
                onPressed: _pickDisplayPicture,
                type: ButtonType.outlined,
                icon: const Icon(Icons.image_outlined, size: 20),
              ),
            ),
            if (_displayPictureBytes != null || _existingDisplayPicture != null) ...[
              const SizedBox(width: 12),
              CustomButton(
                label: 'Remove',
                onPressed: _removeDisplayPicture,
                type: ButtonType.outlined,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ],
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 600.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildVisibilitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Make Course Public',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Public courses can be viewed by all students',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) {
              setState(() => _isPublic = value);
            },
            activeColor: AppTheme.primaryBlue,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 900.ms, duration: 600.ms)
        .slideX(begin: -0.2, end: 0);
  }
}