import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/auth/login_page.dart';
import '../../presentation/dashboard/dashboard_page.dart';
import '../../presentation/students/students_page.dart';
import '../../presentation/students/student_detail_page.dart';
import '../../presentation/groups/groups_page.dart';
import '../../presentation/groups/group_detail_page.dart';
import '../../presentation/attendance/attendance_page.dart';
import '../../presentation/attendance/live_session_page.dart';
import '../../presentation/reports/reports_page.dart';
import '../../presentation/students/face_registration_page.dart';
import '../../presentation/settings/settings_page.dart';
import '../../presentation/semester/semester_setup_page.dart';
import '../../presentation/attendance/attendance_matrix_page.dart';
import '../../presentation/shared/app_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginPage(),
    ),
    ShellRoute(
      builder: (_, state, child) => AppScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (_, __) => const NoTransitionPage(child: DashboardPage()),
        ),
        GoRoute(
          path: '/semester-setup',
          pageBuilder: (_, __) => const NoTransitionPage(child: SemesterSetupPage()),
        ),
        GoRoute(
          path: '/groups',
          pageBuilder: (_, __) => const NoTransitionPage(child: GroupsPage()),
        ),
        GoRoute(
          path: '/groups/:id',
          builder: (_, state) =>
              GroupDetailPage(groupId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/attendance',
          pageBuilder: (_, __) => const NoTransitionPage(child: AttendancePage()),
        ),
        GoRoute(
          path: '/attendance/matrix/:assignmentId',
          builder: (_, state) =>
              AttendanceMatrixPage(assignmentId: state.pathParameters['assignmentId']!),
        ),
        GoRoute(
          path: '/attendance/live/:sessionId',
          builder: (_, state) =>
              LiveSessionPage(sessionId: state.pathParameters['sessionId']!),
        ),
        GoRoute(
          path: '/register-face/:studentId/:studentName',
          builder: (_, state) => FaceRegistrationPage(
            studentId: state.pathParameters['studentId']!,
            studentName: state.pathParameters['studentName']!,
          ),
        ),
        GoRoute(
          path: '/reports',
          pageBuilder: (_, __) => const NoTransitionPage(child: ReportsPage()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (_, __) => const NoTransitionPage(child: SettingsPage()),
        ),
      ],
    ),
  ],
);
