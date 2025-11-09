import 'package:flutter/material.dart';
import 'home/dashboard_screen.dart';

// Светлая тема
final ThemeData lightTheme = ThemeData(
  primaryColor: Color(0xFF6366F1),
  scaffoldBackgroundColor: Color(0xFFF4F6F8),
  colorScheme: ColorScheme(
    primary: Color(0xFF6366F1),
    primaryContainer: Color(0xFFE0E7FF),
    secondary: Color(0xFF8B5CF6),
    secondaryContainer: Color(0xFFF4F6F8),
    surface: Color(0xFFFFFFFF),       // белый для карточек и панелей
    background: Color.fromARGB(255, 239, 240, 241),
    error: Color(0xFFEF4444),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFF1E293B),
    onBackground: Color(0xFF334155),
    onError: Colors.white,
    brightness: Brightness.light,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF1E293B),
    elevation: 1,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF6366F1),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Color(0xFF6366F1),
      side: BorderSide(color: Color(0xFF6366F1), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Color(0xFFD1D5DB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Color(0xFFD1D5DB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Color(0xFF6366F1)),
    ),
    prefixIconColor: Color(0xFF8B5CF6),
    hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
  ),
);

// Обычная тёмная тема
final ThemeData darkTheme = ThemeData(
  primaryColor: Color(0xFF2196F3), // стандартный синий
  scaffoldBackgroundColor: Color(0xFF121212), // стандартный темный фон
  colorScheme: ColorScheme.dark(
    primary: Color(0xFF2196F3),
    primaryContainer: Color(0xFF1976D2),
    secondary: Color(0xFF03DAC6), // стандартный teal
    secondaryContainer: Color(0xFF1E1E1E),
    surface: Color(0xFF1E1E1E),
    background: Color(0xFF121212),
    error: Color(0xFFCF6679),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Colors.white,
    onBackground: Colors.white,
    onError: Colors.white,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
    elevation: 4,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF2196F3),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Color(0xFF2196F3),
      side: BorderSide(color: Color(0xFF2196F3), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF1E1E1E),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Color(0xFF424242)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Color(0xFF424242)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Color(0xFF2196F3), width: 2),
    ),
    prefixIconColor: Color(0xFF03DAC6),
    hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
  ),
);

// Расширение для тем
extension CustomColors on ThemeData {
  Color get sidePanelColor => this.colorScheme.secondaryContainer;
  Color get sidePanelTextColor => this.brightness == Brightness.dark 
    ? Colors.white
    : Color(0xFF1E293B);
  Color get sidePanelTextSecondaryColor => this.brightness == Brightness.dark 
    ? Color(0xFF9E9E9E) 
    : Color(0xFF64748B);
}

// Основное приложение
class AdminCoursesApp extends StatefulWidget {
  @override
  _AdminCoursesAppState createState() => _AdminCoursesAppState();
}

class _AdminCoursesAppState extends State<AdminCoursesApp> {
  bool isDarkMode = true; // По умолчанию тёмная тема
  
  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Админ панель - Курсы программирования',
      theme: isDarkMode ? darkTheme : lightTheme,
      home: DashboardScreen(onThemeToggle: toggleTheme, isDarkMode: isDarkMode),
      debugShowCheckedModeBanner: false,
    );
  }
}