import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/semester.dart';
import 'app_providers.dart';
import '../data/repositories/semester_repository.dart';

final semesterRepoProvider = Provider<SemesterRepository>(
    (ref) => SemesterRepository(ref.watch(databaseProvider)));

final currentSemesterProvider = StateNotifierProvider<CurrentSemesterNotifier, AsyncValue<Semester?>>(
    (ref) => CurrentSemesterNotifier(ref.watch(semesterRepoProvider)));

class CurrentSemesterNotifier extends StateNotifier<AsyncValue<Semester?>> {
  final SemesterRepository _repo;

  CurrentSemesterNotifier(this._repo) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final semester = await _repo.getActive();
      state = AsyncValue.data(semester);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createSemester(String name, String teacherId) async {
    final semester = Semester(name: name, teacherId: teacherId, isActive: true);
    await _repo.insert(semester);
    await _repo.setActive(semester.id);
    await refresh();
  }

  Future<void> reset() async {
    state = const AsyncValue.data(null);
  }
}
