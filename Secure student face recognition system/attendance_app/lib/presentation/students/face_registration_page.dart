import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../shared/common_widgets.dart';

class FaceRegistrationPage extends ConsumerStatefulWidget {
  final String studentId;
  final String studentName;
  const FaceRegistrationPage({super.key, required this.studentId, required this.studentName});

  @override
  ConsumerState<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends ConsumerState<FaceRegistrationPage> {
  bool _isRegistering = false;
  String? _error;
  Uint8List? _frameBytes;
  Timer? _timer;


  late final _api; // add this field

  @override
  void initState() {
    super.initState();
    _api = ref.read(recognitionApiProvider); // save ref early
    _startCamera();
  }

  Future<void> _startCamera() async {
    await _api.startCamera();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _fetchFrame());
  }

  Future<void> _fetchFrame() async {
    try {
      final baseUrl = _api.streamUrl.replaceAll('/stream', '');
      final response = await http.get(Uri.parse('$baseUrl/camera/frame'));
      if (response.statusCode == 200 && mounted) {
        setState(() => _frameBytes = response.bodyBytes);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _api.stopCamera(); 
    super.dispose();
  }

  Future<void> _register() async {
    setState(() { _isRegistering = true; _error = null; });
    try {
      final success = await _api.registerFace(widget.studentName);
      if (success) {
        final repo = ref.read(studentRepoProvider); // ref still valid here
        await repo.updateFaceRegistration(widget.studentId, true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Face registered for ${widget.studentName}')),
          );
          context.pop();
        }
      } else {
        setState(() => _error = 'Failed to capture face. Ensure face is clearly visible.');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Future<void> stopCamera() async {
    try {
      final api = ref.read(recognitionApiProvider); // ← this is the culprit
      final baseUrl = api.streamUrl.replaceAll('/stream', '');
      await http.post(Uri.parse('$baseUrl/camera/stop'));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Column(
        children: [
          PageHeader(
            title: 'Register Face',
            subtitle: 'Capturing biometric data for ${widget.studentName}',
            trailing: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 640,
                height: 480,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 20),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Polled JPEG frames
                    _frameBytes != null
                        ? Image.memory(
                            _frameBytes!,
                            fit: BoxFit.cover,
                            width: 640,
                            height: 480,
                            gaplessPlayback: true, // prevents flicker between frames
                          )
                        : const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Starting camera...', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                    // Overlay
                    Positioned(
                      bottom: 24, left: 0, right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'Align face within the frame and look at the camera',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: SizedBox(
              width: 200, height: 56,
              child: ElevatedButton.icon(
                onPressed: _isRegistering ? null : _register,
                icon: _isRegistering
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.camera_alt_rounded),
                label: Text(_isRegistering ? 'Registering...' : 'Capture Face'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}