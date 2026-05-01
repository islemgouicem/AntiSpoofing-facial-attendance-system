import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/models/student.dart';
import '../../../providers/app_providers.dart';

class FaceCaptureDialog extends ConsumerStatefulWidget {
  final Student student;
  const FaceCaptureDialog({super.key, required this.student});

  @override
  ConsumerState<FaceCaptureDialog> createState() => _FaceCaptureDialogState();
}

class _FaceCaptureDialogState extends ConsumerState<FaceCaptureDialog> {
  Timer? _frameTimer;
  Uint8List? _currentFrame;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  void _startTimers() {
    _frameTimer = Timer.periodic(AppConstants.frameInterval, (_) => _fetchFrame());
  }

  Future<void> _fetchFrame() async {
    final api = ref.read(recognitionApiProvider);
    final bytes = await api.getFrame();
    if (bytes != null && mounted) {
      setState(() => _currentFrame = Uint8List.fromList(bytes));
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    super.dispose();
  }

  Future<void> _captureFace() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final api = ref.read(recognitionApiProvider);
      // Backend expects the name as parameter. We save face embedding mapped to student.id
      final success = await api.registerFace(widget.student.id);

      if (success && mounted) {
        // Update database accurately
        final repo = ref.read(studentRepoProvider);
        final updated = widget.student.copyWith(faceRegistered: true);
        await repo.update(updated);
        ref.invalidate(studentsProvider);

        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face captured for ${widget.student.firstName} !')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture face. Please ensure only one well-lit face is visible.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Capture Face'),
      content: SizedBox(
        width: 480,
        height: 380,
        child: Column(
          children: [
            const Text(
              'Please look directly at the camera to register your face. This will be used for attendance recognition.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black,
                  child: _currentFrame != null
                      ? Image.memory(
                          _currentFrame!,
                          gaplessPlayback: true,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white54),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Skip for now'),
        ),
        ElevatedButton.icon(
          onPressed: _currentFrame == null || _isCapturing ? null : _captureFace,
          icon: _isCapturing
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.camera_alt_rounded),
          label: Text(_isCapturing ? 'Capturing...' : 'Capture Face'),
        ),
      ],
    );
  }
}
