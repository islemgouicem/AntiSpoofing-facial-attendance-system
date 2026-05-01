import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';

/// Persistent sidebar navigation for the main shell.
class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  static const _items = <_NavItem>[
    _NavItem('/', Icons.dashboard_rounded, 'Dashboard'),
    _NavItem('/groups', Icons.groups_rounded, 'Groups'),
    _NavItem('/attendance', Icons.fact_check_rounded, 'Attendance'),
    _NavItem('/reports', Icons.bar_chart_rounded, 'Reports'),
    _NavItem('/settings', Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPath = GoRouterState.of(context).uri.toString();

    return Container(
      width: AppConstants.sidebarWidth,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSidebar : AppColors.lightSidebar,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // ── Brand ──────────────────────────
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.face_retouching_natural,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'FaceAttend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Navigation ─────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final item = _items[i];
                final isActive = currentPath == item.path ||
                    (item.path != '/' && currentPath.startsWith(item.path));
                return _SidebarItem(item: item, isActive: isActive);
              },
            ),
          ),

          // ── Start attendance CTA ───────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/attendance'),
                icon: const Icon(Icons.videocam_rounded, size: 18),
                label: const Text('Start Session'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
          
          // ── Logout ───────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: () {
                // Clear simple auth state
                ref.read(isLoggedInProvider.notifier).state = false;
                ref.read(currentTeacherProvider.notifier).state = null;
                context.go('/login');
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
                    const SizedBox(width: 12),
                    const Text('Logout', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.error
                    )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final String label;
  const _NavItem(this.path, this.icon, this.label);
}

class _SidebarItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  const _SidebarItem({required this.item, required this.isActive});

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = widget.isActive;

    Color bgColor = Colors.transparent;
    if (active) {
      bgColor = AppColors.primary.withOpacity(0.12);
    } else if (_hovered) {
      bgColor = isDark ? AppColors.darkCardHover : AppColors.lightCardHover;
    }

    final fgColor = active
        ? AppColors.primary
        : isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => context.go(widget.item.path),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(widget.item.icon, size: 20, color: fgColor),
                const SizedBox(width: 12),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
