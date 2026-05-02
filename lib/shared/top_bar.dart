import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  final List<String> menuItems;
  final VoidCallback? onAddCourse;
  final VoidCallback? onAddAchievement;

  const TopBar({
    super.key,
    required this.selectedIndex,
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.menuItems,
    this.onAddCourse,
    this.onAddAchievement,
  });

  @override
  Widget build(BuildContext context) {
    final bool showAddButton = menuItems[selectedIndex] == 'Курсы' && onAddCourse != null ||
        menuItems[selectedIndex] == 'Достижения' && onAddAchievement != null;

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
                if (menuItems[selectedIndex] == 'Курсы') {
                  onAddCourse?.call();
                } else if (menuItems[selectedIndex] == 'Достижения') {
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
    if (selectedIndex >= 0 && selectedIndex < menuItems.length) {
      return menuItems[selectedIndex];
    }
    return 'Dashboard';
  }

  String _getButtonText() {
    final item = selectedIndex >= 0 && selectedIndex < menuItems.length
        ? menuItems[selectedIndex]
        : '';
    if (item == 'Курсы') return 'Добавить курс';
    if (item == 'Достижения') return 'Добавить достижение';
    return '';
  }
}
