import 'dart:async';

import 'package:app_links/app_links.dart';
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
  late final AppLinks _appLinks;
  StreamSubscription<Uri?>? _linkSub;

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

  void logout() {
    setState(() {
      isLoggedIn = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // Cold-start link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  void _handleDeepLink(Uri uri) {
    final queryType = uri.queryParameters['type'];
    if (queryType == 'reset_password') {
      final email = uri.queryParameters['email'];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamed(
          '/reset-password',
          arguments: email,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Course Platform',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => isLoggedIn
            ? DashboardScreen(
                onThemeToggle: () => toggleTheme(!isDarkMode),
                isDarkMode: isDarkMode,
              )
            : AuthScreen(
                isDarkMode: isDarkMode,
                onToggleTheme: (value) => toggleTheme(value),
                onLoginSuccess: loginSuccess,
              ),
        '/reset-password': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return ResetPasswordScreen(
            email: email,
            onSuccess: () {
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
              }
            },
            isDarkMode: isDarkMode,
            onToggleTheme: toggleTheme,
          );
        },
      },
    );
  }
}
