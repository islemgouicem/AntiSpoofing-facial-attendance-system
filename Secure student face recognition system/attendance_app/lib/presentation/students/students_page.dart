import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../domain/models/student.dart';
import '../shared/common_widgets.dart';
import 'components/add_student_dialog.dart';

class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key});
  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  String _search = '';

  void _showAddDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AddStudentDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          PageHeader(
            title: 'Students',
            subtitle: 'Manage student profiles and face data',
            trailing: ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Student'),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          // Student list
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (students) {
                final list = (students as List<Student>).where((s) {
                  if (_search.isEmpty) return true;
                  final q = _search.toLowerCase();
                  return s.fullName.toLowerCase().contains(q) ||
                      (s.studentId?.toLowerCase().contains(q) ?? false);
                }).toList();

                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline_rounded,
                    message: 'No students found.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _StudentTile(
                    student: list[i],
                    onDelete: () async {
                      final repo = ref.read(studentRepoProvider);
                      await repo.delete(list[i].id);
                      ref.invalidate(studentsProvider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatefulWidget {
  final Student student;
  final VoidCallback onDelete;
  const _StudentTile({required this.student, required this.onDelete});
  @override
  State<_StudentTile> createState() => _StudentTileState();
}

class _StudentTileState extends State<_StudentTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.student;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _hovered
              ? (isDark ? AppColors.darkCardHover : AppColors.lightCardHover)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(s.initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  )),
            ),
            const SizedBox(width: 16),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (s.studentId != null)
                    Text(s.studentId!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        )),
                ],
              ),
            ),
            // Face status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: s.faceRegistered
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.darkTextTertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                s.faceRegistered ? 'FACE OK' : 'NO FACE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: s.faceRegistered ? AppColors.success : AppColors.darkTextTertiary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Delete
            if (_hovered)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                onPressed: widget.onDelete,
                tooltip: 'Delete student',
              ),
          ],
        ),
      ),
    );
  }
}
