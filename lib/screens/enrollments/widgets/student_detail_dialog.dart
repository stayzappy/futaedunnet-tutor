import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../models/enrollment.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/loading_widget.dart';

class StudentDetailDialog extends StatefulWidget {
  final Enrollment enrollment;
  final VoidCallback onDisenroll;

  const StudentDetailDialog({
    super.key,
    required this.enrollment,
    required this.onDisenroll,
  });

  @override
  State<StudentDetailDialog> createState() => _StudentDetailDialogState();
}

class _StudentDetailDialogState extends State<StudentDetailDialog> {
  double? _progress;
  bool _isLoadingProgress = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoadingProgress = true);

    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
    final progress = await enrollmentProvider.getStudentProgress(
      widget.enrollment.student,
      widget.enrollment.course,
    );

    if (mounted) {
      setState(() {
        _progress = progress;
        _isLoadingProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.enrollment.studentInfo;
    final course = widget.enrollment.courseInfo;

    if (student == null) {
      return const SizedBox.shrink();
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, student),
              _buildContent(context, student, course),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, StudentInfo student) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.8),
            AppTheme.primaryDark,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Student Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStudentAvatar(student),
          const SizedBox(height: 12),
          Text(
            student.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            student.matricNumber,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.3, end: 0);
  }

  Widget _buildStudentAvatar(StudentInfo student) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          student.initials,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, StudentInfo student, CourseInfo? course) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSection(
            context,
            'Contact Information',
            Icons.contact_mail,
            [
              _buildInfoRow(context, Icons.email, 'Email', student.email),
            ],
            0,
          ),
          const SizedBox(height: 20),
          if (course != null) ...[
            _buildSection(
              context,
              'Course Information',
              Icons.book,
              [
                _buildInfoRow(context, Icons.class_, 'Course Code', course.code),
                _buildInfoRow(context, Icons.title, 'Course Title', course.title),
                _buildInfoRow(context, Icons.school, 'Level', '${course.level} Level'),
                _buildInfoRow(context, Icons.calendar_today, 'Semester', course.semester),
              ],
              1,
            ),
            const SizedBox(height: 20),
          ],
          _buildSection(
            context,
            'Enrollment Details',
            Icons.info_outline,
            [
              _buildInfoRow(
                context,
                Icons.access_time,
                'Enrolled On',
                DateFormat('MMMM dd, yyyy').format(widget.enrollment.enrolledAt),
              ),
              _buildInfoRow(
                context,
                Icons.access_time,
                'Enrolled At',
                DateFormat('hh:mm a').format(widget.enrollment.enrolledAt),
              ),
            ],
            2,
          ),
          const SizedBox(height: 20),
          _buildProgressSection(context),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (200 + (index * 100)).ms, duration: 600.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, size: 20, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Course Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingProgress)
            const Center(
              child: SmallLoadingIndicator(),
            )
          else if (_progress != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Completion',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${_progress!.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(_progress!),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress! / 100,
                minHeight: 10,
                backgroundColor: AppTheme.cardDark,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(_progress!),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getProgressStatus(_progress!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Color _getProgressColor(double progress) {
    if (progress >= 80) {
      return AppTheme.success;
    } else if (progress >= 50) {
      return AppTheme.warning;
    } else {
      return AppTheme.error;
    }
  }

  String _getProgressStatus(double progress) {
    if (progress >= 100) {
      return 'Completed all units';
    } else if (progress >= 80) {
      return 'Almost done!';
    } else if (progress >= 50) {
      return 'Making good progress';
    } else if (progress > 0) {
      return 'Just getting started';
    } else {
      return 'Not started yet';
    }
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              label: 'Close',
              onPressed: () => Navigator.pop(context),
              type: ButtonType.outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomButton(
              label: 'Disenroll',
              onPressed: () {
                Navigator.pop(context);
                widget.onDisenroll();
              },
              type: ButtonType.primary,
              icon: const Icon(Icons.person_remove, size: 20),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 800.ms, duration: 600.ms)
        .slideY(begin: 0.3, end: 0);
  }
}