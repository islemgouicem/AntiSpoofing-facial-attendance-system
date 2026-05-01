import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_constants.dart';

/// SQLite database helper — offline-first storage.
class AppDatabase {
  static AppDatabase? _instance;
  static Database? _db;

  AppDatabase._();
  factory AppDatabase() => _instance ??= AppDatabase._();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    sqfliteFfiInit();
    final dbFactory = databaseFactoryFfi;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, AppConstants.dbName);
    return dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── Pre-existing: Teacher Auth ───────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS teachers (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        display_name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // ── Academic Structure ──────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS semesters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        teacher_id TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS modules (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        academic_year TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        academic_year TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS students (
        id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT,
        student_id TEXT UNIQUE,
        face_registered INTEGER DEFAULT 0,
        photo_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS student_groups (
        student_id TEXT NOT NULL,
        group_id TEXT NOT NULL,
        PRIMARY KEY (student_id, group_id),
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
        FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
      )
    ''');

    // ── Assignments & Sessions ──────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS teaching_assignments (
        id TEXT PRIMARY KEY,
        semester_id TEXT NOT NULL,
        module_id TEXT NOT NULL,
        group_id TEXT NOT NULL,
        session_type TEXT NOT NULL, -- 'Tutorial' or 'Lab'
        FOREIGN KEY (semester_id) REFERENCES semesters(id) ON DELETE CASCADE,
        FOREIGN KEY (module_id) REFERENCES modules(id) ON DELETE CASCADE,
        FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS academic_sessions (
        id TEXT PRIMARY KEY,
        assignment_id TEXT NOT NULL,
        session_number INTEGER NOT NULL, -- S1, S2, S3...
        started_at INTEGER, -- Null if not yet conducted
        ended_at INTEGER,
        status TEXT DEFAULT 'pending', -- 'pending', 'active', 'completed'
        FOREIGN KEY (assignment_id) REFERENCES teaching_assignments(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance_records (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        status TEXT DEFAULT 'absent', -- 'present', 'absent', 'manual_present', 'manual_absent'
        recognized_at INTEGER,
        confidence REAL,
        FOREIGN KEY (session_id) REFERENCES academic_sessions(id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // For development convenience, we'll rebuild schema if on old version
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS attendance_records');
      await db.execute('DROP TABLE IF EXISTS academic_sessions');
      await db.execute('DROP TABLE IF EXISTS teaching_assignments');
      await db.execute('DROP TABLE IF EXISTS student_groups');
      await db.execute('DROP TABLE IF EXISTS students');
      await db.execute('DROP TABLE IF EXISTS groups');
      await db.execute('DROP TABLE IF EXISTS modules');
      await db.execute('DROP TABLE IF EXISTS semesters');
      await db.execute('DROP TABLE IF EXISTS teachers');
      await db.execute('DROP TABLE IF EXISTS attendance_sessions'); // Old table

      await _onCreate(db, newVersion);
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
