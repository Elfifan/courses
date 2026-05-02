import 'package:flutter/material.dart';
import '../core/theme/app_components.dart'; // Подключаем вашу дизайн-систему
import '../models/database_models.dart';
import '../repositories/course_moderation_repository.dart';
import '../services/supabase_service.dart';
import 'course_win/course_edit_general_tab.dart';
import 'course_win/course_edit_modules_tab.dart';
import 'course_win/course_edit_analytics_students_tab.dart';
import 'course_win/course_edit_reviews_tab.dart';

class CourseEditScreen extends StatefulWidget {
  final int courseId;
  final String? userRole;
  final int? userId;

  const CourseEditScreen({
    super.key,
    required this.courseId,
    this.userRole,
    this.userId,
  });

  @override
  _CourseEditScreenState createState() => _CourseEditScreenState();
}

class _CourseEditScreenState extends State<CourseEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  Course? _course;
  bool _isLoading = true;
  bool _isChangingStatus = false;

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

  bool get _isAdmin => widget.userRole?.toLowerCase() == 'администратор';

  /// Изменить статус курса (только для администратора)
  Future<void> _changeStatusWithComment(String newStatus) async {
    if (!_isAdmin || widget.userId == null) return;

    if (newStatus == 'Отклонено') {
      _showRejectionDialog(newStatus);
      return;
    }

    await _saveModerationLog(newStatus);
  }

  void _showRejectionDialog(String status) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
        title: Text('Отклонить курс', style: AppStyles.h1),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Причина отклонения',
                style: AppStyles.label.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 5,
                decoration: KodixComponents.textFieldDecoration(
                  hintText: 'Укажите причину отклонения...',
                ),
                style: AppStyles.body,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Отмена', style: AppStyles.label.copyWith(color: AppColors.textGrey)),
          ),
          KodixComponents.primaryButton(
            onPressed: () {
              final comment = commentController.text.trim();
              if (comment.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Укажите причину отклонения курса')),
                );
                return;
              }
              Navigator.pop(dialogContext);
              _saveModerationLog(status, comment: comment);
            },
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshCourse() async {
    if (!mounted) return;
    try {
      final data = await SupabaseService.client
          .from('courses')
          .select()
          .eq('id', widget.courseId)
          .single();
      if (mounted) {
        setState(() {
          _course = Course.fromJson(data as Map<String, dynamic>);
        });
      }
    } catch (_) {
      // Игнорируем временные ошибки при обновлении, чтобы не ломать UX
    }
  }

  Future<void> _saveModerationLog(String newStatus, {String? comment}) async {
    if (!mounted || _course == null || widget.userId == null) return;

    setState(() => _isChangingStatus = true);

    try {
      await CourseModerationRepository.setCourseModerationStatus(
        courseId: _course!.id,
        adminId: widget.userId!,
        newStatus: newStatus,
        comment: comment,
      );

      await _refreshCourse();

     
    } finally {
      if (mounted) {
        setState(() => _isChangingStatus = false);
      }
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
      return const Scaffold(
        backgroundColor: AppColors.bgLight, // Используем bgLight из компонентов
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
      );
    }

    if (_course == null) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(child: Text('Курс не найден', style: AppStyles.label)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight, // Светлый фон приложения
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
                  onCourseUpdated: _updateCourseData,
                  readOnly: _isAdmin,
                ),
                CourseEditModulesTab(
                  courseId: _course!.id,
                  courseName: _course!.name ?? '',
                  courseIcon: _course!.icon ?? '',
                  readOnly: _isAdmin,
                ),
                const CourseEditAnalyticsStudentsTab(),
                CourseEditReviewsTab(courseId: _course!.id, readOnly: _isAdmin),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.bgLight, width: 2)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textGrey, size: 20),
          ),
          const SizedBox(width: 12),
          // Иконка курса с градиентом Кодикс[cite: 1]
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: AppColors.primaryGradient,
            ),
            child: Center(child: Text(_course?.icon ?? '📚', style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _course?.name ?? 'Редактирование курса',
                  style: AppStyles.h1.copyWith(fontSize: 22), // Roboto Bold[cite: 1]
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'ID: ${_course!.id}',
                      style: AppStyles.label.copyWith(fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 6),
                    Text(
                      'Создан: ${_course!.dateCreate?.toString().split(' ')[0] ?? '—'}',
                      style: AppStyles.label.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isAdmin)
            _buildAdminStatusButtons()
          else
            _buildStatusChip(),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final status = _course!.status ?? 'На проверке';
    final color = status == 'Активный' ? const Color(0xFF10B981) : status == 'На проверке' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final label = status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppStyles.label.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

/// Кнопки для администратора для смены статуса
Widget _buildAdminStatusButtons() {
  final currentStatus = _course!.status ?? 'На проверке';
  const statuses = ['Активный', 'На проверке', 'Отклонено'];

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: statuses.map((status) {
      final isActive = currentStatus == status;
      return Padding(
        padding: const EdgeInsets.only(left: 10),
        child: OutlinedButton(
          onPressed: isActive ? null : () => _changeStatusWithComment(status),
          style: OutlinedButton.styleFrom(
            backgroundColor: isActive 
                ? AppColors.primaryPurple 
                : Colors.transparent,
            foregroundColor: isActive 
                ? Colors.white 
                : AppColors.primaryPurple,
            side: BorderSide(
              color: isActive 
                  ? AppColors.primaryPurple 
                  : AppColors.primaryPurple.withOpacity(0.5),
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            // Отключаем стандартные эффекты наведения/нажатия для заблокированной кнопки
            disabledBackgroundColor: AppColors.primaryPurple,
            disabledForegroundColor: Colors.white,
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AppColors.primaryPurple,
            ),
          ),
        ),
      );
    }).toList(),
  );
}

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Мягкий фон под вкладки
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primaryPurple, // Акцентный цвет[cite: 1]
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textGrey,
        labelStyle: AppStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: AppStyles.body.copyWith(fontSize: 13),
        tabs: const [
          Tab(text: 'Общие'),
          Tab(text: 'Модули'),
          Tab(text: 'Аналитика'),
          Tab(text: 'Отзывы'),
        ],
      ),
    );
  }
}