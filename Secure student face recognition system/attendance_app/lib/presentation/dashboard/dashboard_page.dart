import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/academic_session.dart';
import '../../providers/app_providers.dart';
import '../../providers/semester_provider.dart';
import '../shared/common_widgets.dart';
import '../shared/stat_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teacherName = ref.watch(currentTeacherProvider) ?? 'Teacher';
    final semesterAsync = ref.watch(currentSemesterProvider);

    // ── Semester Guard ──
    return semesterAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (semester) {
        if (semester == null) {
          // No active semester found, redirect to setup
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/semester-setup');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
           
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting ──
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Active Semester: ${semester.name}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              )),
                          const SizedBox(height: 2),
                          Text('Welcome back, $teacherName',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  )),
                        ],
                      ),
                    ),
                    _AiStatusBadge(),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Stats ──
                const SizedBox(
                  height: 150,
                  child: _StatsRow(),
                ),
                const SizedBox(height: 28),

                // ── Quick Actions ──
                Text('Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.videocam_rounded,
                      label: 'Start Attendance',
                      color: AppColors.primary,
                      onTap: () => context.go('/attendance'),
                    ),
                    const SizedBox(width: 14),
                    _QuickAction(
                      icon: Icons.groups_rounded,
                      label: 'Manage Groups',
                      color: AppColors.warning,
                      onTap: () => context.go('/groups'),
                    ),
                    const SizedBox(width: 14),
                    _QuickAction(
                      icon: Icons.assessment_rounded,
                      label: 'View Reports',
                      color: AppColors.info,
                      onTap: () => context.go('/reports'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Recent sessions ──
                Text('Recent Sessions (Current Assignment)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                const SizedBox(height: 14),
                _RecentSessions(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Stats Row ──────────────────────────────────────────────
class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);
    // TODO: Implement academic session broad count
    
    final groupCount = groupsAsync.valueOrNull?.length ?? 0;
    final engineRunning = ref.watch(aiEngineServiceProvider.select((s) => s.isRunning));

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'My Groups',
            value: '$groupCount',
            icon: Icons.groups_rounded,
            iconColor: AppColors.accent,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: StatCard(
            title: 'Target Year',
            value: groupCount > 0 ? (groupsAsync.valueOrNull?.first.academicYear ?? 'N/A') : 'N/A',
            icon: Icons.school_rounded,
            iconColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: StatCard(
            title: 'AI Engine',
            value: engineRunning ? 'Online' : 'Offline',
            icon: Icons.memory_rounded,
            iconColor: engineRunning ? AppColors.success : AppColors.error,
          ),
        ),
      ],
    );
  }
}

// ── Quick Action Card ──────────────────────────────────────
class _QuickAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withOpacity(0.08)
                  : (isDark ? AppColors.darkCard : AppColors.lightCard),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hovered
                    ? widget.color.withOpacity(0.3)
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Column(
              children: [
                Icon(widget.icon, color: widget.color, size: 28),
                const SizedBox(height: 10),
                Text(widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── AI Status Badge ─────────────────────────────────────────
class _AiStatusBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(aiStatusProvider);
    final Color color;
    final String label;

    switch (status) {
      case AiStatus.running:
        color = AppColors.success;
        label = 'AI Online';
      case AiStatus.starting:
        color = AppColors.warning;
        label = 'Starting...';
      case AiStatus.error:
        color = AppColors.error;
        label = 'AI Error';
      case AiStatus.stopped:
        color = AppColors.darkTextTertiary;
        label = 'AI Offline';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ── Recent Sessions ─────────────────────────────────────────
class _RecentSessions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Force refresh every time this widget builds
    Future.microtask(() => ref.invalidate(sessionsProvider));
  
    final sessionsAsync = ref.watch(sessionsProvider);
    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (sessions) {
        if (sessions.isEmpty) {
          return const EmptyState(
            icon: Icons.event_busy_rounded,
            message: 'No sessions yet. Start your first attendance session!',
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            itemBuilder: (context, i) {
              final s = sessions[i];
              final sessionNumber = s['session_number'] as int? ?? i + 1;
              final moduleName = s['module_name'] as String? ?? 'Unknown Module';
              final groupName = s['group_name'] as String? ?? 'Unknown Group';
              final statusStr = s['status'] as String? ?? 'pending';
              final status = SessionStatus.values.firstWhere(
                (e) => e.name == statusStr,
                orElse: () => SessionStatus.pending,
              );

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_rounded,
                      color: AppColors.primary, size: 20),
                ),
                title: Text(
                  'S$sessionNumber — $moduleName',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == SessionStatus.completed
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: status == SessionStatus.completed
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}