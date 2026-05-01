import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/recognition_result.dart';

/// HTTP client for the AI engine REST API.
class RecognitionApi {
  late final Dio _dio;

  RecognitionApi() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.aiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  // ── Health ───────────────────────────────────────────────
  Future<bool> isHealthy() async {
    try {
      final res = await _dio.get('/health');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Camera ───────────────────────────────────────────────
  Future<bool> startCamera({int cameraId = 0}) async {
    try {
      await _dio.post('/camera/start', queryParameters: {'camera_id': cameraId});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopCamera() async {
    try {
      await _dio.post('/camera/stop');
    } catch (_) {}
  }

  Future<List<int>?> getFrame() async {
    try {
      final res = await _dio.get<List<int>>(
        '/camera/frame',
        options: Options(responseType: ResponseType.bytes),
      );
      return res.data;
    } catch (_) {
      return null;
    }
  }

  String get streamUrl => '${AppConstants.aiBaseUrl}/stream';

  // ── Recognition ──────────────────────────────────────────
  Future<RecognitionResult?> recognize() async {
    try {
      final res = await _dio.post('/recognize');
      return RecognitionResult.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Registration ─────────────────────────────────────────
  Future<bool> registerFace(String name) async {
    try {
      final res = await _dio.post('/register', queryParameters: {'name': name});
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> listRegisteredStudents() async {
    try {
      final res = await _dio.get('/students');
      final data = res.data as Map<String, dynamic>;
      return List<String>.from(data['students'] as List);
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteRegisteredStudent(String name) async {
    try {
      await _dio.delete('/students/$name');
      return true;
    } catch (_) {
      return false;
    }
  }
}
