import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/academic_session.dart';
import '../../domain/models/attendance_record.dart';
import '../../providers/app_providers.dart';
import '../../providers/semester_provider.dart';
import '../shared/common_widgets.dart';

class AttendanceMatrixPage extends ConsumerStatefulWidget {
  final String assignmentId;
  const AttendanceMatrixPage({super.key, required this.assignmentId});

  @override
  ConsumerState<AttendanceMatrixPage> createState() => _AttendanceMatrixPageState();
}

class _AttendanceMatrixPageState extends ConsumerState<AttendanceMatrixPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 1. Load Sessions for this assignment
    final sessionsFuture = ref.watch(attendanceRepoProvider).getSessionsForAssignment(widget.assignmentId);
    
    // 2. Load Matrix Data
    final matrixFuture = ref.watch(attendanceRepoProvider).getAttendanceMatrix(widget.assignmentId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
        future: Future.wait([sessionsFuture, matrixFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final sessions = snapshot.data![0] as List<AcademicSession>;
          final matrix = snapshot.data![1] as Map<String, Map<String, AttendanceRecord>>;

          // Get group students to ensure everyone is listed even if no records exist
          // TODO: Load students for group from repo

          return Column(
            children: [
              PageHeader(
                title: 'Attendance Matrix',
                subtitle: 'Track presence across all sessions',
                trailing: ElevatedButton.icon(
                  onPressed: () => _createNewSession(sessions.length + 1),
                  icon: const Icon(Icons.add),
                  label: Text('Add Session (S${sessions.length + 1})'),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          columns: [
                            const DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            ...sessions.map((s) => DataColumn(
                              label: InkWell(
                                onTap: () => _onSessionClick(s),
                                child: Text('S${s.sessionNumber}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                            )),
                          ],
                          rows: matrix.entries.map((entry) {
                            final studentId = entry.key;
                            final recordMap = entry.value;
                            final studentName = recordMap.values.first.studentName ?? 'Student';

                            return DataRow(
                              cells: [
                                DataCell(Text(studentName)),
                                ...sessions.map((s) {
                                  final record = recordMap[s.id];
                                  return DataCell(_AttendanceCell(
                                    status: record?.status ?? AttendanceStatus.absent,
                                    onChanged: (newStatus) => _updateStatus(s.id, studentId, newStatus),
                                  ));
                                }),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _createNewSession(int number) async {
    final repo = ref.read(attendanceRepoProvider);
    final session = await repo.createSession(assignmentId: widget.assignmentId, sessionNumber: number);
    if (mounted) {
      context.go('/attendance/live/${session.id}');
    }
  }

  void _onSessionClick(AcademicSession session) {
    if (session.status == SessionStatus.completed) {
      // Show summary or allow restart
    } else {
      context.go('/attendance/live/${session.id}');
    }
  }

  void _updateStatus(String sessionId, String studentId, AttendanceStatus status) async {
    await ref.read(attendanceRepoProvider).updateRecordStatus(sessionId, studentId, status);
    setState(() {}); // Refresh matrix
  }
}

class _AttendanceCell extends StatelessWidget {
  final AttendanceStatus status;
  final Function(AttendanceStatus) onChanged;

  const _AttendanceCell({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case AttendanceStatus.present:
      case AttendanceStatus.manual_present:
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
      case AttendanceStatus.absent:
      case AttendanceStatus.manual_absent:
        color = AppColors.error;
        icon = Icons.cancel_rounded;
    }

    return InkWell(
      onTap: () {
        // Toggle status manually
        final next = (status == AttendanceStatus.present || status == AttendanceStatus.manual_present)
            ? AttendanceStatus.manual_absent
            : AttendanceStatus.manual_present;
        onChanged(next);
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
