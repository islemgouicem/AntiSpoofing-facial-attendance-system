import 'dart:async';
import 'dart:io';
import '../../core/constants/app_constants.dart';

/// Manages the Python AI engine process lifecycle.
class AiEngineService {
  Process? _process;
  bool _isRunning = false;
  Timer? _healthTimer;

  bool get isRunning => _isRunning;

  /// Initialize the engine monitoring.
  void initialize() {
    print('[AiEngine] Initializing background monitor...');
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkHealth());
    // Immediate first check
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    final client = HttpClient();
    bool isAlive = false;
    try {
      final request = await client
          .getUrl(Uri.parse('${AppConstants.aiBaseUrl}/health'))
          .timeout(const Duration(seconds: 1));
      final response = await request.close();
      if (response.statusCode == 200) {
        isAlive = true;
      }
    } catch (_) {
      isAlive = false;
    } finally {
      client.close();
    }

    if (!isAlive) {
      if (_isRunning) {
        print('[AiEngine] Engine went down unexpectedly. Restarting...');
        _isRunning = false;
      }
      await start();
    } else {
      if (!_isRunning) {
        print('[AiEngine] Engine is now online.');
        _isRunning = true;
      }
    }
  }

  /// Start the AI engine and wait until healthy.
  Future<bool> start() async {
    // Avoid concurrent start attempts
    if (_isRunning) return true;

    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      
      // 1. Try frozen executable (Packaged)
      final exeCandidates = [
        '$exeDir\\ai_engine\\ai_engine.exe',
        '$exeDir\\ai_engine.exe',
      ];
      String? frozenExePath;
      for (final c in exeCandidates) {
        if (await File(c).exists()) {
          frozenExePath = File(c).absolute.path;
          break;
        }
      }

      if (frozenExePath != null) {
        print('[AiEngine] Launching packaged engine: $frozenExePath');
        _process = await Process.start(
          frozenExePath,
          ['--parent-pid', pid.toString()],
          workingDirectory: File(frozenExePath).parent.path,
          mode: ProcessStartMode.detached,
        );
      } else {
        // 2. Try python script (Development)
        String? serverPath;
        
        // Search in project structure relative to script/exe
        final candidates = [
          '$exeDir\\..\\..\\..\\..\\..\\ai_engine\\server.py',
          '$exeDir\\..\\ai_engine\\server.py',
          '$exeDir\\ai_engine\\server.py',
        ];

        for (final c in candidates) {
          if (await File(c).exists()) {
            serverPath = File(c).absolute.path;
            break;
          }
        }

        if (serverPath == null) {
          // Absolute fallback for local dev repo
          final projectRoot = Directory.current.path;
          final candidatesDev = [
            '$projectRoot\\..\\ai_engine\\server.py',
            '$projectRoot\\ai_engine\\server.py',
          ];
          for (final c in candidatesDev) {
            if (await File(c).exists()) {
              serverPath = File(c).absolute.path;
              break;
            }
          }
        }

        if (serverPath == null) {
          print('[AiEngine] ERROR: Could not find AI engine source or executable.');
          return false;
        }

        print('[AiEngine] Launching python engine: $serverPath');
        
        // Try 'python' first, then 'python3'
        try {
          _process = await Process.start(
            'python',
            [serverPath, '--parent-pid', pid.toString()],
            workingDirectory: File(serverPath).parent.path,
            mode: ProcessStartMode.detached,
          );
        } catch (_) {
          print('[AiEngine] "python" failed, trying "python3"...');
          _process = await Process.start(
            'python3',
            [serverPath, '--parent-pid', pid.toString()],
            workingDirectory: File(serverPath).parent.path,
            mode: ProcessStartMode.detached,
          );
        }
      }

      // Wait for API to become healthy
      _isRunning = await _waitForHealth();
      if (_isRunning) {
        print('[AiEngine] SUCCESS: Engine is online and healthy.');
      } else {
        print('[AiEngine] ERROR: Engine started but health check failed.');
      }
      return _isRunning;
    } catch (e) {
      print('[AiEngine] Startup error: $e');
      return false;
    }
  }

  Future<bool> _waitForHealth() async {
    final client = HttpClient();
    for (int i = 0; i < AppConstants.aiHealthMaxRetries; i++) {
      try {
        final request = await client
            .getUrl(Uri.parse('${AppConstants.aiBaseUrl}/health'))
            .timeout(const Duration(seconds: 1));
        final response = await request.close();
        if (response.statusCode == 200) {
          client.close();
          return true;
        }
      } catch (_) {}
      await Future.delayed(AppConstants.aiHealthPoll);
    }
    client.close();
    return false;
  }

  /// Stop the AI engine process.
  Future<void> stop() async {
    _healthTimer?.cancel();
    if (_process != null) {
      _process!.kill();
      _process = null;
    }
    _isRunning = false;
  }
}
