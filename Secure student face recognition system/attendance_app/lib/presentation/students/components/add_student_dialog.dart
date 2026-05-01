import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/group.dart';
import '../../../providers/app_providers.dart';
import 'face_capture_dialog.dart';

class AddStudentDialog extends ConsumerStatefulWidget {
  const AddStudentDialog({super.key});
  @override
  ConsumerState<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends ConsumerState<AddStudentDialog> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _sidCtrl = TextEditingController();
  String? _selectedGroupId;
  bool _saving = false;

  Future<void> _save() async {
    if (_firstCtrl.text.trim().isEmpty || _lastCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final repo = ref.read(studentRepoProvider);
    final groupRepo = ref.read(groupRepoProvider);

    final student = await repo.create(
      firstName: _firstCtrl.text.trim(),
      lastName: _lastCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      studentId: _sidCtrl.text.trim().isEmpty ? null : _sidCtrl.text.trim(),
    );

    if (_selectedGroupId != null) {
      await groupRepo.addStudent(_selectedGroupId!, student.id);
      ref.invalidate(groupsProvider);
    }

    ref.invalidate(studentsProvider);

    if (mounted) {
      Navigator.pop(context); // Close add dialog
      
      // Immediately offer to take a picture
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => FaceCaptureDialog(student: student),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return AlertDialog(
      title: const Text('Add Student'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _firstCtrl,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  autofocus: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _lastCtrl,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sidCtrl,
              decoration: const InputDecoration(labelText: 'Student ID (optional)'),
            ),
            const SizedBox(height: 16),
            groupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Text('Error loading groups'),
              data: (groups) {
                if (groups.isEmpty) return const SizedBox.shrink();
                
                final items = [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...groups.map((g) => DropdownMenuItem(
                        value: (g as Group).id,
                        child: Text(g.name),
                      )),
                ];

                return DropdownButtonFormField<String>(
                  value: _selectedGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Assign to Group (Optional)',
                    prefixIcon: Icon(Icons.groups_rounded),
                  ),
                  items: items,
                  onChanged: (v) => setState(() => _selectedGroupId = v),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add & Continue to Photo'),
        ),
      ],
    );
  }
}
