import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
                _modules.add(Module(name: nameCtrl.text, academicYear: yearCtrl.text));
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
    final teacherId = ref.read(currentTeacherProvider) ?? 'admin';
    final notifier = ref.read(currentSemesterProvider.notifier);
    
    // 1. Create Semester
    await notifier.createSemester(_semesterNameCtrl.text, teacherId);
    final semester = ref.read(currentSemesterProvider).value;
    if (semester == null) return;

    // 2. Create Modules & Assignments
    final moduleRepo = ref.read(moduleRepoProvider);
    final assignmentRepo = ref.read(teachingAssignmentRepoProvider);

    for (final module in _modules) {
      await moduleRepo.insert(module);
      final groupIds = _moduleGroups[module.id] ?? [];
      for (final gid in groupIds) {
        await assignmentRepo.insert(TeachingAssignment(
          semesterId: semester.id,
          moduleId: module.id,
          groupId: gid,
          sessionType: 'Tutorial', // Default, can be refined
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
                  const Text('Assign groups to your modules:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  groupsAsync.when(
                    data: (groups) => ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _modules.length,
                      itemBuilder: (context, i) {
                        final m = _modules[i];
                        final filteredGroups = groups.where((g) => g.academicYear == m.academicYear).toList();
                        
                        return ExpansionTile(
                          title: Text(m.name),
                          subtitle: Text('${_moduleGroups[m.id]?.length ?? 0} groups assigned'),
                          children: filteredGroups.map((g) {
                            final isAssigned = _moduleGroups[m.id]?.contains(g.id) ?? false;
                            return CheckboxListTile(
                              title: Text(g.name),
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
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error loading groups'),
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
}
