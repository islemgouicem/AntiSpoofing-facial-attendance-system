import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/group.dart';
import '../../providers/app_providers.dart';
import '../shared/common_widgets.dart';

class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});
  @override
  ConsumerState<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends ConsumerState<GroupsPage> {
  void _showAddDialog() {
    final nameCtrl = TextEditingController(); // e.g. G1
    final yearCtrl = TextEditingController(); // e.g. Year 1

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Group'),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: yearCtrl,
              decoration: const InputDecoration(
                labelText: 'Academic Year',
                hintText: 'e.g. Year 1, Year 2',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g. G1, G2, G3',
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || yearCtrl.text.trim().isEmpty) return;
              final repo = ref.read(groupRepoProvider);
              await repo.create(
                name: nameCtrl.text.trim(),
                academicYear: yearCtrl.text.trim(),
              );
              ref.invalidate(groupsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          PageHeader(
            title: 'Groups',
            subtitle: 'Academic groups organized by year of study',
            trailing: ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Group'),
            ),
          ),
          Expanded(
            child: groupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (groups) {
                if (groups.isEmpty) {
                  return const EmptyState(
                    icon: Icons.groups_outlined,
                    message: 'No groups found. Start by creating a group for a specific year.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(32),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final g = groups[i] as Group;
                    return _GroupCard(
                      group: g,
                      onDelete: () async {
                        final repo = ref.read(groupRepoProvider);
                        await repo.delete(g.id);
                        ref.invalidate(groupsProvider);
                      },
                      onViewStudents: () {
                        // Navigate to students within this group
                        context.go('/groups/${g.id}');
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

class _GroupCard extends StatefulWidget {
  final Group group;
  final VoidCallback onDelete;
  final VoidCallback onViewStudents;
  const _GroupCard({
    required this.group,
    required this.onDelete,
    required this.onViewStudents,
  });
  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final g = widget.group;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _hovered
              ? (isDark ? AppColors.darkCardHover : AppColors.lightCardHover)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: _hovered ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 4)
            )
          ] : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Illustration
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.school_rounded,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 20),
            
            // Middle Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${g.academicYear} – ${g.name}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 6),
                  Text('${g.studentCount} students enrolled',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      )),
                ],
              ),
            ),
            
            // Action Buttons
            Row(
              children: [
                if (_hovered)
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: 'Delete Group',
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: widget.onViewStudents,
                  icon: const Icon(Icons.people_alt_rounded, size: 18),
                  label: const Text('Manage Students'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
