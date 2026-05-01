import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/academic_session.dart';
import '../../providers/app_providers.dart';
import '../../providers/semester_provider.dart';
import '../shared/common_widgets.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final semesterAsync = ref.watch(currentSemesterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const PageHeader(
            title: 'Academic Reports',
            subtitle: 'Historical session data and completion status',
          ),
          Expanded(
            child: semesterAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (semester) {
                if (semester == null) return const Center(child: Text('Set up a semester to see reports.'));

                return FutureBuilder(
                  future: ref.read(attendanceRepoProvider).getSessionsForAssignment('%'), // Load all for now
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                    final sessions = snapshot.data as List<AcademicSession>;
                    if (sessions.isEmpty) return const EmptyState(icon: Icons.bar_chart_rounded, message: 'No sessions recorded yet.');

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(isDark ? AppColors.darkSurface : AppColors.lightBg),
                          columns: const [
                            DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Assignment', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: sessions.map((s) => DataRow(cells: [
                            DataCell(Text('S${s.sessionNumber}')),
                            DataCell(Text(s.assignmentId.substring(0, 8))),
                            DataCell(Text(s.startedAt != null ? '${s.startedAt!.day}/${s.startedAt!.month}/${s.startedAt!.year}' : '—')),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: s.status == SessionStatus.completed
                                    ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(s.status.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: s.status == SessionStatus.completed ? AppColors.success : AppColors.warning)),
                            )),
                          ])).toList(),
                        ),
                      ),
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
