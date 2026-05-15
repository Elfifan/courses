import 'package:flutter/material.dart';
import '../core/theme/app_components.dart';


class TopBar extends StatelessWidget {
  final int selectedIndex;
  final List<String> menuItems;
  final VoidCallback? onAddCourse;
  final VoidCallback? onAddAchievement;

  const TopBar({
    super.key,
    required this.selectedIndex,
    required this.menuItems,
    this.onAddCourse,
    this.onAddAchievement,
  });

  @override
  Widget build(BuildContext context) {
    final bool showAddButton = menuItems[selectedIndex] == 'Курсы' && onAddCourse != null;

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

          const Spacer(),

          // Add button
          if (showAddButton)
            KodixComponents.primaryButton(
              height: 40,
              width: 180,
              onPressed: () {
                if (menuItems[selectedIndex] == 'Курсы') {
                  onAddCourse?.call();
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _getButtonText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
    return '';
  }
}
