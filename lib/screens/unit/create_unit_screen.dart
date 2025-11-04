import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../config/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/text_helper.dart';
import '../../providers/unit_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_builder.dart';
import 'widgets/unit_content_editor.dart';

class CreateUnitScreen extends StatefulWidget {
  final String courseId;

  const CreateUnitScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<CreateUnitScreen> createState() => _CreateUnitScreenState();
}

class _CreateUnitScreenState extends State<CreateUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _orderController = TextEditingController();
  final _quillController = QuillController.basic();

  Uint8List? _videoBytes;
  String? _videoFileName;
  double _nextOrder = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNextOrder();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _orderController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _loadNextOrder() async {
    final unitProvider = Provider.of<UnitProvider>(context, listen: false);
    final nextOrder = await unitProvider.getNextUnitOrder(widget.courseId);
    setState(() {
      _nextOrder = nextOrder;
      _orderController.text = nextOrder.toInt().toString();
    });
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        // Change from FileType.video to FileType.custom
        type: FileType.custom,
        // Define the allowed extensions, including mkv
        allowedExtensions: ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv'], // Add or modify this list as needed
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate file
        final validation = Validators.validateVideoFile(
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
          _videoBytes = file.bytes;
          _videoFileName = file.name;
        });

        if (mounted) {
          SuccessSnackBar.show(context, 'Video selected: ${TextHelper.formatFileSize(file.size)}');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, 'Failed to pick video');
      }
    }
  }

  void _removeVideo() {
    setState(() {
      _videoBytes = null;
      _videoFileName = null;
    });
  }

  String _getContentAsHtml() {
    final delta = _quillController.document.toDelta();
    // Convert delta to HTML (you may need to use vsc_quill_delta_to_html package)
    // For now, we'll use plain text as fallback
    return _quillController.document.toPlainText();
  }

  Future<void> _handleCreateUnit() async {
    if (!_formKey.currentState!.validate()) return;

    final content = _getContentAsHtml();
    if (content.trim().isEmpty) {
      ErrorSnackBar.show(context, 'Please add some content to the unit');
      return;
    }

    final unitProvider = Provider.of<UnitProvider>(context, listen: false);

    final order = double.tryParse(_orderController.text) ?? _nextOrder;

    final success = await unitProvider.createUnit(
      title: _titleController.text.trim(),
      content: content,
      courseId: widget.courseId,
      order: order,
      videoBytes: _videoBytes,
      videoFileName: _videoFileName,
    );

    if (mounted) {
      if (success) {
        SuccessSnackBar.show(context, AppConstants.unitCreatedSuccess);
        Navigator.pop(context);
      } else {
        ErrorSnackBar.show(
          context,
          unitProvider.errorMessage ?? 'Failed to create unit',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitProvider = Provider.of<UnitProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Unit'),
      ),
      body: LoadingOverlay(
        isLoading: unitProvider.isLoading,
        message: 'Creating unit...',
        child: ResponsiveConstrainedBox(
          maxWidth: 1000,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildBasicInfoSection(),
                  const SizedBox(height: 24),
                  _buildContentSection(),
                  const SizedBox(height: 24),
                  _buildVideoSection(),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Cancel',
                          onPressed: () => Navigator.pop(context),
                          type: ButtonType.outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: CustomButton(
                          label: 'Create Unit',
                          onPressed: unitProvider.isLoading ? null : _handleCreateUnit,
                          isLoading: unitProvider.isLoading,
                        ),
                      ),
                    ],
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
          'Unit Details',
          style: Theme.of(context).textTheme.headlineMedium,
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, end: 0),
        const SizedBox(height: 8),
        Text(
          'Create a new unit for this course',
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

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        ),
        const SizedBox(height: 16),
        ResponsiveRow(
          children: [
            Expanded(
              flex: 3,
              child: CustomTextField(
                controller: _titleController,
                label: 'Unit Title',
                hint: 'e.g., Introduction to Requirements',
                prefixIcon: const Icon(Icons.title_outlined),
                validator: Validators.validateUnitTitle,
                textCapitalization: TextCapitalization.words,
              ),
            ),
            Expanded(
              child: CustomTextField(
                controller: _orderController,
                label: 'Unit Number',
                hint: 'e.g., 1',
                prefixIcon: const Icon(Icons.numbers),
                validator: Validators.validateUnitOrder,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unit Content',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use the editor below to create rich content with formatting, images, and more',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        UnitContentEditor(
          controller: _quillController,
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 600.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Video Content (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add a video to supplement your unit content',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        if (_videoBytes != null && _videoFileName != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.video_library,
                    color: AppTheme.primaryBlue,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _videoFileName!,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        TextHelper.formatFileSize(_videoBytes!.length),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.error),
                  onPressed: _removeVideo,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Change Video',
            onPressed: _pickVideo,
            type: ButtonType.outlined,
            icon: const Icon(Icons.video_library, size: 20),
            width: double.infinity,
          ),
        ] else
          CustomButton(
            label: 'Select Video',
            onPressed: _pickVideo,
            type: ButtonType.outlined,
            icon: const Icon(Icons.video_library, size: 20),
            width: double.infinity,
          ),
      ],
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 600.ms)
        .slideX(begin: -0.2, end: 0);
  }
}