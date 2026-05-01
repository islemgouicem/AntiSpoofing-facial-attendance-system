import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../providers/semester_provider.dart';
import '../shared/common_widgets.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final aiStatus = ref.watch(aiStatusProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const PageHeader(title: 'Settings', subtitle: 'Application configuration'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  // ── Appearance ──
                  _Section(title: 'Appearance', children: [
                    _SettingsTile(
                      icon: Icons.dark_mode_rounded,
                      title: 'Dark Mode',
                      subtitle: themeMode == ThemeMode.dark ? 'Enabled' : 'Disabled',
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (_) =>
                            ref.read(themeModeProvider.notifier).toggle(),
                        activeColor: AppColors.primary,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Academic Management ──
                  _Section(title: 'Academic Management', children: [
                    _SettingsTile(
                      icon: Icons.auto_awesome_motion_rounded,
                      title: 'Current Semester',
                      subtitle: 'Reset and start a new academic period',
                      trailing: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _confirmNewSemester(context, ref),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: const Text('Start New Semester'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── AI engine ──
                  _Section(title: 'AI Engine', children: [
                    _SettingsTile(
                      icon: Icons.memory_rounded,
                      title: 'Engine Status',
                      subtitle: aiStatus.name.toUpperCase(),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (aiStatus == AiStatus.running ? AppColors.success : AppColors.error).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          aiStatus == AiStatus.running ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            color: aiStatus == AiStatus.running ? AppColors.success : AppColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── About ──
                  _Section(title: 'About', children: [
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'FaceAttend',
                      subtitle: 'Version 1.0.0 • Face Recognition Attendance System',
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmNewSemester(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start New Semester?'),
        content: const Text(
          'This will close the current academic period and allow you to set up a new one. All existing attendance records will be preserved in the archive.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Start New'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(currentSemesterProvider.notifier).reset();
      if (context.mounted) {
        context.go('/semester-setup');
      }
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            )),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing,
    );
  }
}
