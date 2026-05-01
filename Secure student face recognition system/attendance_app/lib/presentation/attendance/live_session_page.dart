import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/recognition_result.dart';
import '../../domain/models/student.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/academic_session.dart';
import '../../providers/app_providers.dart';

class LiveSessionPage extends ConsumerStatefulWidget {
  final String sessionId;
  const LiveSessionPage({super.key, required this.sessionId});
  @override
  ConsumerState<LiveSessionPage> createState() => _LiveSessionPageState();
}

class _LiveSessionPageState extends ConsumerState<LiveSessionPage> {
  Timer? _frameTimer;
  Timer? _recognitionTimer;
  Timer? _clockTimer;
  Uint8List? _currentFrame;
  final List<_RecognizedEntry> _recognized = [];
  Duration _elapsed = Duration.zero;
  DateTime? _startTime;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _startSessionInDb();
    _startTimers();
  }

  Future<void> _startSessionInDb() async {
    await ref.read(attendanceRepoProvider).startSession(widget.sessionId);
  }

  void _startTimers() {
    _frameTimer = Timer.periodic(AppConstants.frameInterval, (_) => _fetchFrame());
    _recognitionTimer = Timer.periodic(AppConstants.recognitionInterval, (_) => _recognize());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null) {
        setState(() => _elapsed = DateTime.now().difference(_startTime!));
      }
    });
  }

  Future<void> _fetchFrame() async {
    final api = ref.read(recognitionApiProvider);
    final bytes = await api.getFrame();
    if (bytes != null && mounted) {
      setState(() => _currentFrame = Uint8List.fromList(bytes));
    }
  }

  Future<void> _recognize() async {
    if (!_active) return;
    final api = ref.read(recognitionApiProvider);
    final result = await api.recognize();
    
    if (result != null && result.recognized && result.name != null && mounted) {
      // Find student by name/id in DB
      final students = await ref.read(studentsProvider.future);
      final student = students.cast<Student?>().firstWhere(
        (s) => s?.firstName == result.name || '${s?.firstName} ${s?.lastName}' == result.name,
        orElse: () => null,
      );

      if (student == null) return;

      final alreadyLogged = _recognized.any((e) => e.studentId == student.id);
      if (!alreadyLogged) {
        // Persist to DB
        await ref.read(attendanceRepoProvider).updateRecordStatus(
          widget.sessionId,
          student.id,
          AttendanceStatus.present,
        );

        setState(() {
          _recognized.insert(0, _RecognizedEntry(
            studentId: student.id,
            name: '${student.firstName} ${student.lastName}',
            confidence: result.confidence ?? 0,
            time: DateTime.now(),
          ));
        });
      }
    }
  }

  void _stopSession() async {
    _active = false;
    _frameTimer?.cancel();
    _recognitionTimer?.cancel();
    _clockTimer?.cancel();
    
    await ref.read(attendanceRepoProvider).completeSession(widget.sessionId);
    
    if (mounted) {
      // Return to matrix view
      // We need to know the assignmentId to go back to the right matrix
      // For now, go back to dashboard or previous page
      context.pop();
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _recognitionTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Row(
        children: [
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: _stopSession,
                      ),
                      const SizedBox(width: 8),
                      Text('Live Attendance',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.fiber_manual_record,
                                color: AppColors.error, size: 10),
                            const SizedBox(width: 8),
                            Text(_formatDuration(_elapsed),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: Colors.black,
                        child: _currentFrame != null
                            ? Image.memory(_currentFrame!,
                                gaplessPlayback: true,
                                fit: BoxFit.contain,
                                width: double.infinity)
                            : const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(color: Colors.white54),
                                    SizedBox(height: 16),
                                    Text('Connecting to camera...',
                                        style: TextStyle(color: Colors.white54)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _stopSession,
                      icon: const Icon(Icons.stop_rounded, size: 24),
                      label: const Text('FINISH SESSION', style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 380,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                left: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const Icon(Icons.history_toggle_off_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text('Recent Log',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${_recognized.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            )),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                Expanded(
                  child: _recognized.isEmpty
                      ? const Center(child: Text('Waiting for recognitions...'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: _recognized.length,
                          itemBuilder: (_, i) {
                            final entry = _recognized[i];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 6),
                              leading: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_outline,
                                    color: AppColors.success, size: 24),
                              ),
                              title: Text(entry.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16)),
                              subtitle: Text(
                                '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}:${entry.time.second.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecognizedEntry {
  final String studentId;
  final String name;
  final double confidence;
  final DateTime time;
  const _RecognizedEntry({
    required this.studentId,
    required this.name,
    required this.confidence, 
    required this.time
  });
}
