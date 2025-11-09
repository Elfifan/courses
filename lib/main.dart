import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'auth_screen.dart';
import 'home/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://xrpuolgthmgonondczfy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhycHVvbGd0aG1nb25vbmRjemZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgxODcxNjcsImV4cCI6MjA3Mzc2MzE2N30.lWjE3d_BTloNXjWrlKU-SH3MB8vG15npTkguLg2FVu8',
  );
  
  runApp(const AdminApp());
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  bool isDarkMode = true;
  bool isLoggedIn = false;

  void toggleTheme(bool newValue) {
    setState(() {
      isDarkMode = newValue;
    });
  }

  void loginSuccess() {
    setState(() {
      isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Course Platform',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: isLoggedIn
          ? DashboardScreen(
              onThemeToggle: () => toggleTheme(!isDarkMode),
              isDarkMode: isDarkMode,
            )
          : AuthScreen(
              isDarkMode: isDarkMode,
              onToggleTheme: (value) => toggleTheme(value),
              onLoginSuccess: loginSuccess,
            ),
    );
  }
}
