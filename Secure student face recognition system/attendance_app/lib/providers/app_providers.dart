import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database/app_database.dart';
import '../data/repositories/student_repository.dart';
import '../data/repositories/group_repository.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/ai_engine_service.dart';
import '../data/services/recognition_api.dart';
import '../data/repositories/teaching_assignment_repository.dart';
import '../data/repositories/semester_repository.dart';
import '../data/repositories/module_repository.dart';
import '../data/database/app_database.dart';

// ── Database ───────────────────────────────────────────────
final databaseProvider = Provider<AppDatabase>((_) => AppDatabase());

// ── Repositories ───────────────────────────────────────────
final studentRepoProvider = Provider<StudentRepository>(
    (ref) => StudentRepository(ref.watch(databaseProvider)));

final groupRepoProvider = Provider<GroupRepository>(
    (ref) => GroupRepository(ref.watch(databaseProvider)));

final attendanceRepoProvider = Provider<AttendanceRepository>(
    (ref) => AttendanceRepository(ref.watch(databaseProvider)));

final authRepoProvider = Provider<AuthRepository>(
    (ref) => AuthRepository(ref.watch(databaseProvider)));

final teachingAssignmentRepoProvider = Provider<TeachingAssignmentRepository>(
    (ref) => TeachingAssignmentRepository(ref.watch(databaseProvider)));

final moduleRepoProvider = Provider<ModuleRepository>(
    (ref) => ModuleRepository(ref.watch(databaseProvider)));

// ── Services ───────────────────────────────────────────────
final aiEngineServiceProvider =
    Provider<AiEngineService>((_) => AiEngineService());

final recognitionApiProvider =
    Provider<RecognitionApi>((_) => RecognitionApi());

// ── Theme ──────────────────────────────────────────────────
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
        (_) => ThemeModeNotifier());

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('theme_mode');
    if (v == 'light') state = ThemeMode.light;
    if (v == 'dark') state = ThemeMode.dark;
  }

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', state.name);
  }
}

// ── Auth state ─────────────────────────────────────────────
final isLoggedInProvider = StateProvider<bool>((_) => false);
final currentTeacherProvider = StateProvider<String?>((_) => null);

// ── AI Engine status ───────────────────────────────────────
enum AiStatus { stopped, starting, running, error }

final aiStatusProvider = StateProvider<AiStatus>((_) => AiStatus.stopped);

// ── Students ───────────────────────────────────────────────
final studentsProvider =
    FutureProvider<List>((ref) async {
  final repo = ref.watch(studentRepoProvider);
  return repo.getAll();
});

final groupStudentsProvider =
    FutureProvider.family<List, String>((ref, groupId) async {
  final repo = ref.watch(studentRepoProvider);
  return repo.getByGroup(groupId);
});

// ── Groups ─────────────────────────────────────────────────
final groupsProvider =
    FutureProvider<List>((ref) async {
  final repo = ref.watch(groupRepoProvider);
  return repo.getAll();
});

// ── Sessions ───────────────────────────────────────────────
final sessionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(attendanceRepoProvider);
  final result = await repo.getRecentSessionsWithDetails(limit: 5);
  return result;
});