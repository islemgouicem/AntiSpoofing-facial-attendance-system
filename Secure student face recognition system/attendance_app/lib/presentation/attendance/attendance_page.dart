import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/group.dart';
import '../../providers/app_providers.dart';
import '../shared/common_widgets.dart';

/// Attendance setup page — select group, start session.
import '../../domain/models/teaching_assignment.dart';
import '../../providers/semester_provider.dart';

/// Attendance setup page — select group, start session.
class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});
  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {



  @override
  Widget build(BuildContext context) {
    final semesterAsync = ref.watch(currentSemesterProvider);

  // END DEBUG
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        
        children: [
          const PageHeader(
            title: 'Attendance Tracking',
            subtitle: 'Select a module assignment to view and track attendance',
          ),
          Expanded(
            child: semesterAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (semester) {
                if (semester == null) return const Center(child: Text('Please set up a semester first.'));
                return FutureBuilder(
                  future: ref.read(teachingAssignmentRepoProvider).getAll(semester.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) return Center(child: Text('Error loading assignments: ${snapshot.error}'));

                    final assignments = snapshot.data as List<TeachingAssignment>;
                    if (assignments.isEmpty) {
                      return const EmptyState(
                        icon: Icons.assignment_outlined,
                        message: 'No modules assigned for this semester yet.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      itemCount: assignments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) {
                        final a = assignments[i];
                        return _AssignmentCard(
                          assignment: a,
                          onTap: () => context.go('/attendance/matrix/${a.id}'),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends ConsumerWidget {
  final TeachingAssignment assignment;
  final VoidCallback onTap;

  const _AssignmentCard({required this.assignment, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // TODO: Ideally we'd have a provider that joins Module Name and Group Name
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.book_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(assignment.moduleName ?? 'Unknown Module',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Level: ${assignment.sessionType} • Group: ${assignment.groupName ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      )),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
