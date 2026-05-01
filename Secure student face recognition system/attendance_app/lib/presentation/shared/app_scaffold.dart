import 'package:flutter/material.dart';
import 'sidebar.dart';

/// Main layout shell used by the ShellRoute — sidebar + page content.
class AppScaffold extends StatelessWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
