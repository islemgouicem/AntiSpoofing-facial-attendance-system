import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/common_widgets.dart';

class StudentDetailPage extends ConsumerWidget {
  final String studentId;
  const StudentDetailPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          PageHeader(
            title: 'Student Details',
            subtitle: 'View profile and attendance history',
            trailing: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
          const Expanded(
            child: Center(child: Text('Student detail view — coming soon')),
          ),
        ],
      ),
    );
  }
}
