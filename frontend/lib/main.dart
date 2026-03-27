// lib/main.dart
//
// App entry point. Sets up Provider (state management) at the root level
// so every screen in the app can access TaskProvider.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'screens/task_list_screen.dart';

void main() {
  runApp(const FlodoApp());
}

class FlodoApp extends StatelessWidget {
  const FlodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // TaskProvider is created once here and shared with the entire app
      create: (_) => TaskProvider(),
      child: MaterialApp(
        title: 'Flodo Task Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const TaskListScreen(),
      ),
    );
  }
}
