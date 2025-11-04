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
import '../../models/unit.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_builder.dart';
import 'widgets/unit_content_editor.dart';

class EditUnitScreen extends StatefulWidget {
  final String unitId;

  const EditUnitScreen({
    super.key,
    required this.unitId,
  });

  @override
  State<EditUnitScreen> createState() => _EditUnitScreenState();
}

class _EditUnitScreenState extends State<EditUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _orderController = TextEditingController();
  late QuillController _quillController;

  Uint8List? _videoBytes;
  String? _videoFileName;
  String? _existingVideo;
  bool _removeVideo = false;

  bool _isLoadingUnit = true;
  Unit? _unit;

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUnit();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _orderController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _loadUnit() async {
    setState(() => _isLoadingUnit = true);

    try {
      final unitProvider = Provider.of<UnitProvider>(context, listen: false);
      await unitProvider.loadUnit(widget.unitId);
      
      _unit = unitProvider.selectedUnit;
      
      if (_unit != null) {
        _titleController.text = _unit!.title;
        _orderController.text = _unit!.order.toInt().toString();
        _existingVideo = _unit!.video;
        
        // Load content into Quill editor
        // For simplicity, we'll treat the content as plain text
        // In production, you'd want to properly parse HTML to Delta
        final document = Document()..insert(0, _unit!.content);
        _quillController = QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }

      setState(() => _isLoadingUnit = false);
    } catch (e) {
      setState(() => _isLoadingUnit = false);
      if (mounted) {
        ErrorSnackBar.show(context, 'Failed to load unit');
      }
    }
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
          _removeVideo = false;
        });

        if (mounted) {
          SuccessSnackBar.show(context, 'New video selected: ${TextHelper.formatFileSize(file.size)}');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, 'Failed to pick video');
      }
    }
  }

  void _removeVideoFile() {
    setState(() {
      _videoBytes = null;
      _videoFileName = null;
      _existingVideo = null;
      _removeVideo = true;
    });
  }

  String _getContentAsHtml() {
    return _quillController.document.toPlainText();
  }

  Future<void> _handleUpdateUnit() async {
    if (!_formKey.currentState!.validate()) return;

    final content = _getContentAsHtml();
    if (content.trim().isEmpty) {
      ErrorSnackBar.show(context, 'Please add some content to the unit');
      return;
    }

    final unitProvider = Provider.of<UnitProvider>(context, listen: false);

    final order = double.tryParse(_orderController.text) ?? _unit!.order;

    final success = await unitProvider.updateUnit(
      unitId: widget.unitId,
      title: _titleController.text.trim(),
      content: content,
      order: order,
      videoBytes: _videoBytes,
      videoFileName: _videoFileName,
      removeVideo: _removeVideo,
    );

    if (mounted) {
      if (success) {
        SuccessSnackBar.show(context, AppConstants.unitUpdatedSuccess);
        Navigator.pop(context);
      } else {
        ErrorSnackBar.show(
          context,
          unitProvider.errorMessage ?? 'Failed to update unit',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitProvider = Provider.of<UnitProvider>(context);

    if (_isLoadingUnit) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading unit...'),
      );
    }

    if (_unit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Unit')),
        body: ErrorDisplayWidget(
          message: 'Failed to load unit',
          onRetry: _loadUnit,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Unit'),
      ),
      body: LoadingOverlay(
        isLoading: unitProvider.isLoading,
        message: 'Updating unit...',
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
                          label: 'Update Unit',
                          onPressed: unitProvider.isLoading ? null : _handleUpdateUnit,
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
          'Edit Unit Details',
          style: Theme.of(context).textTheme.headlineMedium,
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.3, end: 0),
        const SizedBox(height: 8),
        Text(
          'Update the information for Unit ${_unit!.unitNumber}',
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
          'Update your unit content with rich formatting',
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
          'Video Content',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Update or remove the video for this unit',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        if (_videoBytes != null && _videoFileName != null)
          // New video selected
          _buildVideoPreview(_videoFileName!, _videoBytes!.length, true)
        else if (_existingVideo != null && _existingVideo!.isNotEmpty && !_removeVideo)
          // Existing video from server
          _buildExistingVideoPreview()
        else
          // No video
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

  Widget _buildVideoPreview(String fileName, int fileSize, bool isNew) {
    return Column(
      children: [
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
                      fileName,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isNew ? '${TextHelper.formatFileSize(fileSize)} (New)' : 'Existing video',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.error),
                onPressed: _removeVideoFile,
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
      ],
    );
  }

  Widget _buildExistingVideoPreview() {
    return _buildVideoPreview(_existingVideo!, 0, false);
  }
}