import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../config/app_theme.dart';
import '../../config/pocketbase_config.dart';
import '../../utils/constants.dart';
import '../../utils/text_helper.dart';
import '../../providers/unit_provider.dart';
import '../../models/unit.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/responsive_builder.dart';

class UnitPreviewScreen extends StatefulWidget {
  final String unitId;

  const UnitPreviewScreen({
    super.key,
    required this.unitId,
  });

  @override
  State<UnitPreviewScreen> createState() => _UnitPreviewScreenState();
}

class _UnitPreviewScreenState extends State<UnitPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isLoadingVideo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUnit();
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadUnit() async {
    final unitProvider = Provider.of<UnitProvider>(context, listen: false);
    await unitProvider.loadUnit(widget.unitId);
    
    final unit = unitProvider.selectedUnit;
    if (unit != null && unit.hasVideo) {
      _initializeVideo(unit);
    }
  }

  Future<void> _initializeVideo(Unit unit) async {
    setState(() => _isLoadingVideo = true);

    try {
      final videoUrl = unit.getVideoUrl(PocketBaseConfig.unitsCollection);
      
      if (videoUrl != null) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await _videoController!.initialize();
        
        setState(() {
          _isVideoInitialized = true;
          _isLoadingVideo = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingVideo = false);
      if (mounted) {
        ErrorSnackBar.show(context, 'Failed to load video');
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController != null && _isVideoInitialized) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitProvider = Provider.of<UnitProvider>(context);
    final unit = unitProvider.selectedUnit;

    if (unitProvider.isLoading && unit == null) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading unit...'),
      );
    }

    if (unit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unit Preview')),
        body: ErrorDisplayWidget(
          message: 'Failed to load unit',
          onRetry: _loadUnit,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview as Student'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.info.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.visibility, size: 18, color: AppTheme.info),
                const SizedBox(width: 8),
                Text(
                  'Student View',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.info,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ResponsiveConstrainedBox(
        maxWidth: 900,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUnitHeader(unit),
              const SizedBox(height: 32),
              _buildUnitContent(unit),
              if (unit.hasVideo) ...[
                const SizedBox(height: 32),
                _buildVideoSection(unit),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitHeader(Unit unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Unit ${unit.unitNumber}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
        const SizedBox(height: 16),
        Text(
          unit.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideX(begin: -0.2, end: 0),
      ],
    );
  }

  Widget _buildUnitContent(Unit unit) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          // Display content - in production, you'd want to render HTML properly
          Text(
            unit.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.8,
                ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildVideoSection(Unit unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Video Lecture',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        )
            .animate()
            .fadeIn(delay: 600.ms, duration: 600.ms)
            .slideX(begin: -0.2, end: 0),
        const SizedBox(height: 16),
        if (_isLoadingVideo)
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: LoadingWidget(message: 'Loading video...'),
            ),
          )
        else if (_isVideoInitialized && _videoController != null)
          _buildVideoPlayer()
        else
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.error,
              ),
            ),
          ),
      ],
    )
        .animate()
        .fadeIn(delay: 800.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildVideoPlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          // Play/Pause overlay
          if (!_videoController!.value.isPlaying)
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(20),
                child: const Icon(
                  Icons.play_arrow,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            )
                .animate()
                .scale(duration: 300.ms)
                .fadeIn(),
          // Controls bar at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildVideoControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Play/Pause button
          IconButton(
            icon: Icon(
              _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: _togglePlayPause,
          ),
          // Time display
          Text(
            _formatDuration(_videoController!.value.position),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(width: 8),
          // Progress bar
          Expanded(
            child: VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppTheme.primaryBlue,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Total duration
          Text(
            _formatDuration(_videoController!.value.duration),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          // Fullscreen button (placeholder)
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: () {
              // Fullscreen functionality could be added here
              InfoSnackBar.show(context, 'Fullscreen not implemented in preview');
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    return TextHelper.formatDuration(duration);
  }
}