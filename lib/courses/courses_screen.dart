import 'package:flutter/material.dart';
import '../shared/search_row.dart';
import '../models/database_models.dart';
import 'course_edit_screen.dart';
import '../services/supabase_service.dart';


class CoursesScreen extends StatefulWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final bool isDarkMode;

  const CoursesScreen({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.isDarkMode,
  });

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Course> courses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadCourses();
  }

Future<void> _loadCourses() async {
  try {
    setState(() => isLoading = true);
    
    final loadedCourses = await SupabaseService.getCourses();
    
    if (mounted) {
      setState(() {
        courses = loadedCourses;
        isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    }
  }
}



  @override
  void dispose() {
    _searchController.removeListener(() {});
    _searchController.dispose();
    super.dispose();
  }

  List<Course> _getFilteredCourses() {
    List<Course> filtered = courses;

    // Фильтр по поиску
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((c) => c.name!.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    }

    // Фильтр по статусу/типу
    switch (widget.selectedFilter) {
      case 'Бесплатные':
        filtered = filtered.where((c) => (c.price ?? 0) == 0).toList();
        break;
      case 'Платные':
        filtered = filtered.where((c) => (c.price ?? 0) > 0).toList();
        break;
      case 'Активные':
        filtered = filtered.where((c) => c.status == true).toList();
        break;
      default:
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Фильтры и поиск
        Row(
          children: [
            Expanded(
              child: SearchRow(
                controller: _searchController,
                hintText: 'Поиск курсов по названию...',
                onChanged: (_) => setState(() {}),
                trailing: SizedBox(
                  height: 48,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.isDarkMode ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: widget.selectedFilter,
                      underline: SizedBox(),
                      items: ['Все', 'Бесплатные', 'Платные', 'Активные', 'В разработке', 'Завершенные']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) widget.onFilterChanged(v);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24),

        // Сетка курсов
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : _getFilteredCourses().isEmpty
                  ? Center(child: Text('Курсы не найдены'))
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.02,
                        ),
                        itemCount: _getFilteredCourses().length,
                        itemBuilder: (context, index) {
                          return _buildCourseCard(context, _getFilteredCourses()[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    Color statusColor;
    String statusText;
    bool isPaid = (course.price ?? 0) > 0;

    // Определяем статус
    if (course.status == true) {
      statusColor = Color(0xFF10B981);
      statusText = 'Активный';
    } else {
      statusColor = Color(0xFF6B7280);
      statusText = 'Неактивный';
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isPaid
            ? Border.all(color: Color(0xFFF59E0B).withOpacity(0.3), width: 2)
            : (widget.isDarkMode
                ? Border.all(color: Color(0xFF30363D))
                : null),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                course.icon?.toString() ?? '📚',
                style: TextStyle(fontSize: 25),
              ),
              Spacer(),
              if (isPaid)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 12),
                      SizedBox(width: 4),
                      Text(
                        'PRO',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Статус курса
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          SizedBox(height: 14),
          
          // Название курса
          Text(
            course.name ?? 'Без названия',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 8),
          
          // Описание курса
          Expanded(
            child: Text(
              course.description ?? 'Описание отсутствует',
              style: TextStyle(
                fontSize: 13,
                color: widget.isDarkMode ? Color(0xFF8B949E) : Color(0xFF64748B),
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          SizedBox(height: 12),
          
          // Сложность курса
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFF38BDF8)),
              SizedBox(width: 4),
              Text(
                'Уровень ${course.complexity ?? 1}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                course.price == 0 ? 'Бесплатно' : '₽ ${course.price?.toStringAsFixed(0)}',
                style: TextStyle(
                  color: isPaid ? Color(0xFFF59E0B) : Color(0xFF10B981),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 14),
          
          // Кнопка редактирования
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseEditScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 10),
                textStyle: TextStyle(fontSize: 12),
              ),
              child: Text('Редактировать'),
            ),
          ),
        ],
      ),
    );
  }
}
