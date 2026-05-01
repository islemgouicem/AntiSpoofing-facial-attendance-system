import 'dart:io';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── SQLite setup for Windows desktop ───────────────────────
  if (Platform.isWindows) {
    // Try to load sqlite3.dll from the application directory
    open.overrideFor(OperatingSystem.windows, () {
      // Look for sqlite3.dll next to the executable
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final dllPath = '$exeDir\\sqlite3.dll';
      final dllFile = File(dllPath);

      if (dllFile.existsSync()) {
        return DynamicLibrary.open(dllPath);
      }

      // Fallback: try system path
      return DynamicLibrary.open('sqlite3.dll');
    });
  }

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(const ProviderScope(child: App()));
}
