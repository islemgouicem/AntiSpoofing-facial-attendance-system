import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
    final api = ref.read(recognitionApiProvider);
    await api.startCamera();
  }

  @override
  void dispose() {
    // Optionally stop camera, but AI monitor handles it
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _isRegistering = true;
      _error = null;
    });

    try {
      final api = ref.read(recognitionApiProvider);
      final success = await api.registerFace(widget.studentName);
      
      if (success) {
        // Update SQLite
        final repo = ref.read(studentRepoProvider);
        await repo.updateFaceRegistration(widget.studentId, true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Face registered successfully for ${widget.studentName}')),
          );
          context.pop();
        }
      } else {
        setState(() => _error = 'Failed to capture face. Please ensure your face is clearly visible.');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streamUrl = ref.watch(recognitionApiProvider).streamUrl;

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
                    // Stream from AI Engine
                    Image.network(
                      streamUrl,
                      fit: BoxFit.cover,
                      width: 640,
                      height: 480,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 48),
                            SizedBox(height: 16),
                            Text('Camera Stream Offline', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    
                    // Overlay instructions
                    Positioned(
                      bottom: 24,
                      left: 0, right: 0,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 56,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
