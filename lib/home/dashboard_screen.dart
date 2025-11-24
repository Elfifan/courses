import 'package:flutter/material.dart';
import '../shared/side_panel.dart';
import '../shared/top_bar.dart';
import '../courses/courses_screen.dart';
import '../students/students_screen.dart';
import '../staff/staff_screen.dart';
import '../achievements/achievements_screen.dart';
import '../services/course_service.dart';


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
  String _selectedCourseFilter = 'Все';
  String _selectedStudentFilter = 'Все пользователи';

  final GlobalKey _achievementsKey = GlobalKey();

  final List<String> _menuItems = [
    'Dashboard',
    'Курсы',
    'Пользователь',
    'Сотрудники',
    'Достижения'
  ];

  final List<IconData> _menuIcons = [
    Icons.dashboard_rounded,
    Icons.school_rounded,
    Icons.people_rounded,
    Icons.work_rounded,
    Icons.analytics_rounded,
    Icons.settings_rounded
  ];

  void _showAddCourseForm() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _priceController = TextEditingController();

    String _selectedType = 'Бесплатный';

    // Список эмодзи для выбора
    final List<String> emojiOptions = ['📚', '🐍', '⚡', '📱', '🧑‍💻', '🎯', '🚀', '💻'];
    String _selectedEmoji = emojiOptions[0];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Добавить новый курс'),
              content: SizedBox(
                width: 600,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Выбор эмодзи
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text('Выберите иконку:', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: emojiOptions.map((emoji) {
                            final isSelected = emoji == _selectedEmoji;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedEmoji = emoji;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blueAccent.withValues(alpha: 0.3) : null,
                                  border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        // Название курса
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Название курса *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Введите название курса' : null,
                        ),
                        const SizedBox(height: 20),
                        // Описание курса
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Описание',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 20),
                        // Выбор типа курса
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          items: const [
                            DropdownMenuItem(value: 'Бесплатный', child: Text('Бесплатный')),
                            DropdownMenuItem(value: 'Платный', child: Text('Платный')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Тип курса',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedType = value;
                                if (_selectedType == 'Бесплатный') {
                                  _priceController.text = '';
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        // Цена (если платный)
                        if (_selectedType == 'Платный')
                          TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Цена (₽)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_selectedType == 'Платный') {
                                if (value == null || value.isEmpty) {
                                  return 'Введите цену';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Введите корректное число';
                                }
                              }
                              return null;
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Курс "${_nameController.text}" добавлен')),
                      );
                    }
                  },
                  child: const Text('Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  onAddStaff: () {
                    if (_selectedIndex == 3) {
                      CourseService.showAddCourseForm(context);
                    }
                  },
                  onAddCourse: () {
                    if (_selectedIndex == 1) {
                      _showAddCourseForm();
                    }
                  },
                  onAddAchievement: () {
                    if (_selectedIndex == 4) {
                      final s = _achievementsKey.currentState;
                      if (s != null) {
                        (s as dynamic).openAddDialog();
                      }
                    }
                  },
                ),
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.background,
                    child: Padding(
                      padding: EdgeInsets.all(32),
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
        return CoursesScreen(
          selectedFilter: _selectedCourseFilter,
          onFilterChanged: (filter) {
            setState(() {
              _selectedCourseFilter = filter;
            });
          },
          isDarkMode: widget.isDarkMode,
        );
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
        return StaffScreen(
          isDarkMode: widget.isDarkMode,
        );
      case 4:
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              SizedBox(height: 16),
              Text(
                'Раздел "${_menuItems[_selectedIndex]}" в разработке',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        // Статистические карточки
        Row(
          children: [
            _buildStatCard('Всего курсов', '24', Theme.of(context).primaryColor, Icons.school_rounded),
            SizedBox(width: 20),
            _buildStatCard('Студентов зарегистрировано', '892', Color(0xFF10B981), Icons.people_rounded),
            SizedBox(width: 20),
            _buildStatCard('Платных курсов', '8', Color(0xFFF59E0B), Icons.attach_money_rounded),
            SizedBox(width: 20),
            _buildStatCard('Общий доход', '₽347,820', Color(0xFF38BDF8), Icons.account_balance_wallet_rounded),
          ],
        ),

        SizedBox(height: 30),

        // Дополнительная статистика
        Row(
          children: [
            _buildInfoCard('Средняя оценка курсов', '4.7', Icons.star_rounded, Color(0xFFEAB308)),
            SizedBox(width: 20),
            _buildInfoCard('Курсов в разработке', '2', Icons.autorenew , Color.fromARGB(255, 197, 113, 16)),
            SizedBox(width: 20),
            _buildInfoCard('Новых студентов за месяц', '+156', Icons.trending_up_rounded, Color(0xFF38BDF8)),
            SizedBox(width: 20),
            _buildInfoCard('Кол-во завершённых курсов', '132', Icons.school, Color.fromARGB(255, 28, 173, 60)),
          ],
        ),

        SizedBox(height: 30),

        // Таблицы - только последние курсы и активность
        Expanded(
          child: Row(
            children: [
              // Последние курсы
              Expanded(
                flex: 2,
                child: _buildRecentCoursesCard(),
              ),
              SizedBox(width: 20),
              // Активность на всю высоту
              Expanded(
                child: _buildActivityCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Статистические карточки
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: widget.isDarkMode
            ? Border.all(color: Color(0xFF30363D))
            : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Spacer(),
                Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 20),
              ],
            ),
            SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: widget.isDarkMode ? Color(0xFF8B949E) : Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Информационные карточки
  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: widget.isDarkMode
            ? Border.all(color: Color(0xFF30363D))
            : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: widget.isDarkMode ? Color(0xFF8B949E) : Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCoursesCard() {
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: widget.isDarkMode
          ? Border.all(color: Color(0xFF30363D))
          : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Последние курсы',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 0),
          Expanded(
            child: ListView(
              children: [
                _buildCourseRow('Python для начинающих', 'Активный', Color(0xFF10B981), '234 студента'),
                _buildCourseRow('JavaScript Advanced', 'В разработке', Color(0xFFF59E0B), '0 студентов'),
                _buildCourseRow('React.js Fundamentals', 'Активный', Color(0xFF10B981), '189 студентов'),
                _buildCourseRow('Flutter Mobile Dev', 'Завершен', Color(0xFF6B7280), '145 студентов'),
                _buildCourseRow('Node.js Backend', 'Активный', Color(0xFF10B981), '87 студентов'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseRow(String name, String status, Color statusColor, String students) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.isDarkMode ? Color(0xFF30363D) : Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: widget.isDarkMode ? Color(0xFFE6EDF3) : Color(0xFF1E293B),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              students,
              style: TextStyle(
                color: widget.isDarkMode ? Color(0xFF8B949E) : Color(0xFF64748B),
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: widget.isDarkMode
          ? Border.all(color: Color(0xFF30363D))
          : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Активность',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildActivityItem('Новый студент зарегистрирован', '2 мин назад', Icons.person_add_rounded, Color(0xFF10B981)),
                _buildActivityItem('Курс Python обновлен', '15 мин назад', Icons.edit_rounded, Color(0xFF38BDF8)),
                _buildActivityItem('Оплата получена', '1 час назад', Icons.payment_rounded, Color(0xFFF59E0B)),
                _buildActivityItem('Новый отзыв добавлен', '3 часа назад', Icons.star_rounded, Color(0xFF9F7AEA)),
                _buildActivityItem('Пользователь завершил курс', '4 часа назад', Icons.done_all_rounded, Color(0xFF10B981)),
                _buildActivityItem('Новая регистрация', '6 часов назад', Icons.person_add_alt_rounded, Color(0xFF3B82F6)),
                _buildActivityItem('Обновлен контент курса', '1 день назад', Icons.edit_note_rounded, Color(0xFF8B5CF6)),
                _buildActivityItem('Получен новый отзыв', '2 дня назад', Icons.rate_review_rounded, Color(0xFFEC4899)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    color: widget.isDarkMode ? Color(0xFF8B949E) : Color(0xFF64748B),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
