import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/app_theme.dart';
import '../../../widgets/responsive_builder.dart';

class EnrollmentStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const EnrollmentStatsWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enrollment Analytics',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideX(begin: -0.2, end: 0),
        const SizedBox(height: 8),
        Text(
          'Overview of student enrollments across your courses',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideX(begin: -0.2, end: 0),
        const SizedBox(height: 32),
        _buildOverviewCards(context),
        const SizedBox(height: 32),
        _buildMostEnrolledCourse(context),
        const SizedBox(height: 32),
        _buildEnrollmentsByCourse(context),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(duration: 2.seconds),
          const SizedBox(height: 24),
          Text(
            'No Analytics Available',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Analytics will appear once students enroll in your courses.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context) {
    final totalEnrollments = stats['totalEnrollments'] ?? 0;
    final totalCourses = stats['totalCourses'] ?? 0;
    final averageEnrollments = stats['averageEnrollmentsPerCourse'] ?? 0.0;
    final recentEnrollments = stats['recentEnrollments'] ?? 0;

    return ResponsiveBuilder(
      builder: (context, deviceType) {
        if (deviceType == DeviceType.mobile) {
          return Column(
            children: [
              _buildStatCard(
                context,
                'Total Enrollments',
                totalEnrollments.toString(),
                Icons.people,
                AppTheme.primaryBlue,
                0,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                context,
                'Total Courses',
                totalCourses.toString(),
                Icons.book,
                AppTheme.success,
                1,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                context,
                'Average per Course',
                averageEnrollments.toStringAsFixed(1),
                Icons.trending_up,
                AppTheme.warning,
                2,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                context,
                'Recent (7 days)',
                recentEnrollments.toString(),
                Icons.schedule,
                AppTheme.info,
                3,
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Enrollments',
                  totalEnrollments.toString(),
                  Icons.people,
                  AppTheme.primaryBlue,
                  0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Courses',
                  totalCourses.toString(),
                  Icons.book,
                  AppTheme.success,
                  1,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Average per Course',
                  averageEnrollments.toStringAsFixed(1),
                  Icons.trending_up,
                  AppTheme.warning,
                  2,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Recent (7 days)',
                  recentEnrollments.toString(),
                  Icons.schedule,
                  AppTheme.info,
                  3,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (400 + (index * 100)).ms, duration: 600.ms)
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildMostEnrolledCourse(BuildContext context) {
    final mostEnrolledCourseTitle = stats['mostEnrolledCourseTitle'];
    final maxEnrollments = stats['maxEnrollments'] ?? 0;

    if (mostEnrolledCourseTitle == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.star,
              color: AppTheme.primaryBlue,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Most Enrolled Course',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  mostEnrolledCourseTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.people,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$maxEnrollments ${maxEnrollments == 1 ? "student" : "students"}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 800.ms, duration: 600.ms)
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildEnrollmentsByCourse(BuildContext context) {
    final enrollmentsPerCourse = stats['enrollmentsPerCourse'] as Map<String, dynamic>?;
    final courseTitles = stats['courseTitles'] as Map<String, dynamic>?;

    if (enrollmentsPerCourse == null || 
        courseTitles == null || 
        enrollmentsPerCourse.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort courses by enrollment count
    final sortedCourses = enrollmentsPerCourse.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enrollments by Course',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        )
            .animate()
            .fadeIn(delay: 1000.ms, duration: 600.ms)
            .slideX(begin: -0.2, end: 0),
        const SizedBox(height: 16),
        ...sortedCourses.asMap().entries.map((entry) {
          final index = entry.key;
          final courseEntry = entry.value;
          final courseId = courseEntry.key;
          final count = courseEntry.value as int;
          final title = courseTitles[courseId] as String?;

          if (title == null) return const SizedBox.shrink();

          return _buildCourseEnrollmentBar(
            context,
            title,
            count,
            sortedCourses.first.value as int,
            index,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCourseEnrollmentBar(
    BuildContext context,
    String courseTitle,
    int count,
    int maxCount,
    int index,
  ) {
    final percentage = maxCount > 0 ? (count / maxCount) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  courseTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: AppTheme.cardDark,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (1200 + (index * 100)).ms, duration: 600.ms)
        .slideX(begin: -0.2, end: 0);
  }
}