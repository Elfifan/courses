import 'package:flutter/material.dart';

class StudentProfileScreen extends StatefulWidget {
  final bool isDarkMode;

  const StudentProfileScreen({super.key, required this.isDarkMode});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _showPassword = false;
  bool _isBlocked = false; // статус заблокирован/нет

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    final student = {
      'avatar': 'А',
      'name': 'Анна Петрова',
      'email': 'anna.petrova@email.com',
      'phone': '+7 (900) 123-45-67',
      'registration_date': '15 марта 2024',
      'password': 'mypass123',
      'last_login': '20 сентября, 18:45',
    };

    final activityList = [
      {'title': 'Вошёл на платформу', 'time': '2 минуты назад'},
      {'title': 'Завершил курс Flutter Mobile Dev', 'time': '1 час назад'},
      {'title': 'Пройден тест по Python', 'time': '3 часа назад'},
      {'title': 'Добавлен новый отзыв', 'time': '1 день назад'},
    ];

    final courses = [
      {'name': 'Python для начинающих', 'icon': Icons.code, 'progress': 85, 'completed': false},
      {'name': 'Flutter Mobile Dev', 'icon': Icons.phone_iphone, 'progress': 100, 'completed': true},
      {'name': 'JavaScript Advanced', 'icon': Icons.javascript, 'progress': 60, 'completed': false},
    ];

    final certificates = [
      {'title': 'Сертификат Python', 'date': '10 сент.'},
      {'title': 'Сертификат Flutter', 'date': '5 сент.'},
      {'title': 'Сертификат JavaScript', 'date': '1 сент.'},
    ];

    final achievementEvents = [
      {'event': 'Регистрация на платформе', 'date': '15 марта 2024'},
      {'event': 'Начал курс Python', 'date': '16 марта 2024'},
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Профиль студента', style: TextStyle(color: textColor)),
        backgroundColor: cardBg,
        elevation: 1,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Левая панель
                Container(
                  width: constraints.maxWidth * 0.3,
                  padding: EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: widget.isDarkMode ? Border.all(color: Color(0xFF30363D)) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: theme.primaryColor,
                        child: Text(student['avatar']!,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      SizedBox(height: 10),
                      Text(student['name']!,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                      SizedBox(height: 4),
                      Text(student['email']!, style: TextStyle(color: textSecondary)),
                      SizedBox(height: 8),
                      _infoRow('Телефон', student['phone']!, textSecondary),
                      _passwordRow(student['password']!, textColor, textSecondary),
                      SizedBox(height: 4),
                      _infoRow('Регистрация', student['registration_date']!, textSecondary),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Text('Статус: ', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary)),
                          _statusChip(_isBlocked ? 'Заблокирован' : 'Активен', _isBlocked),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text('Последний вход:', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary)),
                      Text(student['last_login']!,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                minimumSize: Size(10, 38),
                              ),
                              icon: Icon(Icons.edit, size: 18),
                              label: Text('Редактировать', style: TextStyle(fontSize: 14)),
                              onPressed: () {},
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: _isBlocked ? Colors.red.shade300 : Colors.redAccent,
                                foregroundColor: Colors.white,
                                minimumSize: Size(10, 38),
                              ),
                              icon: Icon(Icons.block, size: 18),
                              label: Text(_isBlocked ? 'Разблокировать' : 'Заблокировать', style: TextStyle(fontSize: 14)),
                              onPressed: () => setState(() {
                                _isBlocked = !_isBlocked;
                              }),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                          child: _buildActivityCard(activityList, theme, widget.isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 40),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Курсы',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                        SizedBox(height: 10),
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: courses
                              .map((course) => _buildCourseCard(course, theme, widget.isDarkMode))
                              .toList(),
                        ),
                        SizedBox(height: 30),
                        Text('Достижения',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                        SizedBox(height: 10),
                        ...achievementEvents
                            .map((event) =>
                                _buildAchievementItem(event, theme, textSecondary, widget.isDarkMode))
                            .toList(),
                        SizedBox(height: 32),
                        Text('Сертификаты',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                        SizedBox(height: 12),
                        ...certificates
                            .map((cert) =>
                                _buildCertificateItem(cert, theme, textSecondary, widget.isDarkMode))
                            .toList(),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color))),
          Expanded(child: Text(value, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  Widget _statusChip(String status, bool blocked) {
    final color = blocked ? Colors.redAccent.shade200 : Colors.greenAccent.shade400;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _passwordRow(String password, Color textColor, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text('Пароль', style: TextStyle(fontWeight: FontWeight.w600, color: textSecondary))),
          Expanded(
            child: Row(
              children: [
                Text(
                  _showPassword ? password : '••••••••••',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, size: 20, color: textSecondary),
                  tooltip: _showPassword ? 'Скрыть пароль' : 'Показать пароль',
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map course, ThemeData theme, bool isDarkMode) {
    final isComplete = course['completed'] as bool;
    final progress = course['progress'] as int;
    return Container(
      width: 280,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: isDarkMode ? Border.all(color: Color(0xFF30363D)) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(course['icon'] as IconData, size: 32, color: theme.primaryColor),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course['name'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      isComplete ? Icons.check_circle : Icons.access_time,
                      size: 16,
                      color: isComplete ? Colors.green : Colors.amber,
                    ),
                    SizedBox(width: 2),
                    Text(
                      isComplete ? 'Завершён' : 'В процессе',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                LinearProgressIndicator(
                  value: progress / 100,
                  color: isComplete ? Colors.greenAccent : theme.primaryColor,
                  backgroundColor: theme.dividerColor,
                  minHeight: 6,
                ),
                SizedBox(height: 2),
                Text('$progress% выполнено', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(Map event, ThemeData theme, Color secondary, bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isDarkMode ? Border.all(color: Color(0xFF30363D)) : null,
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: theme.primaryColor),
          SizedBox(width: 16),
          Expanded(child: Text(event['event'] as String, style: TextStyle(fontWeight: FontWeight.w600))),
          Text(event['date'] as String, style: TextStyle(color: secondary)),
        ],
      ),
    );
  }

  Widget _buildCertificateItem(Map cert, ThemeData theme, Color secondary, bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isDarkMode ? Border.all(color: Color(0xFF30363D)) : null,
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium, color: theme.primaryColor),
          SizedBox(width: 14),
          Expanded(child: Text(cert['title'] as String, style: TextStyle(fontWeight: FontWeight.w600))),
          Text(cert['date'] as String, style: TextStyle(color: secondary)),
        ],
      ),
    );
  }

  Widget _buildActivityCard(List<Map> activities, ThemeData theme, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode
            ? theme.colorScheme.surface
            : const Color.fromARGB(255, 239, 240, 241),
        borderRadius: BorderRadius.circular(16),
        border: isDarkMode ? Border.all(color: Color(0xFF30363D)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Активность',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final item = activities[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        ),
                      ),
                      Text(
                        item['time'] as String,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
