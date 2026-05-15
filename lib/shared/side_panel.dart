import 'package:flutter/material.dart';
import '../app.dart';

class SidePanel extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<String> menuItems;
  final List<IconData> menuIcons;
  final VoidCallback onLogout;
  final String? userName;
  final String? userRole;

  const SidePanel({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.menuItems,
    required this.menuIcons,
    required this.onLogout,
    this.userName,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Theme.of(context).sidePanelColor,
      child: Column(
        children: [
          // Логотип и заголовок
          Container(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.code_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'KODIX',
                  style: TextStyle(
                    color: Theme.of(context).sidePanelTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Разделитель
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: const Color(0xFFE2E8F0),
          ),

          // Меню навигации
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ListView.builder(
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  bool isSelected = selectedIndex == index;
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Icon(
                        menuIcons[index],
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).sidePanelTextSecondaryColor,
                        size: 22,
                      ),
                      title: Text(
                        menuItems[index],
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).sidePanelTextSecondaryColor,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      onTap: () => onItemSelected(index),
                    ),
                  );
                },
              ),
            ),
          ),

          // Профиль администратора
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      radius: 20,
                      child: Text(
                        (userName != null && userName!.isNotEmpty)
                            ? userName![0].toUpperCase()
                            : 'А',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userName ?? 'Сотрудник',
                            style: TextStyle(
                              color: Theme.of(context).sidePanelTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            userRole ?? 'Сотрудник',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).sidePanelTextSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.logout,
                        color: Theme.of(context).sidePanelTextSecondaryColor,
                        size: 18,
                      ),
                    ),
                    label: Text(
                      'Выйти',
                      style: TextStyle(
                        color: Theme.of(context).sidePanelTextSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Подтверждение выхода'),
          content: Text('Вы уверены, что хотите выйти из системы?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Нет'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onLogout();
              },
              child: Text('Да'),
            ),
          ],
        );
      },
    );
  }
}
