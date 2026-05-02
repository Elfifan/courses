import 'package:flutter/material.dart';
import '../core/theme/app_components.dart'; // Подключаем вашу дизайн-систему
import '../models/database_models.dart';
import '../services/supabase_service.dart';
import '../shared/search_row.dart';
import '../courses/course_edit_screen.dart';

class CoursesScreen extends StatefulWidget {
  final bool isDarkMode;
  final int? authorId;
  final String? userRole;
  final int? userId;

  const CoursesScreen({super.key, required this.isDarkMode, this.authorId, this.userRole, this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Course> _courses = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';  

  final List<Map<String, String>> _filters = [ 
    {'value': 'all', 'label': 'Все курсы'},
    {'value': 'Активный', 'label': 'Активные'},
    {'value': 'На проверке', 'label': 'На проверке'},
    {'value': 'Отклонено', 'label': 'Отклонено'},
    {'value': 'beginner', 'label': 'Начальный уровень'},
    {'value': 'intermediate', 'label': 'Средний уровень'},
    {'value': 'advanced', 'label': 'Продвинутый уровень'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final query = SupabaseService.client.from('courses').select();
      final data = await (widget.authorId != null
          ? query.eq('id_employee', widget.authorId!).order('date_create', ascending: false)
          : query.order('date_create', ascending: false));
      
      if (mounted) {
        setState(() {
          _courses = (data as List)
              .map((item) => Course.fromJson(item as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  List<Course> get _filteredCourses {
    final q = _searchController.text.trim().toLowerCase();
    
    return _courses.where((c) {
      final matchesSearch = q.isEmpty || 
          c.name?.toLowerCase().contains(q) == true ||
          c.description?.toLowerCase().contains(q) == true;
      
      bool matchesFilter = true;
      if (_selectedFilter != 'all') {
        switch (_selectedFilter) {
          case 'Активный': matchesFilter = c.status == 'Активный'; break;
          case 'На проверке': matchesFilter = c.status == 'На проверке'; break;
          case 'Отклонено': matchesFilter = c.status == 'Отклонено'; break;
          case 'beginner': matchesFilter = c.complexity == 1; break;
          case 'intermediate': matchesFilter = c.complexity == 2; break;
          case 'advanced': matchesFilter = c.complexity == 3; break;
        }
      }
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCourses;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SearchRow(
                controller: _searchController,
                hintText: 'Поиск по курсам...',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              // Обновленные фильтры в стиле Кодикс
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter['value'];
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(filter['label']!),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedFilter = filter['value']!),
                        selectedColor: AppColors.primaryPurple, // Фиолетовый акцент
                        backgroundColor: AppColors.bgLight, // Светлый фон
                        labelStyle: AppStyles.label.copyWith(
                          color: isSelected ? Colors.white : AppColors.textGrey,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide.none,
                        showCheckmark: false,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
              : filtered.isEmpty
                  ? Center(
                      child: Text('Курсы не найдены', style: AppStyles.label),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _buildCourseCard(filtered[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(Course course) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      // Используем универсальный контейнер Кодикс
      child: KodixComponents.cardContainer(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () async {
            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => CourseEditScreen(
                  courseId: course.id,
                  userRole: widget.userRole,
                  userId: widget.userId,
                ),
              ),
            );
            if (updated == true) _loadCourses();
          },
          borderRadius: AppStyles.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Градиентная иконка курса в стиле Кодикс[cite: 1]
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Center(
                    child: Text(course.icon ?? '📚', style: const TextStyle(fontSize: 30)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.name ?? 'Без названия', style: AppStyles.h1.copyWith(fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                        course.description ?? '',
                        style: AppStyles.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (course.price != null)
                            Text('${course.price}₽', style: AppStyles.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                          const SizedBox(width: 12),
                          _buildBadge(
                            _getComplexityLabel(course.complexity ?? 1),
                            _getComplexityColor(course.complexity).withValues(alpha: 0.1),
                            _getComplexityColor(course.complexity),
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            course.status ?? 'На проверке',
                            (course.status == 'Активный' ? Colors.green : course.status == 'На проверке' ? Colors.orange : Colors.red).withValues(alpha: 0.1),
                            course.status == 'Активный' ? Colors.green : course.status == 'На проверке' ? Colors.orange : Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textGrey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppStyles.label.copyWith(fontSize: 11, color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getComplexityLabel(int complexity) {
    switch (complexity) {
      case 1: return 'Начальный';
      case 2: return 'Средний';
      case 3: return 'Продвинутый';
      default: return 'Неизвестно';
    }
  }

  Color _getComplexityColor(int? complexity) {
    switch (complexity) {
      case 1: return const Color(0xFF38BDF8);
      case 2: return const Color(0xFFF59E0B);
      case 3: return const Color(0xFFEF4444);
      default: return AppColors.textGrey;
    }
  }
}