import 'package:flutter/material.dart';
import '../core/theme/app_components.dart'; // Подключаем ваши компоненты[cite: 1]
import '../shared/side_panel.dart';
import '../shared/top_bar.dart';
import '../courses/courses_screen.dart';
import '../students/students_screen.dart';
import '../achievements/achievements_screen.dart';
import '../repositories/course_repository.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const DashboardScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _selectedStudentFilter = 'Все пользователи';

  final GlobalKey _achievementsKey = GlobalKey();

  final List<String> _menuItems = [
    'Статистика',
    'Курсы',
    'Пользователь',
    'Достижения'
  ];

  final List<IconData> _menuIcons = [
    Icons.dashboard_rounded,
    Icons.school_rounded,
    Icons.people_rounded,
    Icons.analytics_rounded,
    Icons.settings_rounded
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white, // Используем белый из палитры[cite: 1]
      body: Row(
        children: [
          SidePanel(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            isDarkMode: widget.isDarkMode,
            menuItems: _menuItems,
            menuIcons: _menuIcons,
          ),
          Expanded(
            child: Column(
              children: [
                TopBar(
                  selectedIndex: _selectedIndex,
                  onThemeToggle: widget.onThemeToggle,
                  isDarkMode: widget.isDarkMode,
                  menuItems: _menuItems,
                  onAddCourse: () {
                    if (_selectedIndex == 1) {
                      CourseService.showAddCourseForm(context);
                    }
                  },
                  onAddAchievement: () {
                    if (_selectedIndex == 3) {
                      final state = _achievementsKey.currentState as dynamic;
                      state.showForm();
                    }
                  },
                ),
                Expanded(
                  child: Container(
                    color: AppColors.bgLight, // Светлый фон подложки[cite: 1]
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: _buildContent(),
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

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return CoursesScreen(isDarkMode: widget.isDarkMode);
      case 2:
        return StudentsScreen(
          selectedFilter: _selectedStudentFilter,
          onFilterChanged: (filter) {
            setState(() {
              _selectedStudentFilter = filter;
            });
          },
          isDarkMode: widget.isDarkMode,
        );
      case 3:
        return AchievementsScreen(
          key: _achievementsKey,
          isDarkMode: widget.isDarkMode,
        );
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _menuIcons[_selectedIndex],
                size: 64,
                color: AppColors.textGrey.withOpacity(0.3), // Серый из палитры[cite: 1]
              ),
              const SizedBox(height: 16),
              Text(
                'Раздел "${_menuItems[_selectedIndex]}" в разработке',
                style: AppStyles.body.copyWith(color: AppColors.textGrey), // Roboto[cite: 1]
              ),
            ],
          ),
        );
    }
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('Всего курсов', '24', AppColors.primaryPurple, Icons.school_rounded), // Фиолетовый акцент[cite: 1]
            const SizedBox(width: 20),
            _buildStatCard('Студентов зарегистрировано', '892', const Color(0xFF10B981), Icons.people_rounded),
            const SizedBox(width: 20),
            _buildStatCard('Платных курсов', '8', const Color(0xFFF59E0B), Icons.attach_money_rounded),
            const SizedBox(width: 20),
            _buildStatCard('Общий доход', '₽347,820', const Color(0xFF38BDF8), Icons.account_balance_wallet_rounded),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            _buildInfoCard('Средняя оценка курсов', '4.7', Icons.star_rounded, const Color(0xFFEAB308)),
            const SizedBox(width: 20),
            _buildInfoCard('Курсов в разработке', '2', Icons.autorenew, const Color(0xFFC57110)),
            const SizedBox(width: 20),
            _buildInfoCard('Новых студентов за месяц', '+156', Icons.trending_up_rounded, const Color(0xFF38BDF8)),
            const SizedBox(width: 20),
            _buildInfoCard('Кол-во завершённых курсов', '132', Icons.school, const Color(0xFF1CAD3C)),
          ],
        ),
        const SizedBox(height: 30),
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 2, child: _buildRecentCoursesCard()),
              const SizedBox(width: 20),
              Expanded(child: _buildActivityCard()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppStyles.cardRadius, // Радиус 24px[cite: 1]
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                const Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: AppStyles.h1.copyWith(fontSize: 28)), // Roboto Bold[cite: 1]
            const SizedBox(height: 4),
            Text(title, style: AppStyles.label), // Roboto Grey[cite: 1]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Text(value, style: AppStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: AppStyles.label.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCoursesCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppStyles.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Последние курсы', style: AppStyles.h1.copyWith(fontSize: 20)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildCourseRow('Python для начинающих', 'Активный', const Color(0xFF10B981), '234 студента'),
                _buildCourseRow('JavaScript Advanced', 'В разработке', const Color(0xFFF59E0B), '0 студентов'),
                _buildCourseRow('React.js Fundamentals', 'Активный', const Color(0xFF10B981), '189 студентов'),
                _buildCourseRow('Flutter Mobile Dev', 'Завершен', AppColors.textGrey, '145 студентов'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseRow(String name, String status, Color statusColor, String students) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.bgLight, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(name, style: AppStyles.body.copyWith(fontWeight: FontWeight.w600))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(status, style: AppStyles.label.copyWith(color: statusColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(students, style: AppStyles.label, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppStyles.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Активность', style: AppStyles.h1.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildActivityItem('Новый студент', '2 мин назад', Icons.person_add_rounded, const Color(0xFF10B981)),
                _buildActivityItem('Курс обновлен', '15 мин назад', Icons.edit_rounded, AppColors.primaryPurple),
                _buildActivityItem('Оплата получена', '1 час назад', Icons.payment_rounded, const Color(0xFFF59E0B)),
                _buildActivityItem('Отзыв добавлен', '3 часа назад', Icons.star_rounded, const Color(0xFF9F7AEA)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppStyles.body.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(time, style: AppStyles.label.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}