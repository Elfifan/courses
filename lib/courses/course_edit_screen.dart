import 'package:flutter/material.dart';

// Импортируйте ваши табы (замените пути при необходимости)
import 'course_win/course_edit_general_tab.dart';
import 'course_win/course_edit_modules_tab.dart';
import 'course_win/course_edit_analytics_students_tab.dart';
import 'course_win/course_edit_reviews_tab.dart'; // Новый файл для вкладки "Отзывы"

class CourseEditScreen extends StatefulWidget {
  const CourseEditScreen({Key? key}) : super(key: key);

  @override
  _CourseEditScreenState createState() => _CourseEditScreenState();
}

class _CourseEditScreenState extends State<CourseEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Flutter Mobile Development');
  final _descriptionController =
      TextEditingController(text: 'Полный курс по разработке мобильных приложений на Flutter');
  final _priceController = TextEditingController(text: '12990');

  String _selectedStatus = 'active';
  String _selectedCategory = 'programming';
  bool _isPublished = true;

  final List<Map<String, dynamic>> _modules = [
    {
      'id': 1,
      'title': 'Введение в Flutter',
      'duration': '2 часа 30 мин',
      'lessons': 4,
      'status': 'published',
      'views': 1234,
      'completion_rate': 85,
      'submodules': [
        {'title': 'Что такое Flutter', 'duration': '15 мин', 'completed': false},
        {'title': 'Установка окружения', 'duration': '25 мин', 'completed': false},
        {'title': 'Создание первого проекта', 'duration': '30 мин', 'completed': false},
        {'title': 'Структура проекта', 'duration': '20 мин', 'completed': false},
      ]
    },
    {
      'id': 2,
      'title': 'Основы языка Dart',
      'duration': '3 часа 15 мин',
      'lessons': 5,
      'status': 'published',
      'views': 987,
      'completion_rate': 72,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // добавили четвертую вкладку "Отзывы"
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  titleController: _titleController,
                  descriptionController: _descriptionController,
                  priceController: _priceController,
                  selectedStatus: _selectedStatus,
                  selectedCategory: _selectedCategory,
                  isPublished: _isPublished,
                  onStatusChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                  onCategoryChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                  onPublishedChanged: (val) => setState(() => _isPublished = val),
                  onSave: _saveCourse,
                  onArchive: _archiveCourse,
                  onDelete: _deleteCourse,
                ),
                CourseEditModulesTab(module: _modules[0]),
                const CourseEditAnalyticsStudentsTab(),
                const CourseEditReviewsTab(),  // Новая вкладка с отзывами
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
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
            ),
            child: const Center(child: Text('📱', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Редактирование курса',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                Row(
                  children: [
                    Text(
                      'ID: #CR-2024-001',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Создан: 15 января 2024',
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
    final statusColors = {
      'active': Colors.green,
      'draft': Colors.orange,
      'archived': Colors.grey,
    };
    final text = {
      'active': 'Активный',
      'draft': 'Черновик',
      'archived': 'Архивирован',
    };
    final color = statusColors[_selectedStatus] ?? Colors.grey;
    final label = text[_selectedStatus] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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
          Tab(text: 'Отзывы'),   // новая вкладка
        ],
      ),
    );
  }

  // Действия
  void _saveCourse() {
    if (_formKey.currentState?.validate() == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Курс сохранен успешно')),
      );
    }
  }

  void _archiveCourse() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Курс архивирован')),
    );
  }

  void _deleteCourse() {
    _showDeleteConfirmation('курс', _titleController.text);
  }

  void _showDeleteConfirmation(String type, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить $type?'),
        content: Text('Вы уверены, что хотите удалить $type "$name"? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$type "$name" удален')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
