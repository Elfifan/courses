import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Цветовая палитра проекта «Кодикс»
class AppColors {
  static const Color primaryPurple = Color(0xFFA58EFF);
  static const Color accentPink = Color(0xFFF2C9D4);
  static const Color textDark = Color(0xFF1E1E2E);
  static const Color textGrey = Color(0xFF9094A6);
  static const Color bgLight = Color(0xFFF8F9FB);
  static const Color white = Colors.white;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, accentPink],
  );
}

/// Константы стилей (отступы, радиусы, шрифты)
class AppStyles {
  // Шрифты
  static TextStyle h1 = GoogleFonts.roboto(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static TextStyle body = GoogleFonts.roboto(
    fontSize: 16,
    color: AppColors.textDark,
  );

  static TextStyle label = GoogleFonts.roboto(
    fontSize: 14,
    color: AppColors.textGrey,
  );

  // Радиусы
  static final BorderRadius mainRadius = BorderRadius.circular(20);
  static final BorderRadius cardRadius = BorderRadius.circular(24);
}

/// Общие переиспользуемые виджеты
class KodixComponents {
  
  /// Кнопка с градиентом «Кодикс»
  static Widget primaryButton({
    required String text,
    required VoidCallback onTap,
    double height = 56,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppStyles.mainRadius,
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppStyles.mainRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          height: height,
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  /// Декорация для текстовых полей
  static InputDecoration textFieldDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppStyles.label,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primaryPurple, size: 22) : null,
      filled: true,
      fillColor: AppColors.bgLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: AppStyles.mainRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppStyles.mainRadius,
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppStyles.mainRadius,
        borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
      ),
    );
  }

  /// Карточка-контейнер для списков
  static Widget cardContainer({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppStyles.cardRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Универсальный AppBar
  static PreferredSizeWidget appBar(String title, {List<Widget>? actions}) {
    return AppBar(
      title: Text(title, style: AppStyles.h1),
      actions: actions,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppColors.textDark),
    );
  }
}