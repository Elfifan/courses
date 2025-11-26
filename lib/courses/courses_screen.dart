import 'package:flutter/material.dart';
import '../models/database_models.dart';
import '../services/supabase_service.dart';
import '../shared/search_row.dart';
import '../courses/course_edit_screen.dart';

class CoursesScreen extends StatefulWidget {
  final bool isDarkMode;

  const CoursesScreen({super.key, required this.isDarkMode});

  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Course> _courses = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';  // ← ДОБАВЛЕНО

  final List<Map<String, String>> _filters = [  // ← ДОБАВЛЕНО
    {'value': 'all', 'label': 'Все курсы'},
    {'value': 'active', 'label': 'Активные'},
    {'value': 'draft', 'label': 'Черновики'},
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
      final data = await SupabaseService.client
          .from('courses')
          .select()
          .order('date_create', ascending: false);
      
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
      // Фильтр по поиску
      final matchesSearch = q.isEmpty || 
          c.name?.toLowerCase().contains(q) == true ||
          c.description?.toLowerCase().contains(q) == true;
      
      // Фильтр по статусу и сложности
      bool matchesFilter = true;
      if (_selectedFilter != 'all') {
        switch (_selectedFilter) {
          case 'active':
            matchesFilter = c.status == true;
            break;
          case 'draft':
            matchesFilter = c.status == false;
            break;
          case 'beginner':
            matchesFilter = c.complexity == 1;
            break;
          case 'intermediate':
            matchesFilter = c.complexity == 2;
            break;
          case 'advanced':
            matchesFilter = c.complexity == 3;
            break;
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
    final theme = Theme.of(context);
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
              // Фильтры
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter['value'];
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter['label']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = filter['value']!;
                          });
                        },
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color: isSelected 
                            ? theme.primaryColor 
                            : theme.colorScheme.outlineVariant,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                            ? theme.primaryColor
                            : theme.colorScheme.onSurface,
                        ),
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
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Text('Курсы не найдены',
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6))),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final course = filtered[index];
                        return _buildCourseCard(course, theme);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(Course course, ThemeData theme) {
    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => CourseEditScreen(courseId: course.id),
          ),
        );
        
        if (updated == true) {
          _loadCourses();
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
                child: Center(
                  child: Text(course.icon ?? '📚',
                      style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name ?? 'Без названия',
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.description ?? '',
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (course.price != null)
                          Text(
                            '${course.price}₽',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getComplexityColor(course.complexity),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getComplexityLabel(course.complexity ?? 1),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (course.status == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.5),
                              ),
                            ),
                            child: const Text(
                              'Активный',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.5),
                              ),
                            ),
                            child: const Text(
                              'Черновик',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  String _getComplexityLabel(int complexity) {
    switch (complexity) {
      case 1:
        return 'Начальный';
      case 2:
        return 'Средний';
      case 3:
        return 'Продвинутый';
      default:
        return 'Неизвестно';
    }
  }

  Color _getComplexityColor(int? complexity) {
    switch (complexity) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
