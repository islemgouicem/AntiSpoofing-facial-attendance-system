import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/module.dart';
import '../../domain/models/teaching_assignment.dart';
import '../../domain/models/group.dart';
import '../../providers/app_providers.dart';
import '../../providers/semester_provider.dart';
import '../shared/common_widgets.dart';

class SemesterSetupPage extends ConsumerStatefulWidget {
  const SemesterSetupPage({super.key});

  @override
  ConsumerState<SemesterSetupPage> createState() => _SemesterSetupPageState();
}

class _SemesterSetupPageState extends ConsumerState<SemesterSetupPage> {
  int _currentStep = 0;
  final _semesterNameCtrl = TextEditingController();
  final List<Group> _availableGroups = [];
  final List<Module> _modules = [];
  final Map<String, List<String>> _moduleGroups = {}; // ModuleId -> List of GroupIds

  void _addModule() {
  final nameCtrl = TextEditingController();
  final yearCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add Module'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Module Name (e.g. Algorithms)')),
        const SizedBox(height: 12),
        TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'Academic Year (e.g. Year 2)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (nameCtrl.text.isEmpty || yearCtrl.text.isEmpty) return;
            setState(() {
              // Generate ID here so _moduleGroups keying works correctly
              _modules.add(Module(
                id: const Uuid().v4(), // ← THIS WAS MISSING
                name: nameCtrl.text,
                academicYear: yearCtrl.text,
              ));
            });
            Navigator.pop(ctx);
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
  Future<void> _finishSetup() async {
    if (_semesterNameCtrl.text.trim().isEmpty) return;

    final teacherId = ref.read(currentTeacherProvider) ?? 'admin';
    final notifier = ref.read(currentSemesterProvider.notifier);

    await notifier.createSemester(_semesterNameCtrl.text.trim(), teacherId);
    final semester = ref.read(currentSemesterProvider).value;
    if (semester == null) return;

    final moduleRepo = ref.read(moduleRepoProvider);
    final assignmentRepo = ref.read(teachingAssignmentRepoProvider);
    final groupRepo = ref.read(groupRepoProvider);

    // 1. Persist groups first
    for (final group in _availableGroups) {
      await groupRepo.create(
        id: group.id,
        name: group.name,
        academicYear: group.academicYear,
      );
    }

    // 2. Persist modules + assignments
    for (final module in _modules) {
      await moduleRepo.insert(module);
      final groupIds = _moduleGroups[module.id] ?? [];
      for (final gid in groupIds) {
        await assignmentRepo.insert(TeachingAssignment(
          id: const Uuid().v4(),
          semesterId: semester.id,
          moduleId: module.id,
          groupId: gid,
          sessionType: 'Tutorial',
        ));
      }
    }

    if (mounted) context.go('/');
  }
  
 
  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      body: Center(
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 64, color: AppColors.primary),
                const SizedBox(height: 24),
                Text('Welcome to FaceAttend', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Let\'s set up your current academic semester.'),
                const SizedBox(height: 48),

                if (_currentStep == 0) ...[
                  TextField(
                    controller: _semesterNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Semester Name',
                      hintText: 'e.g. Fall 2024 / Semester 1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() => _currentStep = 1),
                    child: const Text('Next: Add Modules'),
                  ),
                ],

                if (_currentStep == 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Modules you teach:', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(onPressed: _addModule, icon: const Icon(Icons.add), label: const Text('Add Module')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _modules.length,
                    itemBuilder: (context, i) {
                      final m = _modules[i];
                      return ListTile(
                        title: Text(m.name),
                        subtitle: Text(m.academicYear),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setState(() => _modules.removeAt(i)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _modules.isEmpty ? null : () => setState(() => _currentStep = 2),
                    child: const Text('Next: Assign Groups'),
                  ),
                ],

                if (_currentStep == 2) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Assign Groups to Modules:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _addGroup,
                        icon: const Icon(Icons.group_add),
                        label: const Text('Create Group'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Created groups pool
                  if (_availableGroups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No groups yet. Create one above.',
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableGroups.map((g) => Chip(
                        label: Text('${g.name} (${g.academicYear})'),
                        avatar: const Icon(Icons.group, size: 16),
                      )).toList(),
                    ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Module → group assignment
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _modules.length,
                    itemBuilder: (context, i) {
                      final m = _modules[i];
                      return ExpansionTile(
                        title: Text(m.name),
                        subtitle: Text('${_moduleGroups[m.id]?.length ?? 0} groups assigned'),
                        leading: (_moduleGroups[m.id]?.isNotEmpty ?? false)
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
                            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                        children: _availableGroups.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('Create groups above to assign them here.',
                                      style: TextStyle(color: Colors.grey)),
                                )
                              ]
                            : _availableGroups.map((g) {
                                final isAssigned =
                                    _moduleGroups[m.id]?.contains(g.id) ?? false;
                                return CheckboxListTile(
                                  title: Text(g.name),
                                  subtitle: Text(g.academicYear),
                                  value: isAssigned,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val!) {
                                        _moduleGroups.putIfAbsent(m.id, () => []).add(g.id);
                                      } else {
                                        _moduleGroups[m.id]?.remove(g.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _finishSetup,
                    child: const Text('Finish Setup'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addGroup() {
  final nameCtrl = TextEditingController();
  final yearCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Create Group'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Group Name (e.g. Group A)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: yearCtrl,
          decoration: const InputDecoration(
            labelText: 'Academic Year (e.g. Year 2)',
            border: OutlineInputBorder(),
          ),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
       ElevatedButton(
        onPressed: () async {
          if (nameCtrl.text.isEmpty || yearCtrl.text.isEmpty) return;
          
          // Generate ONE id for everything
          final id = const Uuid().v4();
          final group = Group(
            id: id,
            name: nameCtrl.text.trim(),
            academicYear: yearCtrl.text.trim(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final repo = ref.read(groupRepoProvider);
          await repo.create(
            id: group.id,
            name: group.name,
            academicYear: group.academicYear,
          );
          ref.invalidate(groupsProvider);

          setState(() {
            _availableGroups.add(group);
          });

          Navigator.pop(ctx);
        },
        child: const Text('Create'),
      ),
      ],
    ),
  );
}
}
