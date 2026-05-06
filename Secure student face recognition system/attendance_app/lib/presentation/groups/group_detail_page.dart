import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/group.dart';
import '../../domain/models/student.dart';
import '../../providers/app_providers.dart';
import '../shared/common_widgets.dart';

class GroupDetailPage extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailPage({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  void _showAddStudentDialog() {
    final firstCtrl = TextEditingController();
    final lastCtrl = TextEditingController();
    final idCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Student to Group'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: firstCtrl, decoration: const InputDecoration(labelText: 'First Name')),
          const SizedBox(height: 12),
          TextField(controller: lastCtrl, decoration: const InputDecoration(labelText: 'Last Name')),
          const SizedBox(height: 12),
          TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Student ID / Number')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (firstCtrl.text.isEmpty || lastCtrl.text.isEmpty) return;
              final studentRepo = ref.read(studentRepoProvider);
              final groupRepo = ref.read(groupRepoProvider);
              
              // 1. Create student
              final student = await studentRepo.create(
                firstName: firstCtrl.text.trim(),
                lastName: lastCtrl.text.trim(),
                studentId: idCtrl.text.trim(),
              );
              
              // 2. Add to group
              await groupRepo.addStudent(widget.groupId, student.id);
              
              ref.invalidate(groupStudentsProvider(widget.groupId));
              ref.invalidate(groupsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupAsync = ref.watch(groupsProvider).whenData(
        (list) => list.cast<Group>().firstWhere((g) => g.id == widget.groupId));
    final studentsAsync = ref.watch(groupStudentsProvider(widget.groupId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          groupAsync.when(
            data: (g) => PageHeader(
              title: '${g.academicYear} / ${g.name}',
              subtitle: 'Managing enrolled students',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => {
                      if (context.canPop()) {
                          context.pop()
                        } else {
                          context.go('/groups') // fallback
                        }
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddStudentDialog,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Add Student'),
                  ),
                ],
              ),
            ),
            loading: () => const PageHeader(title: 'Loading...', subtitle: ''),
            error: (_, __) => const PageHeader(title: 'Error', subtitle: ''),
          ),
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (students) {
                if (students.isEmpty) {
                  return const EmptyState(
                    icon: Icons.person_off_rounded,
                    message: 'No students in this group yet.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(32),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final s = students[i] as Student;
                    return Card(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(s.firstName[0], style: const TextStyle(color: AppColors.primary)),
                        ),
                        title: Text('${s.firstName} ${s.lastName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('ID: ${s.studentId ?? 'N/A'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                s.faceRegistered ? Icons.face_retouching_natural_rounded : Icons.face_rounded,
                                color: s.faceRegistered ? AppColors.success : AppColors.darkTextTertiary,
                              ),
                              tooltip: s.faceRegistered ? 'Face Registered' : 'Register Face',
                              onPressed: () => context.push('/register-face/${s.id}/${s.firstName} ${s.lastName}').then((_) => ref.invalidate(groupStudentsProvider(widget.groupId))),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                              tooltip: 'Remove from group',
                              onPressed: () async {
                                await ref.read(groupRepoProvider).removeStudent(widget.groupId, s.id);
                                ref.invalidate(groupStudentsProvider(widget.groupId));
                                ref.invalidate(groupsProvider);
                              },
                            ),
                          ],
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
