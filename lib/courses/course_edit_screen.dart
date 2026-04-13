import 'package:flutter/material.dart';
import '../models/database_models.dart';
import '../services/supabase_service.dart';
import 'course_win/course_edit_general_tab.dart';
import 'course_win/course_edit_modules_tab.dart';
import 'course_win/course_edit_analytics_students_tab.dart';
import 'course_win/course_edit_reviews_tab.dart';

class CourseEditScreen extends StatefulWidget {
  final int courseId;

  const CourseEditScreen({super.key, required this.courseId});

  @override
  _CourseEditScreenState createState() => _CourseEditScreenState();
}

class _CourseEditScreenState extends State<CourseEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  Course? _course;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.client
          .from('courses')
          .select()
          .eq('id', widget.courseId)
          .single();
      
      if (mounted) {
        setState(() {
          _course = Course.fromJson(data as Map<String, dynamic>);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки курса: $e')),
        );
      }
    }
  }

  // ← НОВЫЙ МЕТОД: обновляет только данные курса без перезагрузки
  Future<void> _updateCourseData(String name, String description, double price, int complexity) async {
    if (mounted) {
      setState(() {
        _course = Course(
          id: _course!.id,
          name: name,
          description: description,
          price: price,
          complexity: complexity,
          icon: _course!.icon,
          status: _course!.status,
          dateCreate: _course!.dateCreate,
        );
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_course == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(child: Text('Курс не найден')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          _buildAdminHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                CourseEditGeneralTab(
                  formKey: _formKey,
                  course: _course!,
                  onCourseUpdated: _updateCourseData,  // ← ПЕРЕДАЁМ ЭТО
                ),
                CourseEditModulesTab(
                  courseId: _course!.id,
                  courseName: _course!.name ?? '',
                  courseIcon: _course!.icon ?? '',
                ),
                const CourseEditAnalyticsStudentsTab(),
                CourseEditReviewsTab(courseId: _course!.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
            ),
            child: Center(child: Text(_course?.icon ?? '📚', style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _course?.name ?? 'Редактирование курса',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Номер курса: ${_course!.id}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Создан: ${_course!.dateCreate?.toString().split(' ')[0] ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildStatusChip(),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final isActive = _course!.status ?? true;
    final color = isActive ? Colors.green : Colors.orange;
    final label = isActive ? 'Активный' : 'Черновик';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        tabs: const [
          Tab(text: 'Общие'),
          Tab(text: 'Модуль'),
          Tab(text: 'Аналитика и Пользователи'),
          Tab(text: 'Отзывы'),
        ],
      ),
    );
  }
}
