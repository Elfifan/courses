import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_components.dart';
import '../shared/side_panel.dart';
import '../shared/top_bar.dart';
import '../courses/courses_screen.dart';
import '../students/students_screen.dart';
import '../achievements/achievements_screen.dart';
import '../repositories/course_repository.dart';
import '../courses/author_chats_screen.dart';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  final String? userRole;
  final int? userId;
  final VoidCallback onLogout;

  const DashboardScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.userRole,
    required this.userId,
    required this.onLogout,
  });

  @override
  // ignore: library_private_types_in_public_api
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _selectedStudentFilter = 'Все пользователи';

  bool _isLoadingDashboard = true;
  int _totalCourses = 0;
  int _totalStudents = 0;
  int _paidCourses = 0;
  double _totalRevenue = 0.0;
  double _averageRating = 0.0;
  int _coursesInDevelopment = 0;
  int _newStudentsMonth = 0;
  int _completedCoursesCount = 0;
  
  List<Map<String, dynamic>> _recentCoursesList = [];
  List<Map<String, dynamic>> _recentActivities = [];
  StreamSubscription? _courseSubscription;

  final GlobalKey _achievementsKey = GlobalKey();

  bool get _isAuthor => widget.userRole?.toLowerCase() == 'автор';

  @override
  void initState() {
    super.initState();
    if (!_isAuthor) {
      _loadDashboardData();
    }
    _setupRealtime();
  }

  void _setupRealtime() {
    _courseSubscription = CourseService.watchCourses().listen((_) {
      if (!_isAuthor) {
        _loadDashboardData(isBackground: true);
      }
    });
  }

  @override
  void dispose() {
    _courseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData({bool isBackground = false}) async {
    if (!mounted) return;
    if (!isBackground) {
      setState(() => _isLoadingDashboard = true);
    }

    try {
      // Fetch courses
      final coursesRes = await SupabaseService.safeDbCall(() => 
        SupabaseService.client.from('courses').select('id, name, status, price, date_create')
      );
      final courses = coursesRes as List;
      
      int totalCourses = courses.length;
      int paidCourses = courses.where((c) => (c['price'] ?? 0) > 0).length;
      int coursesInDev = courses.where((c) => c['status'] == 'В разработке').length;
      
      List<Map<String, dynamic>> recentCoursesList = List<Map<String, dynamic>>.from(courses);
      recentCoursesList.sort((a, b) {
        if (a['date_create'] == null) return 1;
        if (b['date_create'] == null) return -1;
        return DateTime.parse(b['date_create']).compareTo(DateTime.parse(a['date_create']));
      });
      recentCoursesList = recentCoursesList.take(4).toList();

      // Fetch passing
      final passingRes = await SupabaseService.safeDbCall(() =>
        SupabaseService.client.from('passing').select('id_courses, status, date_passage')
      );
      final passings = passingRes as List;
      
      int completedCoursesCount = 0;
      Map<int, int> studentsPerCourse = {};
      
      for (var p in passings) {
        int courseId = p['id_courses'];
        studentsPerCourse[courseId] = (studentsPerCourse[courseId] ?? 0) + 1;
        if (p['status'] == true) {
          completedCoursesCount++;
        }
      }
      
      double totalRevenue = 0.0;
      for (var c in courses) {
        int courseId = c['id'];
        double price = (c['price'] ?? 0).toDouble();
        int students = studentsPerCourse[courseId] ?? 0;
        totalRevenue += price * students;
      }
      
      for (var rc in recentCoursesList) {
        rc['students_count'] = studentsPerCourse[rc['id']] ?? 0;
      }

      // Fetch users
      final usersRes = await SupabaseService.safeDbCall(() => 
        SupabaseService.client.from('users').select('id, date_registration')
      );
      final users = usersRes as List;
      int totalStudents = users.length;
      
      DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      int newStudentsMonth = 0;
      
      List<Map<String, dynamic>> activities = [];
      
      for (var u in users) {
        if (u['date_registration'] != null) {
          DateTime regDate = DateTime.parse(u['date_registration']);
          if (regDate.isAfter(thirtyDaysAgo)) {
            newStudentsMonth++;
          }
          activities.add({
            'title': 'Новый студент',
            'time': regDate,
            'icon': Icons.person_add_rounded,
            'color': const Color(0xFF10B981)
          });
        }
      }
      
      for (var c in courses) {
        if (c['date_create'] != null) {
          activities.add({
            'title': 'Новый курс',
            'time': DateTime.parse(c['date_create']),
            'icon': Icons.school_rounded,
            'color': AppColors.primaryPurple
          });
        }
      }
      
      activities.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));
      final recentActivities = activities.take(4).toList();

      // Fetch feedback
      final feedbackRes = await SupabaseService.safeDbCall(() =>
        SupabaseService.client.from('feedback').select('estimation').eq('status', true)
      );
      final feedbacks = feedbackRes as List;
      double averageRating = 0.0;
      if (feedbacks.isNotEmpty) {
        double sum = feedbacks.fold(0.0, (prev, f) => prev + (f['estimation'] ?? 0).toDouble());
        averageRating = sum / feedbacks.length;
      }

      if (mounted) {
        setState(() {
          _totalCourses = totalCourses;
          _paidCourses = paidCourses;
          _coursesInDevelopment = coursesInDev;
          _recentCoursesList = recentCoursesList;
          _totalRevenue = totalRevenue;
          _completedCoursesCount = completedCoursesCount;
          _totalStudents = totalStudents;
          _newStudentsMonth = newStudentsMonth;
          _averageRating = averageRating;
          _recentActivities = recentActivities;
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки дашборда: $e');
      if (mounted) {
        setState(() => _isLoadingDashboard = false);
      }
    }
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} мин назад';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} час назад';
    } else {
      return '${diff.inDays} дн назад';
    }
  }

  List<String> get _menuItems => _isAuthor
      ? ['Курсы', 'Чаты']
      : ['Статистика', 'Курсы', 'Пользователь', 'Достижения'];

  List<IconData> get _menuIcons => _isAuthor
      ? [Icons.school_rounded, Icons.message_rounded]
      : [
          Icons.dashboard_rounded,
          Icons.school_rounded,
          Icons.people_rounded,
          Icons.analytics_rounded,
        ];

  @override
  Widget build(BuildContext context) {
    // Список экранов для IndexedStack, чтобы они не пересоздавались каждый раз
    final List<Widget> screens = _isAuthor 
      ? [
          CoursesScreen(
            isDarkMode: widget.isDarkMode,
            authorId: widget.userId,
            userRole: widget.userRole,
            userId: widget.userId,
          ),
          AuthorChatsScreen(authorId: widget.userId!),
        ]
      : [
          _buildDashboard(),
          CoursesScreen(
            isDarkMode: widget.isDarkMode,
            authorId: null,
            userRole: widget.userRole,
            userId: widget.userId,
          ),
          StudentsScreen(
            selectedFilter: _selectedStudentFilter,
            onFilterChanged: (filter) {
              setState(() {
                _selectedStudentFilter = filter;
              });
            },
            isDarkMode: widget.isDarkMode,
          ),
          AchievementsScreen(
            key: _achievementsKey,
            isDarkMode: widget.isDarkMode,
          ),
        ];

    return Scaffold(
      backgroundColor: AppColors.white, 
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
            onLogout: widget.onLogout,
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
                    if (_menuItems[_selectedIndex] == 'Курсы') {
                      CourseService.showAddCourseForm(context, authorId: widget.userId);
                    }
                  },
                  onAddAchievement: () {
                    if (_menuItems[_selectedIndex] == 'Достижения') {
                      final state = _achievementsKey.currentState as dynamic;
                      state.showForm();
                    }
                  },
                ),
                Expanded(
                  child: Container(
                    color: AppColors.bgLight, 
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: screens,
                      ),
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

  // _buildContent больше не нужен, так как используется IndexedStack
  
  Widget _buildDashboard() {
    if (_isLoadingDashboard) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
    }

    final currencyFormatter = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('Всего курсов', _totalCourses.toString(), AppColors.primaryPurple, Icons.school_rounded),
            const SizedBox(width: 20),
            _buildStatCard('Студентов зарегистрировано', _totalStudents.toString(), const Color(0xFF10B981), Icons.people_rounded),
            const SizedBox(width: 20),
            _buildStatCard('Платных курсов', _paidCourses.toString(), const Color(0xFFF59E0B), Icons.attach_money_rounded),
            const SizedBox(width: 20),
            _buildStatCard('Общий доход', currencyFormatter.format(_totalRevenue), const Color(0xFF38BDF8), Icons.account_balance_wallet_rounded),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            _buildInfoCard('Средняя оценка курсов', _averageRating.toStringAsFixed(1), Icons.star_rounded, const Color(0xFFEAB308)),
            const SizedBox(width: 20),
            _buildInfoCard('Курсов в разработке', _coursesInDevelopment.toString(), Icons.autorenew, const Color(0xFFC57110)),
            const SizedBox(width: 20),
            _buildInfoCard('Новых студентов за месяц', '+$_newStudentsMonth', Icons.trending_up_rounded, const Color(0xFF38BDF8)),
            const SizedBox(width: 20),
            _buildInfoCard('Кол-во завершённых курсов', _completedCoursesCount.toString(), Icons.school, const Color(0xFF1CAD3C)),
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
              color: Colors.black.withValues(alpha: 0.04),
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
                    color: color.withValues(alpha: 0.1),
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
              color: Colors.black.withValues(alpha: 0.03),
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
                    color: color.withValues(alpha: 0.1),
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
            child: _recentCoursesList.isEmpty
                ? const Center(child: Text('Нет курсов'))
                : ListView(
                    children: _recentCoursesList.map((course) {
                      String statusStr = course['status'] ?? 'Неизвестно';
                      Color statusColor;
                      if (statusStr.toLowerCase() == 'в разработке') {
                        statusColor = const Color(0xFFF59E0B);
                      } else if (statusStr.toLowerCase() == 'активный' || statusStr.toLowerCase() == 'опубликован') {
                        statusColor = const Color(0xFF10B981);
                      } else {
                        statusColor = AppColors.textGrey;
                      }
                      
                      String studentsStr = '${course['students_count']} студент' + (course['students_count'] == 1 ? '' : 'ов');
                      
                      return _buildCourseRow(
                        course['name'] ?? 'Без названия',
                        statusStr,
                        statusColor,
                        studentsStr,
                      );
                    }).toList(),
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
                color: statusColor.withValues(alpha: 0.1),
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
            child: _recentActivities.isEmpty
                ? const Center(child: Text('Нет активности'))
                : ListView(
                    children: _recentActivities.map((act) {
                      return _buildActivityItem(
                        act['title'],
                        _formatTimeAgo(act['time']),
                        act['icon'],
                        act['color'],
                      );
                    }).toList(),
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
              color: color.withValues(alpha: 0.1),
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