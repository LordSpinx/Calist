import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/event.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(EventAdapter());

  await Hive.openBox<Event>('events');

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Calist',
    theme: ThemeData(
      primarySwatch: Colors.green,
      brightness: Brightness.light,
    ),
    darkTheme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: Colors.black54,
      colorScheme: const ColorScheme.dark(
        primary: Colors.green,
        secondary: Colors.black54,
      ),
    ),
    themeMode: ThemeMode.system, // Auto-Wechsel je nach OS
    home: const HomeScreen(),
  );
}
