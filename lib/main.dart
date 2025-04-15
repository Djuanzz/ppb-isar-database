import 'package:expense_tracker/screens/homepage.dart';
import 'package:expense_tracker/services/database.service.dart';
import 'package:flutter/material.dart';

void main() async {
  await _setupDatabase();
  runApp(const MyApp());
}

Future<void> _setupDatabase() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.setupDatabase();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
      ),
      home: const HomePage(),
    );
  }
}
