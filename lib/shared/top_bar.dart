import 'package:flutter/material.dart';
import '../repositories/course_repository.dart';

class TopBar extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  final List<String> menuItems;
  final VoidCallback? onAddStaff;
  final VoidCallback? onAddCourse;
  final VoidCallback? onAddAchievement;

  const TopBar({
    super.key,
    required this.selectedIndex,
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.menuItems,
    this.onAddStaff,
    this.onAddCourse,
    this.onAddAchievement,
  });

  @override
  Widget build(BuildContext context) {
    final bool showAddButton = [1, 3, 4].contains(selectedIndex) && (
      (selectedIndex == 1 && onAddCourse != null) ||
      (selectedIndex == 3 && onAddStaff != null) ||
      (selectedIndex == 4 && onAddAchievement != null)
    );

    return Container(
      height: 70,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Text(
            _getPageTitle(),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),

          // Theme toggle
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF21262D) : const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(10), 
              border: Border.all(
                color: isDarkMode ? const Color(0xFF30363D) : const Color(0xFFEFEFEF),
              ),
            ),
            child: IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: onThemeToggle,
              tooltip: isDarkMode ? 'Светлая тема' : 'Тёмная тема',
            ),
          ),

          const SizedBox(width: 12),

          // Add button
          if (showAddButton)
            ElevatedButton.icon(
              onPressed: () {
                if (selectedIndex == 1) {
                  CourseService.showAddCourseForm(context);
                } else if (selectedIndex == 3) {
                  onAddStaff?.call();
                } else if (selectedIndex == 4) {
                onAddAchievement?.call();
            }
          },
              icon: const Icon(Icons.add),
              label: Text(_getButtonText()),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(140, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (selectedIndex) {
      case 0:
        return 'Статистика';
      case 1:
        return 'Управление курсами';
      case 2:
        return 'Студенты';
      case 3:
        return 'Сотрудники';
      case 4:
        return 'Достижения';
      default:
        return 'Dashboard';
    }
  }

  String _getButtonText() {
    switch (selectedIndex) {
      case 1:
        return 'Добавить курс';
      case 3:
        return 'Добавить сотрудника';
      case 4:
        return 'Добавить достижение';
      default:
        return '';
    }
  }
}
