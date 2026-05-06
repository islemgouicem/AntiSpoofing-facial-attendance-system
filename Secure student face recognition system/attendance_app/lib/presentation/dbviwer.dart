import 'package:attendance_app/data/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DbViewerPage extends ConsumerStatefulWidget {
  const DbViewerPage({super.key});
  @override
  ConsumerState<DbViewerPage> createState() => _DbViewerPageState();
}

class _DbViewerPageState extends ConsumerState<DbViewerPage> {
  Map<String, List<Map<String, dynamic>>> _data = {};
  bool _loading = true;

  final _tables = [
    'teachers',
    'semesters',
    'modules',
    'groups',
    'students',
    'student_groups',
    'teaching_assignments',
    'academic_sessions',
    'attendance_records',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await AppDatabase().database;
    final result = <String, List<Map<String, dynamic>>>{};
    for (final table in _tables) {
      result[table] = await db.query(table);
    }
    setState(() { _data = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DB Viewer'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {
            setState(() => _loading = true);
            _load();
          }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _tables.map((table) {
                final rows = _data[table] ?? [];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(table,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${rows.length} rows'),
                    children: rows.isEmpty
                        ? [const ListTile(title: Text('Empty'))]
                        : rows.map((row) => ListTile(
                              dense: true,
                              title: Text(
                                row.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join('\n'),
                                style: const TextStyle(fontSize: 11,
                                    fontFamily: 'monospace'),
                              ),
                            )).toList(),
                  ),
                );
              }).toList(),
            ),
    );
  }
}